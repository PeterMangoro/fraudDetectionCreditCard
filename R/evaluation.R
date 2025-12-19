# ==============================================================================
# Evaluation Functions: Metrics and Model Evaluation
# ==============================================================================

#' Calculate comprehensive metrics for classification model
#'
#' @param truth True class labels (factor or numeric)
#' @param estimate Predicted class labels (factor or numeric)
#' @param prob Predicted probabilities for positive class (optional)
#' @return Data frame with all metrics
#' @export
calculate_all_metrics <- function(truth, estimate, prob = NULL) {
  
  # Convert to factors with matching levels
  # Convert to character first to handle any factor/numeric input
  truth_char <- as.character(truth)
  estimate_char <- as.character(estimate)
  
  # Map numeric values to labels if needed
  truth_char[truth_char == "0"] <- "Non-Fraud"
  truth_char[truth_char == "1"] <- "Fraud"
  estimate_char[estimate_char == "0"] <- "Non-Fraud"
  estimate_char[estimate_char == "1"] <- "Fraud"
  
  # Convert to factors with explicit levels
  truth <- factor(truth_char, levels = c("Non-Fraud", "Fraud"))
  estimate <- factor(estimate_char, levels = c("Non-Fraud", "Fraud"))
  
  # Calculate metrics using yardstick (individual functions)
  result <- data.frame(
    Accuracy = yardstick::accuracy_vec(truth, estimate),
    Precision = yardstick::precision_vec(truth, estimate),
    Recall = yardstick::recall_vec(truth, estimate),
    F1 = yardstick::f_meas_vec(truth, estimate),
    MCC = yardstick::mcc_vec(truth, estimate),
    Sensitivity = yardstick::sens_vec(truth, estimate),
    Specificity = yardstick::spec_vec(truth, estimate)
  )
  
  # Add PR-AUC and ROC-AUC if probabilities provided
  if (!is.null(prob)) {
    # PR-AUC (truth should be factor)
    pr_auc <- yardstick::pr_auc_vec(truth, prob)
    result$PR_AUC <- pr_auc
    
    # ROC-AUC (truth should be factor)
    roc_auc <- yardstick::roc_auc_vec(truth, prob)
    result$ROC_AUC <- roc_auc
  }
  
  return(result)
}

#' Create confusion matrix with counts and percentages
#'
#' @param truth True class labels
#' @param estimate Predicted class labels
#' @param threshold Probability threshold (if probabilities provided)
#' @return Confusion matrix data frame
#' @export
create_confusion_matrix <- function(truth, estimate, threshold = 0.5) {
  
  # Convert to factors with matching levels
  truth_char <- as.character(truth)
  estimate_char <- as.character(estimate)
  truth_char[truth_char == "0"] <- "Non-Fraud"
  truth_char[truth_char == "1"] <- "Fraud"
  estimate_char[estimate_char == "0"] <- "Non-Fraud"
  estimate_char[estimate_char == "1"] <- "Fraud"
  truth <- factor(truth_char, levels = c("Non-Fraud", "Fraud"))
  estimate <- factor(estimate_char, levels = c("Non-Fraud", "Fraud"))
  
  # Create confusion matrix
  df_cm <- data.frame(truth = truth, estimate = estimate)
  cm <- yardstick::conf_mat(df_cm, truth, estimate)
  
  # Extract counts
  cm_table <- as.data.frame(cm$table)
  
  # Calculate percentages
  total <- sum(cm_table$Freq)
  cm_table$Percentage <- round(cm_table$Freq / total * 100, 2)
  
  return(cm_table)
}

