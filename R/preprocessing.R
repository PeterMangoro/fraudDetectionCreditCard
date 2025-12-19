# ==============================================================================
# Preprocessing Functions: Feature Engineering and Transformation
# ==============================================================================

#' Create time-based features from Time column
#'
#' @param data Data frame with Time column (in seconds)
#' @return Data frame with additional time features
#' @export
create_time_features <- function(data) {
  
  if (!"Time" %in% colnames(data)) {
    warning("Time column not found. Skipping time feature creation.")
    return(data)
  }
  
  data <- data %>%
    dplyr::mutate(
      # Convert to hours
      Time_Hours = Time / 3600,
      
      # Extract hour of day (assuming Time starts at some point, use modulo 24)
      # Since Time is relative, we'll use modulo to get hour-like patterns
      Hour_of_Day = floor(Time_Hours) %% 24,
      
      # Day of dataset (which day since start)
      Day_of_Dataset = floor(Time_Hours / 24),
      
      # Time of day categories
      Time_of_Day = dplyr::case_when(
        Hour_of_Day >= 0 & Hour_of_Day < 6 ~ "Night",
        Hour_of_Day >= 6 & Hour_of_Day < 12 ~ "Morning",
        Hour_of_Day >= 12 & Hour_of_Day < 18 ~ "Afternoon",
        Hour_of_Day >= 18 & Hour_of_Day < 24 ~ "Evening",
        TRUE ~ "Unknown"
      )
    )
  
  cat("Created time-based features: Time_Hours, Hour_of_Day, Day_of_Dataset, Time_of_Day\n")
  
  return(data)
}

#' Create amount-based features
#'
#' @param data Data frame with Amount column
#' @return Data frame with additional amount features
#' @export
create_amount_features <- function(data) {
  
  if (!"Amount" %in% colnames(data)) {
    warning("Amount column not found. Skipping amount feature creation.")
    return(data)
  }
  
  data <- data %>%
    dplyr::mutate(
      # Log transform (add small value to avoid log(0))
      Amount_Log = log1p(Amount),  # log1p(x) = log(1 + x), handles 0 values
      
      # Square root transform
      Amount_Sqrt = sqrt(Amount),
      
      # Amount categories (bins)
      Amount_Category = dplyr::case_when(
        Amount == 0 ~ "Zero",
        Amount > 0 & Amount <= 10 ~ "Very_Small",
        Amount > 10 & Amount <= 50 ~ "Small",
        Amount > 50 & Amount <= 200 ~ "Medium",
        Amount > 200 & Amount <= 1000 ~ "Large",
        Amount > 1000 ~ "Very_Large",
        TRUE ~ "Unknown"
      ),
      
      # Standardized amount (will be properly scaled later, but useful for interactions)
      Amount_Std = scale(Amount)[, 1]
    )
  
  cat("Created amount-based features: Amount_Log, Amount_Sqrt, Amount_Category, Amount_Std\n")
  
  return(data)
}

#' Create interaction features between Amount and key V-features
#'
#' @param data Data frame with Amount and V-features
#' @param v_features Vector of V-feature names to create interactions with
#' @return Data frame with interaction features
#' @export
create_interaction_features <- function(data, v_features = NULL) {
  
  if (!"Amount" %in% colnames(data)) {
    warning("Amount column not found. Skipping interaction feature creation.")
    return(data)
  }
  
  # If no V-features specified, use top correlated ones (or first 5)
  if (is.null(v_features)) {
    # Find V-features
    v_cols <- grep("^V[0-9]+$", colnames(data), value = TRUE)
    if (length(v_cols) > 0) {
      # Use first 5 V-features or top correlated ones
      v_features <- v_cols[1:min(5, length(v_cols))]
    } else {
      warning("No V-features found. Skipping interaction feature creation.")
      return(data)
    }
  }
  
  # Create interactions with Amount
  for (v_feat in v_features) {
    if (v_feat %in% colnames(data)) {
      interaction_name <- paste0("Amount_x_", v_feat)
      data[[interaction_name]] <- data$Amount * data[[v_feat]]
    }
  }
  
  cat("Created interaction features with Amount for:", paste(v_features, collapse = ", "), "\n")
  
  return(data)
}

