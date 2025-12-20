# ==============================================================================
# Project Setup: Package Loading and Configuration
# ==============================================================================

# Check and install required packages if needed
required_packages <- c(
  # Core ML and modeling
  "tidymodels",      # ML workflow framework
  "themis",          # SMOTE and imbalance techniques
  "yardstick",       # Model evaluation metrics
  "vip",             # Variable importance and SHAP
  "DALEX",           # Model explainability
  "xgboost",         # XGBoost implementation
  "ranger",          # Fast Random Forest
  "glmnet",          # Regularized regression for Logistic Regression tuning
  "dials",           # Parameter grids for tuning
  "isotree",         # Isolation Forest for anomaly detection
  
  # Data manipulation
  "dplyr",           # Data manipulation
  "readr",           # Reading CSV files
  "tidyr",           # Data tidying
  
  # Visualization
  "ggplot2",         # Static plots
  "plotly",          # Interactive plots
  "DT",              # Interactive tables
  "corrplot",        # Correlation plots
  
  # Reporting
  "knitr",           # R Markdown
  "kableExtra",      # Enhanced tables
  "rmarkdown",       # R Markdown rendering
  "broom"            # Tidy model outputs
)

# Function to check and install packages
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    install.packages(new_packages, dependencies = TRUE)
  }
}

# Install missing packages
install_if_missing(required_packages)

# Load all required packages
suppressPackageStartupMessages({
  library(tidymodels)
  library(themis)
  library(yardstick)
  library(vip)
  library(DALEX)
  library(xgboost)
  library(ranger)
  library(glmnet)
  library(dials)
  library(isotree)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
  library(plotly)
  library(DT)
  library(corrplot)
  library(knitr)
  library(kableExtra)
  library(rmarkdown)
  library(broom)
})

# ==============================================================================
# Global Options and Configuration
# ==============================================================================

# Set ggplot2 theme
theme_set(theme_minimal(base_size = 11) +
            theme(
              plot.title = element_text(face = "bold", size = 14),
              plot.subtitle = element_text(size = 12),
              axis.title = element_text(face = "bold"),
              legend.position = "bottom"
            ))

# Set knitr options for better output
options(
  knitr.kable.NA = '',
  knitr.table.format = "html",
  dplyr.print_min = 10,
  dplyr.print_max = 10,
  scipen = 999  # Prevent scientific notation
)

# ==============================================================================
# Project Paths
# ==============================================================================

# Get project root directory
# This works when R Markdown files are in analysis/ and R scripts are in R/
# If running from R Markdown, the working directory should be set to project root
# If running as script from R/ folder, go up one level
current_dir <- getwd()
if (basename(current_dir) == "R") {
  project_root <- dirname(current_dir)
} else if (basename(current_dir) == "analysis") {
  project_root <- dirname(current_dir)
} else {
  # Assume we're already in project root
  project_root <- current_dir
}

# Define paths
paths <- list(
  root = project_root,
  data = file.path(project_root, "data"),
  analysis = file.path(project_root, "analysis"),
  results = file.path(project_root, "results"),
  figures = file.path(project_root, "results", "figures"),
  tables = file.path(project_root, "results", "tables"),
  models = file.path(project_root, "results", "models"),
  R = file.path(project_root, "R")
)

# Create results directories if they don't exist
dir.create(paths$figures, showWarnings = FALSE, recursive = TRUE)
dir.create(paths$tables, showWarnings = FALSE, recursive = TRUE)
dir.create(paths$models, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# Helper Functions
# ==============================================================================

# Function to print package versions (for reproducibility)
print_package_versions <- function() {
  cat("=== Package Versions ===\n")
  packages <- c("tidymodels", "themis", "yardstick", "vip", "DALEX", 
                "xgboost", "ranger", "dplyr", "ggplot2", "isotree")
  for (pkg in packages) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat(sprintf("%-15s: %s\n", pkg, packageVersion(pkg)))
    }
  }
}

# Print confirmation
cat("Setup complete! All packages loaded.\n")
cat("Project root:", paths$root, "\n")

