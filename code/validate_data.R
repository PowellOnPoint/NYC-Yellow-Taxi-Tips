# Function to validate that the sample is representative of the population
# Key statistics should be within 1-3% difference (not strict)
# for large samples, even small differences can be significant
# Update as insights develop

validate_sample <- function(sample_df, data_dir = "data/") {
  library(arrow)
  library(dplyr)
  
  ds <- open_dataset(list.files(data_dir, pattern = "^yellow_.*\\.parquet$", full.names = TRUE))
  
  pop_summary <- ds %>%
    collect() %>%
    summarise(
      total_rows = n(),
      mean_tip_amount = mean(tip_amount, na.rm = TRUE),
      sd_tip_amount = sd(tip_amount),
      mean_total_amount = mean(total_amount, na.rm = TRUE),
      sd_total_amount = sd(tip_amount),
      mean_trip_distance = mean(trip_distance, na.rm = TRUE),
      sd_trip_distance = sd(trip_distance)
    ) %>%
    collect()
  
  sample_summary <- sample_df %>%
    summarise(
      total_rows = n(),
      mean_tip_amount = mean(tip_amount, na.rm = TRUE),
      sd_tip_amount = sd(tip_amount),
      mean_total_amount = mean(total_amount, na.rm = TRUE),
      sd_total_amount = sd(tip_amount),
      mean_trip_distance = mean(trip_distance, na.rm = TRUE),
      sd_trip_distance = sd(trip_distance)
    )
  
  cat("Representativeness Check (Population vs Sample)\n")
  print(bind_rows(Population = pop_summary, Sample = sample_summary, .id = "Source"))
}