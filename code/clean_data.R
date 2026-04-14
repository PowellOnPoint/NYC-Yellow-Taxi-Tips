#' Data Cleaning and Feature Engineering for NYC Yellow Taxi Tipping Analysis
#'
#' This module takes the raw sampled data from sample_taxi_data() and prepares
#' it specifically for predicting tipping behavior (tip_amount or tip_pct).
#' Note: total_amount column is updated to exclude tips (i.e. pre-tip fare
#' amount including taxes/surcharges). tip_pct is calculated relative to this
#' updated total_amount.
#'
#' @param raw_data A tibble returned by sample_taxi_data()
#' @return A cleaned and feature-engineered tibble ready for modeling
#' @examples
#' raw_sample <- sample_taxi_data(n = 750000)
#' clean_data <- clean_taxi_data(raw_sample)

library(dplyr)
library(lubridate)

clean_taxi_data <- function(raw_data) {

  cat("=== Starting Data Cleaning & Feature Engineering for Tipping Analysis ===\n")
  cat("Input rows:", nrow(raw_data), "\n")
  
  cleaned <- raw_data %>%
    filter(payment_type == 1) %>% # optional see data_cleaning_worksheet
    filter(!is.na(tip_amount), !is.na(total_amount)) %>% # seed(6306) has none
    
# 1. Convert coded categorical variables to labels
    # Special Category Logic for Flex_fare and Unknown
    mutate(
      # RatecodeID mapping - comprehensive logic
      RatecodeID = case_when(
        RatecodeID == 1 ~ "Standard",
        RatecodeID == 2 ~ "JFK",
        RatecodeID == 3 ~ "Newark",
        RatecodeID == 4 ~ "Nassau",
        RatecodeID == 5 ~ "Negotiated",
        RatecodeID == 6 ~ "Group",
        RatecodeID == 99 ~ "Unknown",
        is.na(RatecodeID) & 
        is.na(passenger_count) & 
        is.na(store_and_fwd_flag) & 
        is.na(congestion_surcharge) & 
        is.na(Airport_fee) ~ "Flex_fare",
        TRUE ~ as.character(RatecodeID)
      ),
      # VendorID mapping
      VendorID = case_when(
        VendorID == 1 ~ "Creative Mobile Tech",
        VendorID == 2 ~ "Curb Mobility",
        VendorID == 6 ~ "Myle Technologies",
        VendorID == 7 ~ "Helix",
        TRUE ~ as.character(VendorID)
      )
    ) %>%
    
    # 2. Quality filters 
    filter(
      trip_distance > 0, 
      total_amount > 0, 
      fare_amount >= 0, 
      tip_amount >= 0, 
      # Allow NA passenger_count for Flex_fare rows
      is.na(passenger_count) | (passenger_count >= 1 & passenger_count <= 6),
      !is.na(tpep_pickup_datetime), 
      !is.na(tpep_dropoff_datetime)
    ) %>%
    
    # 3. Feature Engineering
    mutate(
      # Response variables - update total_amount to exclude tip (credit care payments ha
      total_amount = total_amount - tip_amount,
      tip_pct      = tip_amount / total_amount,
      
      # Time-based features
      pickup_hour = hour(tpep_pickup_datetime),
      pickup_dow = wday(tpep_pickup_datetime, label = TRUE, abbr = FALSE),
      pickup_month = month(tpep_pickup_datetime, label = TRUE),
      weekend = pickup_dow %in% c("Saturday", "Sunday"),
      rush_hour = pickup_hour %in% c(16, 17, 18, 19) & !weekend,
      overnight = pickup_hour %in% c(20, 21, 22, 23, 0, 1, 2, 3, 4, 5),
      
      # Trip characteristics
      trip_duration_min = as.numeric(difftime(tpep_dropoff_datetime, tpep_pickup_datetime, units = "mins")),
      trip_speed_mph    = ifelse(trip_duration_min > 0, (trip_distance / trip_duration_min) * 60, NA_real_),
      
      # Fare and payment features 
      fare_per_mile = ifelse(trip_distance > 0, fare_amount / trip_distance, NA_real_),
      surcharge_total = coalesce(congestion_surcharge, 0) + 
                       coalesce(improvement_surcharge, 0) + 
                       coalesce(mta_tax, 0),
      
      # Binary indicators
      congestion        = coalesce(congestion_surcharge > 0, FALSE),
      airport           = coalesce(Airport_fee > 0, FALSE),
      cbd_congestion    = coalesce(cbd_congestion_fee > 0, FALSE),
      
      # Log transformations
      log_trip_distance = log(trip_distance + 1),
      log_total_amount  = log(total_amount + 1),
      
      # Resolve NA values for modeling by assigning "Flex_fare" level
      passenger_count = if_else(
        RatecodeID == "Flex_fare", 
        "Flex_fare", 
        as.character(coalesce(passenger_count, 1))
      ),
      store_and_fwd_flag = if_else(
        RatecodeID == "Flex_fare", 
        "Flex_fare", 
        coalesce(store_and_fwd_flag, "Unknown")
      )
    ) %>%
    
    # 4. Final quality filters after feature creation
    filter(
      trip_duration_min > 0.5,          # at least 30 seconds
      trip_duration_min < 180,          # remove outliers (>3 hours)
      trip_speed_mph < 80,              # unrealistic speeds
      tip_pct < 1.0                     # tip_pct > 100% is suspicious
    ) %>%
  
    # 5. Select final columns for modeling
    dplyr::select(
      tip_amount, tip_pct, trip_distance, trip_duration_min, trip_speed_mph,
      passenger_count, pickup_hour, pickup_dow, pickup_month, weekend, 
      rush_hour, airport, congestion, cbd_congestion, fare_per_mile, 
      surcharge_total, log_trip_distance, log_total_amount, VendorID, RatecodeID, 
      PULocationID, DOLocationID, overnight, tpep_pickup_datetime, tpep_dropoff_datetime, 
      payment_type, store_and_fwd_flag, total_amount
    ) %>%

    mutate(
      # Explicit factoring with Flex_fare level for variables that have NAs in Flex_fare rows
      VendorID       = factor(VendorID, 
                              levels = c("Creative Mobile Tech", "Curb Mobility", 
                                       "Myle Technologies", "Helix")),
      RatecodeID     = factor(RatecodeID, 
                              levels = c("Standard", "JFK", "Newark", "Nassau", 
                                       "Negotiated", "Group", "Unknown", "Flex_fare")),
      passenger_count = factor(passenger_count, 
                              levels = c("1", "2", "3", "4", "5", "6", "Flex_fare")),
      store_and_fwd_flag = factor(store_and_fwd_flag,
                                 levels = c("Y", "N", "Flex_fare")),
      PULocationID   = factor(PULocationID),
      DOLocationID   = factor(DOLocationID)
    )
  
  # Summary report
  final_n <- nrow(cleaned)
  cat("Cleaning & feature engineering complete!\n")
  cat("Final rows after cleaning:", final_n, "\n")
  cat("Rows removed during cleaning:", nrow(raw_data) - final_n, "\n")
  cat("Final columns:", ncol(cleaned), "\n\n")
  
  # Quick summary of key tipping variables
  cat("Key tipping statistics in cleaned data:\n")
  print(cleaned %>%
          summarise(
            mean_tip_amount = mean(tip_amount, na.rm = TRUE),
            mean_tip_pct    = mean(tip_pct, na.rm = TRUE),
            median_tip_pct  = median(tip_pct, na.rm = TRUE),
            sd_tip_pct      = sd(tip_pct, na.rm = TRUE)
          ))
  
  invisible(cleaned)
}