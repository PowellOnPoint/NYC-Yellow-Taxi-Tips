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

---

## Key Insights (In Development)

We are currently finalizing two substantive insights supported by visualizations, statistical analysis, and domain context.  

**Insight 1** (Draft):  
[To be updated – e.g., Tips are substantially higher for credit-card payments during evening rush hours in Manhattan entertainment zones.]

**Insight 2** (Draft):  
[To be updated – e.g., Trip distance and fare_per_mile show a non-linear relationship with tip amount, moderated by passenger_count and pickup_borough/time-of-day.]

Detailed supporting visualizations and interpretations are located in `code/03_eda_and_insights.R`.

---

## Prediction Model

**Model**: Multiple linear regression (using methods covered in MSDS 6306) predicting `tip_amount`.

**Current Status**: Models built and under evaluation (see latest commit “models built”).

**Planned / In-Progress Details**:
- **Performance Target**: RMSE ≤ 2.0 | MAE ≤ 1.5  
- **Key Features**: trip_distance, fare_amount (or derived fare_per_mile), passenger_count, pickup_hour, pickup_dow, airport indicator, payment_type, and engineered variables (log transformations, time-of-day bins, interactions)
- **Techniques Applied**:
  - Feature engineering and variable selection
  - Outlier detection and handling
  - Full assumption checking (linearity, residual normality, homoscedasticity, multicollinearity via VIF)
  - Diagnostic plots and influence measures

Full modeling code, diagnostics, and evaluation are in `code/04_modeling.R`.

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
├── data/                          # Raw and processed PARQUET/CSV files
├── code/
│   ├── load_data.R                # Reading PARQUET with arrow
│   ├── data_cleaning.R            # Cleaning, tip variable definition
│   ├── validate_data.R            # Visualizations and insight developmentn
├── shiny_app/
│   ├── app.R                      # Main Shiny application
│   ├── ui.R / server.R            # (if modular)
│   └── rag/                       # Folder for RAG setup or fine-tuned model components
├── docs/                          # Presentation deck, video link, notes
├── README.md
└── LICENSE
```

## Data Source

NYC Taxi & Limousine Commission (TLC) – Yellow Taxi Trip Records
https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

## Author

Aaron Powell – MSDS Candidate, Southern Methodist University

# Acknowledgments

Course instructors: Dr. Bivin Sadler 
Dataset: [NYC Taxi & Limousine Commission (TLC)](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) – Yellow Taxi Trip Records 
Special thanks to the SMU MSDS program