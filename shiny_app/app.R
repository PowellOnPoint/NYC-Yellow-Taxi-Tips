library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(plotly)
library(readr)
library(DT)

# Load data by default
if (!exists("train_data")) {
  train_data <- read_csv("train.csv", show_col_types = FALSE)
}

# Load data dictionary
data_dict <- readLines("data_description.txt", warn = FALSE)

# Prepare choices
numeric_vars <- names(train_data)[sapply(train_data, is.numeric)]
numeric_vars <- setdiff(numeric_vars, "Id")
cat_vars <- names(train_data)[sapply(train_data, function(x) is.character(x) || is.factor(x))]
neighborhoods <- sort(unique(train_data$Neighborhood))

ui <- dashboardPage(
  dashboardHeader(title = "House Prices EDA"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Scatterplot", tabName = "scatter"),
      menuItem("Barchart", tabName = "bar"),
      menuItem("Data Viewer", tabName = "data"),
      menuItem("Data Dictionary", tabName = "dictionary")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "scatter",
        fluidRow(
          box(width = 12, status = "primary",
            title = "Scatterplot Explorer",
            plotlyOutput("scatter_plot", height = "600px")
          )
        ),
        fluidRow(
          box(width = 4, title = "Variables",
            selectInput("x_var", "X Variable", choices = numeric_vars, selected = "GrLivArea"),
            selectInput("y_var", "Y Variable", choices = numeric_vars, selected = "SalePrice"),
            selectInput("color_var", "Color by", choices = c("None" = "none", cat_vars), selected = "none")
          ),
          box(width = 4, title = "Filters",
            selectInput("neigh_filter", "Neighborhoods", 
                        choices = neighborhoods, 
                        selected = neighborhoods[1:5],
                        multiple = TRUE),
            sliderInput("alpha", "Point opacity", 0.1, 1, 0.6, step = 0.1)
          ),
          box(width = 4, title = "Options",
            checkboxInput("log_scale", "Log scale (both axes)", FALSE),
            checkboxInput("add_smooth", "Add trend line", FALSE)
          )
        )
      ),
      tabItem(tabName = "bar",
        fluidRow(
          box(width = 12, status = "primary",
            title = "Barchart",
            plotlyOutput("bar_plot", height = "500px")
          )
        ),
        fluidRow(
          box(width = 6, title = "Settings",
            selectInput("bar_x", "Category (X)", choices = cat_vars, selected = "Neighborhood"),
            selectInput("bar_fill", "Fill by", choices = c("None" = "none", cat_vars), selected = "none"),
            checkboxInput("bar_percent", "Show as percentage", FALSE)
          ),
          box(width = 6, title = "Options",
            selectInput("bar_theme", "Theme", choices = c("Minimal", "Classic", "Light")),
            checkboxInput("bar_flip", "Flip coordinates", FALSE)
          )
        )
      ),
      tabItem(tabName = "data",
        fluidRow(
          box(width = 12, status = "primary",
            title = "Raw House Prices Data",
            DT::dataTableOutput("data_table", height = "600px")
          )
        )
      ),
      tabItem(tabName = "dictionary",
        fluidRow(
          box(width = 12, status = "primary",
            title = "Data Dictionary",
            verbatimTextOutput("data_dict", placeholder = FALSE)
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Reactive filtered data for scatter
  filtered_data <- reactive({
    req(input$neigh_filter)
    train_data %>%
      filter(Neighborhood %in% input$neigh_filter)
  })
  
  output$scatter_plot <- renderPlotly({
    data <- filtered_data()
    req(input$x_var, input$y_var)
    
    p <- ggplot(data, aes(x = .data[[input$x_var]], y = .data[[input$y_var]])) +
      geom_point(alpha = input$alpha, size = 2) +
      theme_minimal() +
      labs(title = paste(input$y_var, "vs", input$x_var, 
                        "(filtered to", length(input$neigh_filter), "neighborhoods)"),
           x = input$x_var, y = input$y_var)
    
    if (input$color_var != "none") {
      p <- p + aes(color = .data[[input$color_var]]) +
        labs(color = input$color_var)
    }
    
    if (input$log_scale) {
      p <- p + scale_x_log10() + scale_y_log10()
    }
    
    if (input$add_smooth) {
      p <- p + geom_smooth(method = "lm", se = FALSE)
    }
    
    ggplotly(p, tooltip = c("x", "y", "colour"))
  })
  
  output$bar_plot <- renderPlotly({
    req(input$bar_x)
    
    if (input$bar_fill == "none") {
      data_sum <- train_data %>%
        count(.data[[input$bar_x]], name = "n") %>%
        arrange(desc(n))
      
      p <- ggplot(data_sum, aes(x = reorder(.data[[input$bar_x]], n), y = n)) +
        geom_col(fill = "steelblue")
    } else {
      data_sum <- train_data %>%
        count(.data[[input$bar_x]], .data[[input$bar_fill]], name = "n")
      
      totals <- data_sum %>%
        group_by(.data[[input$bar_x]]) %>%
        summarize(total = sum(n), .groups = "drop") %>%
        arrange(desc(total))
      
      data_sum <- data_sum %>%
        mutate(!!input$bar_x := factor(.data[[input$bar_x]], levels = totals[[input$bar_x]]))
      
      p <- ggplot(data_sum, aes(x = .data[[input$bar_x]], 
                               y = n, 
                               fill = .data[[input$bar_fill]])) +
        geom_col(position = if (input$bar_percent) "fill" else "stack")
    }
    
    p <- p +
      theme_minimal() +
      labs(title = paste("Distribution of", input$bar_x),
           x = input$bar_x)
    
    if (input$bar_percent) {
      p <- p + labs(y = "Proportion")
    } else {
      p <- p + labs(y = "Count")
    }
    
    if (input$bar_flip) {
      p <- p + coord_flip()
    }
    
    # Apply selected theme
    if (input$bar_theme == "Classic") {
      p <- p + theme_classic()
    } else if (input$bar_theme == "Light") {
      p <- p + theme_light()
    }
    
    ggplotly(p)
  })
  
  # Data table for viewer tab
  output$data_table <- DT::renderDataTable({
    train_data
  }, options = list(
    pageLength = 15,
    scrollX = TRUE,
    searching = TRUE,
    lengthMenu = c(10, 25, 50, 100, nrow(train_data))
  ), rownames = FALSE)
  
  # Data dictionary
  output$data_dict <- renderPrint({
    cat(paste(data_dict, collapse = "\n"))
  })
  
}

shinyApp(ui, server)