#' Calculate cost-based metrics using cost matrix
#'
#' @param truth True class labels
#' @param estimate Predicted class labels
#' @param cost_matrix List with TP, FP, FN, TN costs
#' @return Total cost and cost breakdown
#' @export
calculate_cost_metrics <- function(truth, estimate, cost_matrix) {
  
  # Convert to factors with matching levels
  truth_char <- as.character(truth)
  estimate_char <- as.character(estimate)
  truth_char[truth_char == "0"] <- "Non-Fraud"
  truth_char[truth_char == "1"] <- "Fraud"
  estimate_char[estimate_char == "0"] <- "Non-Fraud"
  estimate_char[estimate_char == "1"] <- "Fraud"
  truth <- factor(truth_char, levels = c("Non-Fraud", "Fraud"))
  estimate <- factor(estimate_char, levels = c("Non-Fraud", "Fraud"))
  
  # Create confusion matrix
  df_cm <- data.frame(truth = truth, estimate = estimate)
  cm <- yardstick::conf_mat(df_cm, truth, estimate)
  cm_table <- as.data.frame(cm$table)
  
  # Extract counts
  TP <- sum(cm_table$Freq[cm_table$Truth == "Fraud" & cm_table$Prediction == "Fraud"])
  FP <- sum(cm_table$Freq[cm_table$Truth == "Non-Fraud" & cm_table$Prediction == "Fraud"])
  FN <- sum(cm_table$Freq[cm_table$Truth == "Fraud" & cm_table$Prediction == "Non-Fraud"])
  TN <- sum(cm_table$Freq[cm_table$Truth == "Non-Fraud" & cm_table$Prediction == "Non-Fraud"])
  
  # Calculate costs
  total_cost <- TP * cost_matrix$TP + 
                FP * cost_matrix$FP + 
                FN * cost_matrix$FN + 
                TN * cost_matrix$TN
  
  cost_breakdown <- data.frame(
    Metric = c("TP", "FP", "FN", "TN", "Total"),
    Count = c(TP, FP, FN, TN, TP + FP + FN + TN),
    Cost_Per_Instance = c(cost_matrix$TP, cost_matrix$FP, cost_matrix$FN, cost_matrix$TN, NA),
    Total_Cost = c(TP * cost_matrix$TP, 
                   FP * cost_matrix$FP, 
                   FN * cost_matrix$FN, 
                   TN * cost_matrix$TN,
                   total_cost)
  )
  
  return(list(
    total_cost = total_cost,
    breakdown = cost_breakdown
  ))
}

#' Evaluate model on dataset
#'
#' @param model Trained model object
#' @param data Test/validation data
#' @param target_var Name of target variable
#' @param cost_matrix Optional cost matrix for cost calculation
#' @return List with predictions, metrics, and confusion matrix
#' @export
evaluate_model <- function(model, data, target_var = "Class", cost_matrix = NULL) {
  
  # Get predictions
  if (inherits(model, "workflow")) {
    # tidymodels workflow
    predictions <- stats::predict(model, new_data = data, type = "prob")
    predictions_class <- stats::predict(model, new_data = data, type = "class")
    
    # Extract probabilities and classes
    prob <- predictions$.pred_Fraud
    estimate <- predictions_class$.pred_class
  } else {
    # Assume it's a parsnip model
    predictions <- stats::predict(model, new_data = data, type = "prob")
    predictions_class <- stats::predict(model, new_data = data, type = "class")
    
    prob <- predictions$.pred_Fraud
    estimate <- predictions_class$.pred_class
  }
  
  # Get truth
  truth <- data[[target_var]]
  
  # Calculate metrics
  metrics <- calculate_all_metrics(truth, estimate, prob)
  
  # Create confusion matrix
  cm <- create_confusion_matrix(truth, estimate)
  
  # Calculate cost if cost matrix provided
  cost_result <- NULL
  if (!is.null(cost_matrix)) {
    cost_result <- calculate_cost_metrics(truth, estimate, cost_matrix)
  }
  
  return(list(
    predictions = data.frame(
      truth = truth,
      estimate = estimate,
      prob = prob
    ),
    metrics = metrics,
    confusion_matrix = cm,
    cost = cost_result
  ))
}

#' Create baseline comparison table
#'
#' @param results_list List of evaluation results (from evaluate_model)
#' @param model_names Vector of model names
#' @return Formatted comparison table
#' @export
create_baseline_comparison <- function(results_list, model_names) {
  
  # Extract metrics from each result
  metrics_list <- lapply(results_list, function(x) x$metrics)
  
  # Combine into single data frame
  comparison <- dplyr::bind_rows(metrics_list) %>%
    dplyr::mutate(Model = model_names) %>%
    dplyr::select(Model, dplyr::everything())
  
  # Round numeric columns
  numeric_cols <- sapply(comparison, is.numeric)
  comparison[numeric_cols] <- round(comparison[numeric_cols], 4)
  
  return(comparison)
}

#' Print evaluation summary
#'
#' @param eval_result Evaluation result from evaluate_model
#' @param model_name Name of the model
#' @export
print_evaluation_summary <- function(eval_result, model_name) {
  
  cat("\n", "=", rep("=", 60), "\n", sep = "")
  cat("Evaluation Summary:", model_name, "\n")
  cat("=", rep("=", 60), "\n\n", sep = "")
  
  cat("Metrics:\n")
  print(eval_result$metrics)
  
  cat("\nConfusion Matrix:\n")
  cm_wide <- eval_result$confusion_matrix %>%
    tidyr::pivot_wider(names_from = Prediction, values_from = Freq)
  print(cm_wide)
  
  if (!is.null(eval_result$cost)) {
    cat("\nCost Analysis:\n")
    print(eval_result$cost$breakdown)
    cat("\nTotal Cost: $", eval_result$cost$total_cost, "\n", sep = "")
  }
  
  cat("\n")
}