#' Create preprocessing recipe using tidymodels
#'
#' @param train_data Training data frame
#' @param target_var Name of target variable (default: "Class")
#' @return Preprocessing recipe object
#' @export
create_preprocessing_recipe <- function(train_data, target_var = "Class") {
  
  # Check if target variable exists
  if (!target_var %in% colnames(train_data)) {
    stop("Target variable '", target_var, "' not found in data")
  }
  
  # Create recipe
  recipe <- recipes::recipe(
    as.formula(paste(target_var, "~ .")),
    data = train_data
  ) %>%
    # Normalize all numeric predictors
    # This will scale Amount, Time features, V-features, and interactions
    recipes::step_normalize(recipes::all_numeric_predictors()) %>%
    # Handle factor variables (if any)
    recipes::step_dummy(
      recipes::all_nominal_predictors(),
      one_hot = FALSE
    ) %>%
    # Remove zero variance predictors
    recipes::step_zv(recipes::all_predictors())
  
  cat("Preprocessing recipe created\n")
  
  return(recipe)
}

#' Apply preprocessing recipe to data
#'
#' @param recipe Preprocessing recipe object
#' @param data Data frame to preprocess
#' @param training Logical, whether this is training data (for fitting recipe)
#' @return Preprocessed data frame
#' @export
apply_preprocessing <- function(recipe, data, training = FALSE) {
  
  if (training) {
    # Fit recipe on training data
    recipe <- recipes::prep(recipe, training = data)
  }
  
  # Apply recipe
  preprocessed <- recipes::bake(recipe, new_data = data)
  
  cat("Preprocessing applied. Shape:", nrow(preprocessed), "×", ncol(preprocessed), "\n")
  
  return(preprocessed)
}

#' Complete preprocessing pipeline
#'
#' @param train_data Training data
#' @param val_data Validation data (optional)
#' @param test_data Test data (optional)
#' @param create_interactions Logical, whether to create interaction features
#' @return List containing preprocessed datasets and recipe
#' @export
preprocessing_pipeline <- function(train_data, 
                                   val_data = NULL, 
                                   test_data = NULL,
                                   create_interactions = TRUE) {
  
  cat("=== Starting Preprocessing Pipeline ===\n\n")
  
  # Step 1: Create time features
  cat("Step 1: Creating time features...\n")
  train_data <- create_time_features(train_data)
  if (!is.null(val_data)) val_data <- create_time_features(val_data)
  if (!is.null(test_data)) test_data <- create_time_features(test_data)
  
  # Step 2: Create amount features
  cat("\nStep 2: Creating amount features...\n")
  train_data <- create_amount_features(train_data)
  if (!is.null(val_data)) val_data <- create_amount_features(val_data)
  if (!is.null(test_data)) test_data <- create_amount_features(test_data)
  
  # Step 3: Create interaction features (optional)
  if (create_interactions) {
    cat("\nStep 3: Creating interaction features...\n")
    train_data <- create_interaction_features(train_data)
    if (!is.null(val_data)) val_data <- create_interaction_features(val_data)
    if (!is.null(test_data)) test_data <- create_interaction_features(test_data)
  }
  
  # Step 4: Create preprocessing recipe
  cat("\nStep 4: Creating preprocessing recipe...\n")
  recipe <- create_preprocessing_recipe(train_data)
  
  # Step 5: Fit recipe on training data
  cat("\nStep 5: Fitting recipe on training data...\n")
  recipe_fitted <- recipes::prep(recipe, training = train_data)
  
  # Step 6: Apply preprocessing
  cat("\nStep 6: Applying preprocessing...\n")
  train_preprocessed <- recipes::bake(recipe_fitted, new_data = train_data)
  
  result <- list(
    train = train_preprocessed,
    recipe = recipe_fitted
  )
  
  if (!is.null(val_data)) {
    result$validation <- recipes::bake(recipe_fitted, new_data = val_data)
  }
  
  if (!is.null(test_data)) {
    result$test <- recipes::bake(recipe_fitted, new_data = test_data)
  }
  
  cat("\n=== Preprocessing Pipeline Complete ===\n")
  
  return(result)
}
