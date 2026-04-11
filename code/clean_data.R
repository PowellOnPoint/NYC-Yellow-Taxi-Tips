#' Data Cleaning and Feature Engineering for NYC Yellow Taxi Tipping Analysis
#'
#' This module takes the raw sampled data from sample_taxi_data() and prepares
#' it specifically for predicting tipping behavior (tip_amount or tip_pct).
#'
#' @param raw_data A tibble returned by sample_taxi_data()
#' @return A cleaned and feature-engineered tibble ready for modeling
#' @examples
#' raw_sample <- sample_taxi_data(n = 750000)
#' clean_data <- clean_taxi_data(raw_sample)

# updating from data_cleaning_worksheet.rmd

clean_taxi_data <- function(raw_data) {
  
  library(dplyr)
  library(lubridate)
  
  cat("=== Starting Data Cleaning & Feature Engineering for Tipping Analysis ===\n")
  cat("Input rows:", nrow(raw_data), "\n")
  
  cleaned <- raw_data %>%
    # 1. Filter to valid tipping records (credit card only)
    filter(payment_type == 1) %>%
    filter(!is.na(tip_amount), !is.na(total_amount)) %>%
    
    # 2. Basic data quality filters (remove obvious errors)
    filter(
      trip_distance > 0,
      total_amount > 0,
      fare_amount >= 0,
      tip_amount >= 0,
      passenger_count >= 1,
      passenger_count <= 6,           # realistic max for yellow taxis
      !is.na(tpep_pickup_datetime),
      !is.na(tpep_dropoff_datetime)
    ) %>%
    
    # 3. Feature Engineering - Critical for strong tipping models
    mutate(
      # Response variables (choose one as your target in lm())
      tip_amount = tip_amount,
      tip_pct    = tip_amount / (total_amount - tip_amount + 1e-8),  # avoid div-by-zero
      
      # Time-based features (tipping behavior varies strongly by time)
      pickup_datetime   = tpep_pickup_datetime,
      dropoff_datetime  = tpep_dropoff_datetime,
      pickup_hour       = hour(pickup_datetime),
      pickup_dow        = wday(pickup_datetime, label = TRUE, abbr = FALSE),
      pickup_month      = month(pickup_datetime, label = TRUE),
      is_weekend        = pickup_dow %in% c("Saturday", "Sunday"),
      is_rush_hour      = pickup_hour %in% c(7, 8, 9, 16, 17, 18),
      
      # Trip characteristics
      trip_duration_min = as.numeric(difftime(dropoff_datetime, 
                                              pickup_datetime, 
                                              units = "mins")),
      trip_speed_mph    = ifelse(trip_duration_min > 0, 
                                 (trip_distance / trip_duration_min) * 60, 
                                 NA),
      
      # Fare and payment features (important predictors of tipping)
      fare_per_mile     = ifelse(trip_distance > 0, 
                                 fare_amount / trip_distance, 
                                 NA),
      total_fare_ex_tip = total_amount - tip_amount,
      surcharge_total   = congestion_surcharge + improvement_surcharge + mta_tax,
      
      # Location proxies (PULocationID can be mapped to boroughs later if desired)
      pu_location_id    = PULocationID,
      do_location_id    = DOLocationID,
      
      # Binary indicators that often influence tipping
      has_congestion    = congestion_surcharge > 0,
      airport_trip      = RatecodeID %in% c(2, 3),   # JFK/EWR/Newark airport codes
      
      # Log transformations for skewed variables (helpful in linear regression)
      log_trip_distance = log(trip_distance + 1),
      log_total_fare    = log(total_fare_ex_tip + 1)
    ) %>%
    
    # 4. Final quality filters after feature creation
    filter(
      trip_duration_min > 0.5,          # at least 30 seconds
      trip_duration_min < 180,          # remove extreme outliers (>3 hours)
      trip_speed_mph < 80,              # unrealistic speeds
      tip_pct < 1.0                     # tip_pct > 100% is extremely rare and suspicious
    ) %>%
    
    # 5. Select final columns for modeling (keeps it tidy)
    select(
      tip_amount, tip_pct,
      trip_distance, trip_duration_min, trip_speed_mph,
      passenger_count, pickup_hour, pickup_dow, pickup_month,
      is_weekend, is_rush_hour, airport_trip, has_congestion,
      fare_per_mile, total_fare_ex_tip, surcharge_total,
      log_trip_distance, log_total_fare,
      VendorID, RatecodeID, 
      pu_location_id, do_location_id,
      pickup_datetime, dropoff_datetime   # keep for potential time-series work
    ) %>%
    as_tibble()
  
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