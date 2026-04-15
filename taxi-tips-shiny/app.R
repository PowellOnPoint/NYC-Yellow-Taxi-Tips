# app.R - NYC Yellow Taxi Tips Shiny Dashboard
# MSDS 6306 Final Project - PowellOnPoint Team
# Updated with selectable variable plots per requirements

library(shiny)
library(bs4Dash)      
library(plotly)
library(ggplot2)      # Added for custom plots
library(stringr)
library(DT)
library(dplyr)
library(forcats)
library(httr2)
library(jsonlite)
library(tidyr)        # Added for pivot_longer
library(dotenv)       # Added for .env loading

load_dot_env()        # Load environment variables from .env

# Load pre-processed assets (now in app directory)
taxi_data <- readRDS("taxi_cleaned.rds")  
model_fit <- readRDS("tip_model.rds")           
knowledge_chunks <- readLines("knowledge_base.txt")

# Define variable lists based on ds dataset for dynamic inputs
numeric_vars <- c("trip_distance", "tip_amount", "tip_pct", "total_amount", 
                  "fare_per_mile", "trip_duration_min", "trip_speed_mph", 
                  "pickup_hour", "log_trip_distance", "log_total_amount")

categorical_vars <- c("pickup_dow", "RatecodeID", "passenger_count", "weekend", 
                      "rush_hour", "airport", "VendorID", "overnight", "PULocationID",
                      "DOLocationID")

knowledge_base <- paste(knowledge_chunks, collapse = "\n")
chunks <- strsplit(knowledge_base, "\n\n")[[1]]

# Function to get embeddings via HF API
get_embeddings <- function(texts) {
  if (is.character(texts)) texts <- as.list(texts)
  
  token <- Sys.getenv("HF_TOKEN", "YOUR_HF_TOKEN")
  if (token == "YOUR_HF_TOKEN") {
    warning("HF_TOKEN not set in .env file")
    return(list())
  }
  
  req <- request("https://api-inference.huggingface.co/models/sentence-transformers/all-MiniLM-L6-v2") %>%
    req_headers(Authorization = paste("Bearer", token)) %>%
    req_body_json(list(inputs = texts))
  
  tryCatch({
    resp <- req_perform(req)
    resp_body_json(resp)
  }, error = function(e) {
    warning("HF embeddings API error: ", e$message)
    list()  # fallback
  })
}

# Precompute embeddings for chunks (run once at app start)
chunk_embeddings <- get_embeddings(chunks)

# Cosine similarity function
cosine_similarity <- function(a, b) {
  if (length(a) == 0 || length(b) == 0) return(0)
  sum(a * b) / (sqrt(sum(a^2)) * sqrt(sum(b^2)))
}

# Simple embedding/retrieval helper
get_relevant_context <- function(query, top_k = 3) {
  if (length(chunk_embeddings) == 0) {
    # Fallback to keyword matching
    scores <- sapply(chunks, function(c) sum(stringr::str_detect(tolower(c), tolower(strsplit(query, " ")[[1]]))))
    top_idx <- order(scores, decreasing = TRUE)[1:top_k]
    return(paste(chunks[top_idx], collapse = "\n"))
  }
  query_emb <- get_embeddings(list(query))[[1]]
  if (is.null(query_emb)) {
    # Fallback
    scores <- sapply(chunks, function(c) sum(stringr::str_detect(tolower(c), tolower(strsplit(query, " ")[[1]]))))
    top_idx <- order(scores, decreasing = TRUE)[1:top_k]
    return(paste(chunks[top_idx], collapse = "\n"))
  }
  similarities <- sapply(chunk_embeddings, function(ce) cosine_similarity(query_emb, ce))
  top_indices <- order(similarities, decreasing = TRUE)[1:min(top_k, length(chunks))]
  paste(chunks[top_indices], collapse = "\n")
}

