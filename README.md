# Predicting NYC Yellow Taxi Tips

**MSDS 6306 - Doing Data Science**  
**Southern Methodist University**  
**Master of Science in Data Science Program**

---

## Project Overview

This project analyzes tipping behavior in New York City Yellow Taxis using data from the NYC Taxi & Limousine Commission (TLC). The dual goals are:

1. **Prediction**: Build a linear regression model to predict `tip_amount` that meets the course thresholds (RMSE ≤ 2 and MAE ≤ 1.5).
2. **Insights**: Develop at least two meaningful, non-trivial insights into when, where, and why riders tip more or less.

We focus exclusively on **Yellow Taxi** trip records for one full calendar year (e.g., 2023 or 2024). Data is loaded from PARQUET files using the `arrow` package in R. A focused subset of the data (e.g., specific zones, times of day, or trip types) is used where it improves insight quality and model performance.

Key deliverables include thorough exploratory data analysis (EDA), feature engineering, model diagnostics and assumption checking, interactive visualizations, and an **RShiny dashboard** with a natural language interaction feature (powered by RAG, a fine-tuned model, or both).

---

## Key Insights (Example Placeholders – Update with Your Actual Findings)

- **Insight 1**: [Brief description of your first insight, e.g., "Tips are significantly higher during evening hours in Manhattan entertainment zones, particularly for credit card payments."]
- **Insight 2**: [Brief description of your second insight, e.g., "Longer trips with higher fare amounts show a non-linear relationship with tip percentage, moderated by passenger count and borough."]

These insights are supported by targeted visualizations, statistical tests, and thoughtful interpretation grounded in the data.

---

## Prediction Model

We built a **linear regression model** (limited to methods covered in MSDS 6306) to predict `tip_amount`.

- **Performance**: RMSE = [Your value ≤ 2], MAE = [Your value ≤ 1.5]
- **Features**: [List key predictors after selection and engineering, e.g., trip_distance, fare_amount, passenger_count, pickup_hour, PULocationID (as factor or selected zones), payment_type, etc.]
- **Techniques Applied**:
  - Feature engineering (e.g., time-of-day bins, log transformations, interaction terms)
  - Outlier detection and handling
  - Assumption checks (linearity, normality of residuals, homoscedasticity, multicollinearity via VIF)
  - Variable selection process

Full model diagnostics and evaluation are in the `code/` directory.

---

## RShiny Dashboard

The interactive dashboard allows users to:
- Explore tipping patterns through filters (time, zone, trip characteristics)
- View key visualizations and model results
- Ask natural language questions about the analysis, insights, and model (e.g., “What factors most influence tips in Midtown?” or “How does the model perform on airport trips?”)

**Live App Link**: [Add your deployed Shiny app URL here once hosted on shinyapps.io or similar]

The natural language feature is grounded in the project’s analysis, model coefficients, and prepared knowledge base for reliable, context-specific responses.

---

## Repository Structure

```bash
NYC-Yellow-Taxi-Tips/
├── data/                  # Raw and processed PARQUET/CSV files (gitignore large raw files if needed)
│   └── yellow_tripdata_YYYY-MM.parquet   # Example files
├── code/
│   ├── 01_load_data.R             # Reading PARQUET with arrow
│   ├── 02_data_cleaning.R         # Cleaning, tip variable definition
│   ├── 03_eda_and_insights.R      # Visualizations and insight development
│   ├── 04_modeling.R              # Linear regression, diagnostics, evaluation
│   └── 05_shiny_prep.R            # Data prep for dashboard
├── shiny_app/
│   ├── app.R                      # Main Shiny application
│   ├── ui.R / server.R            # (if modular)
│   ├── rag_or_llm/                # Folder for RAG setup or fine-tuned model components
│   └── www/                       # CSS, images, etc.
├── outputs/                       # Saved plots, model objects, tables
├── docs/                          # Presentation deck PDF, video link, report
├── README.md
└── LICENSE
```