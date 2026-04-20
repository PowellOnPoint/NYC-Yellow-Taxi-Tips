# Predicting NYC Yellow Taxi Tips

**MSDS 6306 - Doing Data Science**  
**Southern Methodist University**  
**Master of Science in Data Science Program**

---

## Project Overview

This project analyzes tipping behavior in New York City Yellow Taxis using data from the NYC Taxi & Limousine Commission (TLC). The dual goals are:

1. **Prediction**: Build a linear regression model to predict `tip_amount`.
2. **Insights**: Develop at least two meaningful, non-trivial insights into when, where, and why riders tip more or less.

We focus exclusively on **Yellow Taxi** trip records for one full calendar year (e.g., 2023 or 2024). Data is loaded from PARQUET files using the `arrow` package in R. A focused subset of the data (e.g., specific zones, times of day, or trip types) is used where it improves insight quality and model performance.


## RShiny Dashboard

The interactive dashboard allows users to:
- Explore tipping patterns through filters (time, zone, trip characteristics)
- View key visualizations and model results
- Ask natural language questions about the analysis, insights, and model!

**Live App Link**: [PowellOnPoint.shinyapp.io/taxi-tips](https://powellonpoint.shinyapps.io/taxi-tips)]

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
│   ├── insights.rmd
│   ├── insights.html
│   ├── prediction.rmd
│   └── prediction.html
├── docs/
│   ├── plots/
│   ├── app.r
│   ├── taxi_clean.rds             # Cleaned Data for app
│   ├── tip_model.rds              # Model for tip prediction
│   └── executive_summary.pptx
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