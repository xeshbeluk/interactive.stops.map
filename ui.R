library(shiny)

navbarPage(
  title = "Interactive Map",

  theme = shinytheme(theme = "flatly"),
  id = "navbar", 
  header = tags$head(
    tags$link(
      rel = "stylesheet", 
      href = "https://fonts.googleapis.com/css2?family=Poppins&display=swap"
    ),
    tags$style(HTML("
      body, label, input, button, select {
        font-family: 'Poppins', sans-serif !important;
      }
    "))
  ),
    tabPanel(title = "Map", 
    fluidPage(
      useShinyjs(),
      sidebarLayout(
        sidebarPanel(
          div(
            class = "sidebar-panel",
            selectInput(
              "dataset", 
              "Choose demographic data:", 
              choices = names(datasets)
            ),
            uiOutput("metric_ui"),
            textOutput("description"),
            br()
          ),
          div(
            class = "sidebar-panel",
            
            # Search Type Selection
            radioButtons("search_type", "Search type:",
                         choices = c("By stops" = "stops", "By routes" = "routes"),
                         selected = "stops",
                         inline = TRUE),
            
            # Dynamic UI for stop or route search
            uiOutput("search_ui"),
            
            actionButton("clean_search", "Clean all search filters"),
            br(),
            br()
          ),
          div(
            sliderInput("tract_opacity", 
                        "Adjust color layer opacity:",
                        min = 0,
                        max = 1,
                        value = 0.35,
                        step = 0.05),
            selectInput("color_scheme_choice", 
                        "Color scheme:",
                        choices = color_schemes$names),
            sliderTextInput(
                        inputId = "utilization_level",
                        label = "Filter hotspots by their urgency",
                        choices = c("Critical", "High Priority", "Moderate Priority", "Requires Attention", "Not So Critical"),
                        selected = "High Priority"
            )
          ),
          uiOutput("disclaimer"),
          width = 3 
        ),
        mainPanel(
          tabsetPanel(
            id = "map_tabs",
            
            tabPanel("Map View",
          leafletOutput("interactive_map", width = "112%", height = "1000px")
            ),
          tabPanel("Expanded Table",
                   br(),
                   actionButton("hotspots_button", "Show hotspots"),
                   actionButton("all_stops_button", "Show all stops"),
                   actionButton("show_search_button", "Show search results"),
                   downloadButton("download_table", "Download XLSX"),
                   br(),
                   br(),
                   textOutput("table_type"),
                   br(),
                   DT::dataTableOutput("filtered_stops_table")
            )
          )
        )
      ),
      tags$head(tags$script(src = jsfile)),
      leafletOutput("map")
      
    )
  ),
  tabPanel(title = "Additional Help",
           fluidPage(
             uiOutput("help"),
             tags$br(), 
             tags$img(src = "help_pic_1.png", height = "auto", width = "auto"
             )
            )
           ),
  footer = tags$footer(
    class = "footer",
    style = "position:fixed; bottom:0; width:100%; padding:10px; background-color:#f9f9f9; border-top:1px solid #333333; text-align:center;",
    HTML("2025 TriMet / Marketing & Business Development // Developed by Dmitry Solovyev / <a href='mailto:solovyed@trimet.org'>solovyed@trimet.org</a>")
  )
)