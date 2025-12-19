# ==============================================================================
# Data Utilities: Data Loading and Splitting Functions
# ==============================================================================

#' Load credit card fraud dataset
#'
#' @param data_path Path to the credit card CSV file
#' @return Data frame with credit card transaction data
#' @export
load_credit_card_data <- function(data_path = file.path(paths$data, "creditcard.csv")) {
  if (!file.exists(data_path)) {
    stop("Data file not found at: ", data_path)
  }
  
  cat("Loading data from:", data_path, "\n")
  df <- readr::read_csv(data_path, show_col_types = FALSE)
  cat("Data loaded: ", nrow(df), "rows ×", ncol(df), "columns\n")
  
  return(df)
}

#' Create stratified 3-way split (Train: 60%, Validation: 20%, Test: 20%)
#'
#' @param data Data frame with Class column
#' @param train_prop Proportion for training set (default: 0.6)
#' @param val_prop Proportion for validation set (default: 0.2)
#' @param test_prop Proportion for test set (default: 0.2)
#' @param seed Random seed for reproducibility
#' @return List containing train, validation, and test data frames
#' @export
create_stratified_split <- function(data, 
                                    train_prop = 0.6, 
                                    val_prop = 0.2, 
                                    test_prop = 0.2,
                                    seed = 42) {
  
  # Verify proportions sum to 1
  if (abs(train_prop + val_prop + test_prop - 1.0) > 1e-6) {
    stop("Proportions must sum to 1.0")
  }
  
  # Check that Class column exists
  if (!"Class" %in% colnames(data)) {
    stop("Data must contain 'Class' column for stratified splitting")
  }
  
  set.seed(seed)
  
  # First split: separate train from (val + test)
  train_val_prop <- val_prop + test_prop
  
  split1 <- rsample::initial_split(
    data, 
    prop = train_prop, 
    strata = Class
  )
  
  train <- rsample::training(split1)
  temp <- rsample::testing(split1)
  
  # Second split: separate val from test
  # Adjust proportion for second split
  val_prop_adjusted <- val_prop / train_val_prop
  
  split2 <- rsample::initial_split(
    temp,
    prop = val_prop_adjusted,
    strata = Class
  )
  
  validation <- rsample::training(split2)
  test <- rsample::testing(split2)
  
  cat("=== Data Split Complete ===\n")
  cat("Train:      ", nrow(train), "rows (", round(nrow(train)/nrow(data)*100, 2), "%)\n")
  cat("Validation: ", nrow(validation), "rows (", round(nrow(validation)/nrow(data)*100, 2), "%)\n")
  cat("Test:       ", nrow(test), "rows (", round(nrow(test)/nrow(data)*100, 2), "%)\n")
  
  return(list(
    train = train,
    validation = validation,
    test = test
  ))
}

#' Verify that stratified split maintained class distribution
#'
#' @param splits List containing train, validation, and test data frames
#' @return Data frame with class distribution comparison
#' @export
verify_split <- function(splits) {
  
  if (!all(c("train", "validation", "test") %in% names(splits))) {
    stop("splits must contain 'train', 'validation', and 'test' elements")
  }
  
  # Calculate class distribution for each split
  train_dist <- splits$train %>%
    dplyr::count(Class) %>%
    dplyr::mutate(
      Split = "Train",
      Percentage = round(n / sum(n) * 100, 4)
    )
  
  val_dist <- splits$validation %>%
    dplyr::count(Class) %>%
    dplyr::mutate(
      Split = "Validation",
      Percentage = round(n / sum(n) * 100, 4)
    )
  
  test_dist <- splits$test %>%
    dplyr::count(Class) %>%
    dplyr::mutate(
      Split = "Test",
      Percentage = round(n / sum(n) * 100, 4)
    )
  
  # Combine all distributions
  combined_dist <- dplyr::bind_rows(train_dist, val_dist, test_dist) %>%
    dplyr::select(Split, Class, Count = n, Percentage) %>%
    dplyr::arrange(Split, Class)
  
  # Calculate overall distribution
  all_data <- dplyr::bind_rows(splits$train, splits$validation, splits$test)
  overall_dist <- all_data %>%
    dplyr::count(Class) %>%
    dplyr::mutate(
      Split = "Overall",
      Percentage = round(n / sum(n) * 100, 4)
    ) %>%
    dplyr::select(Split, Class, Count = n, Percentage)
  
  # Combine with overall
  result <- dplyr::bind_rows(combined_dist, overall_dist)
  
  cat("=== Class Distribution Verification ===\n")
  print(result)
  
  # Check if distributions are similar (within 0.5% tolerance)
  train_fraud_pct <- train_dist$Percentage[train_dist$Class == 1]
  val_fraud_pct <- val_dist$Percentage[val_dist$Class == 1]
  test_fraud_pct <- test_dist$Percentage[test_dist$Class == 1]
  overall_fraud_pct <- overall_dist$Percentage[overall_dist$Class == 1]
  
  max_diff <- max(abs(c(train_fraud_pct, val_fraud_pct, test_fraud_pct) - overall_fraud_pct))
  
  if (max_diff < 0.5) {
    cat("\n✓ Class distribution preserved across splits (max difference:", round(max_diff, 4), "%)\n")
  } else {
    cat("\n⚠ Warning: Class distribution differs across splits (max difference:", round(max_diff, 4), "%)\n")
  }
  
  return(result)
}

#' Save preprocessed datasets
#'
#' @param splits List containing train, validation, and test data frames
#' @param output_dir Directory to save the datasets
#' @export
save_preprocessed_data <- function(splits, output_dir = paths$data) {
  
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Save each split
  readr::write_csv(splits$train, file.path(output_dir, "train.csv"))
  readr::write_csv(splits$validation, file.path(output_dir, "validation.csv"))
  readr::write_csv(splits$test, file.path(output_dir, "test.csv"))
  
  cat("=== Datasets Saved ===\n")
  cat("Train:      ", file.path(output_dir, "train.csv"), "\n")
  cat("Validation: ", file.path(output_dir, "validation.csv"), "\n")
  cat("Test:       ", file.path(output_dir, "test.csv"), "\n")
}
