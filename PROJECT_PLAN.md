# Fraud Detection Project: R Markdown Analysis Structure

## Project Structure

```
fraudDetectionCreditCard/
├── analysis/
│   ├── 00_setup.Rmd              # Environment setup, libraries, seed
│   ├── 01_eda.Rmd                # Exploratory Data Analysis
│   ├── 02_preprocessing.Rmd      # Data preprocessing & feature engineering
│   ├── 03_baseline.Rmd          # Baseline models
│   ├── 04_imbalance_techniques.Rmd  # SMOTE, class weights, undersampling comparison
│   ├── 05_model_selection.Rmd   # RF, XGBoost, Logistic Regression comparison
│   ├── 06_hyperparameter_tuning.Rmd  # Hyperparameter optimization
│   ├── 07_evaluation.Rmd         # Comprehensive evaluation & metrics
│   ├── 08_threshold_optimization.Rmd  # Threshold tuning & cost analysis
│   ├── 09_model_interpretation.Rmd   # Feature importance, SHAP/LIME
│   └── 10_final_model.Rmd       # Final model training & test evaluation
├── R/
│   ├── setup.R                   # Package installation & loading
│   ├── data_utils.R              # Data loading & splitting functions
│   ├── preprocessing.R           # Preprocessing pipelines
│   ├── modeling.R                # Model training functions
│   ├── evaluation.R              # Metrics & evaluation functions
│   └── visualization.R           # Custom plotting functions
├── models/                       # Saved model files (.rds)
├── data/
│   └── creditcard.csv           # Dataset (already exists)
├── results/                      # Generated outputs
│   ├── figures/                 # Plots and visualizations
│   ├── tables/                  # Summary tables
│   └── models/                  # Trained models
└── README.md                     # Project documentation
```

## Implementation Plan

### Phase 1: Project Setup (R/setup.R, analysis/00_setup.Rmd)

**R/setup.R:**

- Load all required packages (tidymodels, themis, yardstick, vip, DALEX, ggplot2, plotly, DT, etc.)
- Set global options (reproducibility, figure settings)
- Define project paths

**analysis/00_setup.Rmd:**

- Set random seed for reproducibility
- Load setup.R
- Display R session info and package versions
- Define cost matrix (if applicable)
- Create results directories

### Phase 2: Data Understanding (analysis/01_eda.Rmd)

**Key analyses:**

- Load creditcard.csv
- Class distribution analysis (with exact counts and percentages)
- Missing values check
- Duplicate detection
- Outlier analysis (especially for Amount)
- Feature distributions (V1-V28, Time, Amount) by class
- Correlation analysis (correlation matrix, correlation with Class)
- Time feature analysis (distribution, patterns)
- Amount feature analysis (distribution, statistics by class)

**Visualizations:**

- Class imbalance bar chart
- Feature distribution plots (fraud vs non-fraud)
- Correlation heatmap
- Amount distribution by class
- Time distribution analysis

### Phase 3: Data Preprocessing (R/data_utils.R, R/preprocessing.R, analysis/02_preprocessing.Rmd)

**R/data_utils.R:**

- `create_stratified_split()`: 3-way split function (60-20-20)
- `verify_split()`: Check class distribution preservation
- Data loading functions

**R/preprocessing.R:**

- `create_time_features()`: Extract hour, day features from Time
- `create_amount_features()`: Log transform, binning
- `preprocessing_pipeline()`: Complete preprocessing recipe using tidymodels

**analysis/02_preprocessing.Rmd:**

- Perform 3-way split (train: 60%, validation: 20%, test: 20%)
- Verify stratified splitting maintained class distribution
- Feature engineering:
  - Time-based features (hour, day of week if derivable)
  - Amount transformations (log, sqrt)
  - Interaction features (Amount × key V-features)
- Scaling: RobustScaler for Amount, StandardScaler for Time
- Save preprocessed datasets
- Display summary statistics

### Phase 4: Baseline Models (analysis/03_baseline.Rmd)

**Baselines to establish:**

- Majority class classifier (always predict non-fraud)
- Logistic Regression (simple, interpretable)
- Random Forest with default parameters

**Evaluation:**

- Use validation set for initial comparison
- Report: Accuracy, Precision, Recall, F1, MCC, PR-AUC
- Create baseline comparison table
- Document why these baselines are important

### Phase 5: Imbalance Techniques Comparison (analysis/04_imbalance_techniques.Rmd)

**Techniques to compare:**

- No sampling + class weights
- SMOTE (using themis package)
- ADASYN
- Borderline-SMOTE
- Random Undersampling
- SMOTEENN (combination)
- SMOTETomek (combination)

**Implementation:**

