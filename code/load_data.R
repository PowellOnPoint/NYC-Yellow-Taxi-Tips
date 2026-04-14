#' Minimal, memory-efficient random sampling from raw NYC Yellow Taxi Parquet files
#'
#' It performs ONLY loading and sampling. No cleaning, no filtering, 
#' no feature engineering is performed. The returned data is as close as 
#' possible to the raw Parquet content.
#'
#' @param n Target sample size (default 750000). 
#' @param data_dir Directory containing the yellow_*.parquet files 
#'                 (default here::here("data"))
#' @param seed Random seed for reproducibility (default 6306)
#' @return A tibble containing the raw sampled rows

sample_taxi_data <- function(n = 750000, data_dir = here::here("data"), seed = 6306) {
  set.seed(seed)
  library(arrow)
  library(dplyr)
  library(here)
  
  cat("NYC Yellow Taxi Sampling Module\n")
  cat("Target sample size :", n, "rows\n")
  cat("Data directory     :", data_dir, "\n")
  
  # Locate all yellow taxi parquet files
  parquet_files <- list.files(data_dir, pattern = "^yellow_.*\\.parquet$", full.names = TRUE)
  if (length(parquet_files) == 0) {
    stop("No yellow_*.parquet files found in directory: ", data_dir, "\nPlease check the path and file naming.")
  }
  cat("Found", length(parquet_files), "parquet file(s)\n")
  
  # Open dataset lazily
  ds <- open_dataset(parquet_files, format = "parquet")
  cat("Performing memory-efficient random sampling...\n")
  
  # Efficient batch-wise sampling using Arrow
  sampled_data <- ds %>%
    map_batches(~ {
      df <- as.data.frame(.)
      if (nrow(df) > 0) {
        slice_sample(df, n = min(n, nrow(df)))  # sample within each batch
      } else {
        df
      }
    }) %>%
    collect() %>%
    # Enforce exact target size if oversampled across batches
    slice_sample(n = min(n, nrow(.))) %>%
    as_tibble()
  
  actual_n <- nrow(sampled_data)
  
  cat("Sampling complete!\n")
  cat("Final sample size  :", actual_n, "rows\n")
  cat("Number of columns  :", ncol(sampled_data), "\n")
  
  invisible(sampled_data)
}