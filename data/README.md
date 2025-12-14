# Dataset Directory

This folder should contain the credit card fraud detection dataset.

## Dataset Information

**File Name**: `creditcard.csv`  
**Source**: [Kaggle Credit Card Fraud Detection Dataset](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud)  
**File Size**: ~150 MB  
**License**: Database Contents License (DbCL) v1.0

## Download Instructions

1. Visit the dataset page: https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud
2. Click "Download" (requires Kaggle account)
3. Extract `creditcard.csv` from the downloaded archive
4. Place `creditcard.csv` in this directory (`data/`)

## Dataset Description

The dataset contains transactions made by credit cards in September 2013 by European cardholders. This dataset presents transactions that occurred in two days, where we have 492 frauds out of 284,807 transactions. The dataset is highly unbalanced, with the positive class (frauds) accounting for 0.172% of all transactions.

### Features

- **V1-V28**: Principal Component Analysis (PCA) transformed features (due to confidentiality, original features are transformed)
- **Time**: Seconds elapsed between each transaction and the first transaction in the dataset
- **Amount**: Transaction amount (not scaled)
- **Class**: Target variable (1 for fraud, 0 otherwise)

### Citation

If you use this dataset, please cite:

```
Andrea Dal Pozzolo, Olivier Caelen, Reid A. Johnson and Gianluca Bontempi. 
Calibrating Probability with Undersampling for Unbalanced Classification. 
In Symposium on Computational Intelligence and Data Mining (CIDM), IEEE, 2015
```

## Notes

- This file is excluded from version control (see `.gitignore`) due to its size
- The dataset is publicly available on Kaggle
- Ensure you have the dataset before running the analysis scripts