# HF LLM call
call_hf_llm <- function(prompt, model = "google/flan-t5-small") {
  req <- request("https://api-inference.huggingface.co/models/") %>%
    req_url_path_append(model) %>%
    req_headers("Authorization" = paste("Bearer", Sys.getenv("HF_TOKEN", "YOUR_HF_TOKEN"))) %>%
    req_body_json(list(inputs = prompt, parameters = list(max_new_tokens = 100, temperature = 0.7)))
  tryCatch({
    resp <- req_perform(req)
    content <- resp_body_json(resp)
    trimws(content[[1]][[1]]$generated_text)
  }, error = function(e) {
    paste("HF API error (check token or rate limits). Using local insight instead:\nTips are higher for longer distances and specific ratecodes like airport trips.")
  })
}

ui <- dashboardPage(
  dashboardHeader(title = "NYC Taxi Tips Explorer"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("home")),
      menuItem("Scatterplots", tabName = "scatter", icon = icon("chart-line")),
      menuItem("Boxplots", tabName = "boxplot", icon = icon("box")),
      menuItem("Histograms", tabName = "histogram", icon = icon("chart-bar")),
      menuItem("Insights & Viz", tabName = "insights", icon = icon("lightbulb")),
      menuItem("Tip Predictor", tabName = "predict", icon = icon("calculator")),
      menuItem("Ask Taxi Driver", tabName = "ask", icon = icon("question"))
    )
  ),
  dashboardBody(
    tabItems(
      # Overview
      tabItem("overview",
        fluidRow(
          box(
            title = "Project Overview", 
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            HTML("
              <p><strong>Predicting NYC Yellow Taxi Tips</strong> — MSDS 6306 Final Project at SMU.</p>
              <p>This dashboard supports two goals:</p>
              <ol>
                <li><strong>Prediction</strong>: Linear regression for <code>tip_amount</code></li>
                <li><strong>Insights</strong>: Interactive visualizations of tipping behavior.</li>
              </ol>
              <p>Data from cleaned 2025 Yellow Taxi records. All plots are interactive.</p>
            ")
          )
        ),
        fluidRow(
          valueBoxOutput("n_trips", width = 3),
          valueBoxOutput("avg_tip", width = 3),
          valueBoxOutput("avg_tip_pct", width = 3),
          valueBoxOutput("model_rsq", width = 3)
        ),
        fluidRow(
          box(title = "Summary Statistics", width = 12, status = "info", DTOutput("summary_table"))
        )
      ),
      
      # Scatterplots - selectable numerical with trend lines and CI
      tabItem("scatter",
        fluidRow(
          box(
            title = "Scatterplot Explorer (Numeric Variables)",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            fluidRow(
              column(3, selectInput("scatter_x", "X Variable:", choices = numeric_vars, selected = "trip_distance")),
              column(3, selectInput("scatter_y", "Y Variable:", choices = numeric_vars, selected = "tip_amount")),
              column(3, selectInput("scatter_color", "Color By:", choices = c("None", categorical_vars), selected = "None")),
              column(3, checkboxInput("show_smooth", "Show LM Trend Line + 95% CI", value = TRUE))
            ),
            plotlyOutput("scatter_plot", height = "600px")
          )
        ),
        fluidRow(
          box(title = "How to Use", width = 12, status = "warning",
              "Choose any numeric variables from the cleaned dataset. Enable trendline to see linear relationship and confidence band. Hover for details.")
        )
      ),
      
      # Boxplots - categorical with proper ordering
      tabItem("boxplot",
        fluidRow(
          box(
            title = "Boxplots by Categorical Variables",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            fluidRow(
              column(4, selectInput("box_x", "Group By (Categorical):", choices = categorical_vars, selected = "pickup_dow")),
              column(4, selectInput("box_y", "Measure (Y):", choices = c("tip_amount", "tip_pct"), selected = "tip_amount")),
              column(4, checkboxInput("box_order", "Order Categories by Median", value = TRUE))
            ),
            plotlyOutput("box_plot", height = "550px")
          )
        ),
        fluidRow(
          box(title = "Interpretation Note", width = 12, status = "warning",
              "Boxplots show distribution of tips across categories. When ordered by median, patterns in tipping behavior become clear (e.g. which days or ratecodes have higher tips).")
        )
      ),
      
      # Histograms - interactive
      tabItem("histogram",
        fluidRow(
          box(
            title = "Interactive Histograms",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            fluidRow(
              column(4, selectInput("hist_var", "Variable to Plot:", choices = numeric_vars, selected = "tip_amount")),
              column(4, sliderInput("hist_bins", "Bins:", min = 10, max = 80, value = 30, step = 5)),
              column(4, selectInput("hist_color", "Fill By (Optional):", choices = c("None", categorical_vars), selected = "None"))
            ),
            plotlyOutput("hist_plot", height = "550px")
          )
        ),
        fluidRow(
          box(title = "Note", width = 12, status = "warning",
              "Histograms are fully interactive with plotly - zoom, hover, and compare distributions by category.")
        )
      ),
      
      # Insights & Viz
      tabItem("insights",
        fluidRow(
          box(title = "Tipping Patterns by Hour and Ratecode", width = 12,
              selectInput("ratecode_filter", "Filter Ratecodes:", 
                         choices = unique(taxi_data$RatecodeID), multiple = TRUE),
              plotlyOutput("tip_viz", height = "500px")
          )
        ),
        fluidRow(
          box(title = "Group Summary", width = 12, DTOutput("insights_table"))
        )
      ),
      
      # Predictor
      tabItem("predict",
        fluidRow(
          box(title = "Adjust Inputs for Prediction", width = 6, status = "primary",
              sliderInput("trip_dist", "Trip Distance (miles)", 0, 30, value = 5, step = 0.1),
              sliderInput("trip_duration", "Trip Duration (minutes)", 0, 120, value = 15, step = 1),
              selectInput("ratecode", "Ratecode", choices = unique(taxi_data$RatecodeID), selected = "1"),
              checkboxInput("is_weekend", "Weekend Trip?", FALSE)
          ),
          box(title = "Results", width = 6, status = "info",
              verbatimTextOutput("pred_output")
          )
        )
      ),
      # Ask Taxi Driver
      tabItem("ask",
        fluidRow(
          box(title = "Ask the Taxi Driver", width = 12, status = "primary",
              textInput("question", "Ask a question about NYC taxi tips:"),
              actionButton("submit", "Submit"),
              verbatimTextOutput("response")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Reactive filtered data for Overview tab
  overview_data <- reactive({
    taxi_data
  })

  # Value boxes for overview
  output$n_trips <- renderValueBox({
    valueBox(value = format(nrow(taxi_data), big.mark = ","), subtitle = "Total Trips", icon = icon("taxi"), color = "primary")
  })
  
  output$avg_tip <- renderValueBox({
    avg_val <- round(mean(taxi_data$tip_amount, na.rm = TRUE), 2)
    valueBox(value = paste0("$", avg_val), subtitle = "Average Tip", icon = icon("dollar-sign"), color = "success")
  })
  
  output$avg_tip_pct <- renderValueBox({
    pct_val <- round(mean(taxi_data$tip_pct, na.rm = TRUE) * 100, 1)
    valueBox(value = paste0(pct_val, "%"), subtitle = "Average Tip %", icon = icon("percent"), color = "info")
  })
  
  output$model_rsq <- renderValueBox({
    rsq <- round(summary(model_fit)$r.squared, 3)
    valueBox(value = rsq, subtitle = "Model R²", icon = icon("chart-line"), color = "warning")
  })
  
  # Summary table
  output$summary_table <- renderDT({
    summary_stats <- taxi_data |> 
      select(where(is.numeric)) |> 
      summarise(across(everything(), list(
        Mean = ~round(mean(.x, na.rm = TRUE), 2),
        SD = ~round(sd(.x, na.rm = TRUE), 2),
        Min = ~round(min(.x, na.rm = TRUE), 2),
        Max = ~round(max(.x, na.rm = TRUE), 2)
      ), .names = "{.col}.{.fn}")) |> 
      pivot_longer(everything(), names_to = c("Variable", ".value"), names_sep = "\\.")
    datatable(summary_stats)
  })
  
  # Scatterplot output
  output$scatter_plot <- renderPlotly({
    p <- ggplot(taxi_data, aes(x = !!sym(input$scatter_x), y = !!sym(input$scatter_y)))
    if (input$scatter_color != "None") {
      p <- p + aes(color = !!sym(input$scatter_color))
    }
    p <- p + geom_point(alpha = 0.7, size = 2)
    if (input$show_smooth) {
      p <- p + geom_smooth(method = "lm", se = TRUE)
    }
    p <- p + labs(title = paste(input$scatter_y, "vs", input$scatter_x), x = input$scatter_x, y = input$scatter_y)
    ggplotly(p) |> layout(legend = list(orientation = "h", y = -0.2))
  })
  
  # Boxplot output
  output$box_plot <- renderPlotly({
    data <- taxi_data
    if (input$box_order) {
      data <- data |> mutate(!!sym(input$box_x) := fct_reorder(factor(!!sym(input$box_x)), !!sym(input$box_y), median, na.rm = TRUE))
    }
    p <- ggplot(data, aes(x = !!sym(input$box_x), y = !!sym(input$box_y), fill = !!sym(input$box_x))) +
      geom_boxplot(outlier.alpha = 0.4) +
      labs(title = paste("Boxplot of", input$box_y, "by", input$box_x), x = input$box_x, y = input$box_y)
    ggplotly(p)
  })
  
  # Histogram output
  output$hist_plot <- renderPlotly({
    p <- ggplot(taxi_data, aes(x = !!sym(input$hist_var)))
    if (input$hist_color == "None") {
      p <- p + geom_histogram(bins = input$hist_bins, alpha = 0.8, fill = "blue")
    } else {
      p <- p + geom_histogram(bins = input$hist_bins, alpha = 0.8, aes(fill = !!sym(input$hist_color)), position = "dodge")
    }
    p <- p + labs(title = paste("Histogram of", input$hist_var), x = input$hist_var, y = "Count")
    ggplotly(p) |> layout(legend = list(orientation = "h", y = -0.2))
  })
  
  output$tip_viz <- renderPlotly({
    filtered <- taxi_data %>% filter(RatecodeID %in% input$ratecode_filter | length(input$ratecode_filter) == 0)
    plot_ly(filtered, x = ~pickup_hour, y = ~tip_amount, type = "scatter", mode = "markers") %>%
      layout(title = "Tip Amount by Pickup Hour")
  })
  
  output$insights_table <- renderDT({
    group_summary <- taxi_data |> group_by(RatecodeID) |> summarise(avg_tip = round(mean(tip_amount), 2), avg_pct = round(mean(tip_pct)*100, 1))
    datatable(group_summary)
  })
  
  # Dynamic prediction reactive
  predicted_tip <- reactive({
    new_data <- data.frame(
      trip_distance = input$trip_dist,
      trip_duration_min = input$trip_duration,
      RatecodeID = as.factor(input$ratecode),
      weekend = input$is_weekend
    )
    pred <- predict(model_fit, newdata = new_data)
    paste("Predicted Tip: $", round(pred, 2), "\nProjected Total: $", round(pred / 0.173, 2))
  })
  
  output$pred_output <- renderText({
    predicted_tip()
  })
  
  # Ask Taxi Driver RAG reactive
  ask_response <- eventReactive(input$submit, {
    context <- get_relevant_context(input$question)
    prompt <- paste0("Please answer the question based on the context.\nContext: ", context, "\nQuestion: ", input$question)
    call_hf_llm(prompt)
  })
  
  output$response <- renderText({
    ask_response()
  })
  
}

shinyApp(ui, server)
