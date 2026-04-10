#' Generate a reproducible random sample from the raw NYC Taxi dataset

library(arrow)
library(dplyr)
library(lubridate)
library(skimr)

#' Loads the raw parquet files into memory as a dataframe, then samples.
#' 
#' @param n Target sample size (will return all rows if dataset is smaller)
#' @param output_dir Directory containing the parquet files and where to save output
#' @param write_csv Whether to write the sampled data to CSV when run standalone
#' @return A tibble containing the raw sampled data
sample_taxi_data <- function(n = 750000, output_dir = "data/", write_csv = TRUE) {
  set.seed(6306)
  sample_name <- paste0("taxi_", n/1000, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  
  cat("Loading taxi dataset into memory as dataframe...\n")
  parquet_files <- list.files(output_dir, pattern = "yellow_.*\\.parquet$", full.names = TRUE)
  cat("Found", length(parquet_files), "parquet files\n")
  
  # Turn into regular dataframe (as requested)
  taxi_data <- open_dataset(parquet_files) |> collect()
  
  cat("Dataset dimensions before sampling:", nrow(taxi_data), "rows and", 
      ncol(taxi_data), "columns\n")
  cat("Taking random sample of up to", n, "raw rows...\n")
  
  # Sample from the dataframe
  if (nrow(taxi_data) > n) {
    sampled_data <- taxi_data |> 
      slice_sample(n = n)
  } else {
    sampled_data <- taxi_data
  }
  
  actual_n <- nrow(sampled_data)
  cat("Final sample size:", actual_n, "rows\n")
  
  if (write_csv) {
    output_path <- file.path(output_dir, paste0(sample_name, ".csv"))
    write.csv(sampled_data, output_path)
    cat("Saved to:", output_path, "\n")
  }
  
  invisible(sampled_data)
}

# Only run when this file is executed directly (not when source()'d)
if (sys.nframe() == 0) {
  sample_taxi_data()
}