- Apply each technique to training set only (within CV)
- Use Random Forest as base model
- Compare using stratified 5-fold CV
- Report metrics: Precision, Recall, F1, MCC, PR-AUC
- Create comparison table and visualization
- Statistical significance testing (McNemar's test or paired t-test)

### Phase 6: Model Selection (analysis/05_model_selection.Rmd)

**Models to compare:**

- Logistic Regression (with class weights)
- Random Forest (with best imbalance technique from Phase 5)
- XGBoost (with best imbalance technique)
- Ensemble (voting/stacking)

**Implementation:**

- Use validation set for quick comparison
- Use best imbalance technique from Phase 5
- Train each model with default/reasonable hyperparameters
- Compare using comprehensive metrics
- Create model comparison table
- Visualize performance differences
- Select best model(s) for hyperparameter tuning

### Phase 7: Hyperparameter Tuning (analysis/06_hyperparameter_tuning.Rmd)

**Tuning strategy:**

- Use nested cross-validation (5-fold outer, 3-fold inner)
- Tune on training set only
- Optimize for PR-AUC or F1-score

**Hyperparameters to tune:**

- **Random Forest**: n_estimators, max_depth, min_samples_split, min_samples_leaf
- **XGBoost**: learning_rate, max_depth, nrounds, subsample, colsample_bytree
- **Logistic Regression**: regularization strength (if using)

**Implementation:**

- Use tidymodels `tune_grid()` or `tune_bayes()`
- Create tuning plots
- Select best hyperparameters
- Document final hyperparameter values

### Phase 8: Comprehensive Evaluation (R/evaluation.R, analysis/07_evaluation.Rmd)

**R/evaluation.R:**

- `calculate_all_metrics()`: Comprehensive metric calculation
- `create_confusion_matrix()`: Confusion matrix at different thresholds
- `bootstrap_metrics()`: Bootstrap confidence intervals
- `statistical_tests()`: McNemar's test, paired t-tests

**analysis/07_evaluation.Rmd:**

- Train final models with best hyperparameters on train+validation combined
- Evaluate on test set (first time test set is used)
- Report all metrics: Precision, Recall, F1, MCC, PR-AUC, ROC-AUC
- Create confusion matrices at multiple thresholds (0.3, 0.4, 0.5, 0.6, 0.7)
- Bootstrap confidence intervals for key metrics
- Statistical significance testing between models
- Precision-Recall curves
- ROC curves (for comparison, though PR-AUC is primary)
- Cost-benefit analysis (if cost matrix defined)

### Phase 9: Threshold Optimization (analysis/08_threshold_optimization.Rmd)

**Analysis:**

- Precision-Recall curve analysis
- Find optimal threshold for different objectives:
  - Maximum F1-score
  - Maximum F-beta (beta=2 for recall emphasis)
  - Cost-optimized threshold
- Create threshold analysis plots
- Show precision-recall trade-offs
- Recommend threshold based on business needs
- Evaluate final model at optimal threshold

### Phase 10: Model Interpretation (analysis/09_model_interpretation.Rmd)

**Interpretation methods:**

- Feature importance (from Random Forest/XGBoost)
- Permutation importance (validate feature importance)
- SHAP values (using vip package or fastshap)
- LIME (for local explanations)
- Partial dependence plots

**Visualizations:**

- Feature importance plots (compare across models)
- SHAP summary plots
- SHAP waterfall plots for specific fraud cases
- Feature interaction analysis

### Phase 11: Final Model & Summary (analysis/10_final_model.Rmd)

**Final steps:**

- Train final model on all available data (train+validation+test combined)
- Save final model (.rds file)
- Create model card documenting:
  - Model type and hyperparameters
  - Training data characteristics
  - Performance metrics
  - Limitations and assumptions
- Generate executive summary
- Create final comparison table of all techniques
- Document key findings and recommendations

## Key Enhancements Over Guide

1. **3-way split**: Proper train/validation/test separation
2. **Nested CV**: For hyperparameter tuning
3. **Statistical testing**: McNemar's test, bootstrap CIs
4. **Enhanced feature engineering**: Time features, interactions, transformations
5. **Multiple imbalance techniques**: ADASYN, Borderline-SMOTE, combinations
6. **Cost-sensitive evaluation**: Cost matrix and cost-optimized thresholds
7. **Comprehensive metrics**: All recommended metrics + bootstrap CIs
8. **Model interpretation**: SHAP, LIME, permutation importance
9. **Reproducibility**: Seeds, session info, package versioning
10. **Modular structure**: Separate files for each phase

## R Package Stack

- **tidymodels**: ML workflow (recipes, parsnip, tune, yardstick)
- **themis**: SMOTE, ADASYN, undersampling
- **vip**: Variable importance, SHAP
- **DALEX**: Model explainability
- **xgboost**: XGBoost implementation
- **ranger**: Fast Random Forest
- **ggplot2**: Static plots
- **plotly**: Interactive plots
- **DT**: Interactive tables
- **knitr/kableExtra**: Professional tables

## Next Steps (After R Markdown)

Once R Markdown analysis is complete and validated:

- Create Shiny app structure
- Integrate trained models
- Build interactive dashboard
- Add real-time prediction interface

