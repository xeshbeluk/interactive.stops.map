function(input, output, session) {

  selected_data <- reactive({
    req(input$dataset, input$metrics) 
    
    # Filter the selected dataset by the second column and the chosen metric
    dataset <- datasets[[input$dataset]]
    column_name <- names(dataset)[2]  # Dynamically get the second column name
    dataset %>% filter(!!sym(column_name) == input$metrics)
  })
  
  # Get metadata for the selected dataset
  dataset_info <- reactive({
    req(input$dataset)  # Ensure dataset is selected
    dataset_metadata[[input$dataset]]
  })
  
  # Render dynamic UI for metric selection
  output$metric_ui <- renderUI({
    req(dataset_info())  # Ensure metadata is available
    metrics <- dataset_info()$metrics
    selectInput(
      "metrics",
      "Filter chosen dataset by:",
      choices = c(metrics),
      selected = metrics[1]  # Default to the first metric
    )
  })
  
  # Update metrics when the dataset changes
  observeEvent(input$dataset, {
    req(dataset_info())  # Ensure metadata is available
    metrics <- dataset_metadata[[input$dataset]]$metrics
    updateSelectInput(
      session,
      "metrics",
      choices = metrics,
      selected = metrics[1]  # Reset to the first metric
    )
  })
  
  # Dynamic border opacity slider
  border_opacity <-  reactive({
    if (input$tract_opacity == 0) {
      border_opacity <- 0
    } else if (input$tract_opacity > 0 & input$tract_opacity < 0.25) {
      border_opacity <- 0.4
    } else if (input$tract_opacity >= 0.25 & input$tract_opacity < 0.5) {
      border_opacity <- 0.8
    } else {
      border_opacity <- 1
    }
  })
  
  # Dynamic thickness opacity slider
  border_thickness <-  reactive({
    if (input$tract_opacity == 0) {
      border_thickness <- 0
    } else if (input$tract_opacity > 0 & input$tract_opacity < 0.65) {
      border_thickness <- 0.5
    } else {
      border_thickness <- 1
    }
  })

  
##### SEARCHING TOOL #####  
  
  # A list of all stops in a search bar
  observe({
    req(input$search_type == "stops")
    large_stop_list <- sort(unique(totals$stop_name))
    
    updateSelectizeInput(
      session,
      inputId  = "search_stop",
      choices  = large_stop_list,
      server   = TRUE,     
      selected = character(0)     
    )
  })
  
  observe({
    req(input$search_type == "routes")
    large_routes_list <- sort(unique(routes_lines$rte))
    
    updateSelectizeInput(
      session,
      inputId  = "search_route",
      choices  = large_routes_list,
      server   = TRUE,     
      selected = character(0)     
    )
  })
  
  # Adjusting search list if the search type is changed
  
  output$search_ui <- renderUI({
    if (input$search_type == "stops") {
      # Existing search by stops input
      selectizeInput(
        inputId  = "search_stop",
        label    = "Search bus stop:",
        choices  = NULL,  # Will be updated in server
        selected = character(0),                              
        multiple = TRUE,
        options  = list(
          placeholder  = "Enter stop address...",
          onInitialize = I("function() { this.clear(true); }")
        )
      )
    } else if (input$search_type == "routes") {
      # New search by routes input
      selectizeInput(
        inputId  = "search_route",
        label    = "Search by route:",
        choices  = NULL,  # Will be updated in server
        selected = character(0),                              
        multiple = TRUE,
        options  = list(
          placeholder  = "Enter route number...",
          onInitialize = I("function() { this.clear(true); }")
        )
      )
    }
  })
  
 
  hotspots_filtered_data <- reactive({
    req(input$utilization_level)
    
    if (input$utilization_level == "Critical") {
      hotspots_level_1
    } else if (input$utilization_level == "High Priority") {
      hotspots_level_2
    } else if (input$utilization_level == "Moderate Priority") {
      hotspots_level_3
    } else if (input$utilization_level == "Requires Attention") {
      hotspots_level_4
    } else if (input$utilization_level == "Not So Critical") {
      hotspots_level_5
    }
  })
  
  # 1) A small reactiveVal to track the mode of the table.
  table_mode <- reactiveVal("all_stops")  
  # Could be "search", "hotspots", or "all_stops".
  
  # ReactiveVal to store IDs from any shape-based selection
  shape_selected_ids <- reactiveVal(NULL)
  

  # 2) When user clicks the Hotspots button, switch mode to "hotspots".
  observeEvent(input$hotspots_button, {
    table_mode("hotspots")
  })
  
  # 3) When user clicks All Stops button, switch mode to "all_stops".
  observeEvent(input$all_stops_button, {
    table_mode("all_stops")
  })
  
  # 3a) When user clicks Show search results, switch mode to "search".
  observeEvent(input$show_search_button, {
    table_mode("search")
  })
  # 4) Reactive for filtering stops from the search bar.
  
  #    If user types anything, we capture it here.
  filtered_stops <- reactive({
    if (input$search_type == "stops") {    
        s <- input$search_stop
        if (!is.null(s) && length(s) > 0) {
          pattern <- paste0("(", paste0(s, collapse = "|"), ")")
          return(totals %>% filter(grepl(pattern, stop_name, ignore.case = TRUE)))
        }
        
        # Otherwise, fall back to shape
        shape_ids <- shape_selected_ids()
        if (!is.null(shape_ids) && length(shape_ids) > 0) {
          return(totals %>% filter(LOCATION_ID %in% shape_ids))
        }
        
        return(NULL)
      }
    
    if (input$search_type == "routes") {
      s <-  input$search_route
      if (!is.null(s) && length(s) > 0) {
        chosen_stops_ids <- routes_with_stops %>%
          filter(rte %in% s) %>%
          pull(stop_id)  # This yields a simple vector of IDs
        
        # 2) Return the matching rows from totals
        return(
          totals %>%
            filter(LOCATION_ID %in% chosen_stops_ids)
        )
      } 
      
      shape_ids <- shape_selected_ids()
      if (!is.null(shape_ids) && length(shape_ids) > 0) {
        return(totals %>% filter(LOCATION_ID %in% shape_ids))
      }
      
      return(NULL)
      
    }
  })
  
  # Clean the search bar
  observeEvent(input$clean_search, {
    # Clear the selection
    if (input$search_type == "stops") {
    updateSelectizeInput(session, 
                         inputId  = "search_stop", 
                         selected = character(0)  # no selection
    )
    shape_selected_ids(NULL) }
    
    if (input$search_type == "routes") {
      updateSelectizeInput(session,
                           inputId = "search_route",
                           selected = character(0)
    )
      shape_selected_ids(NULL) }
  })
  
  
  # 5) Whenever filtered_stops changes (i.e. user typed in the search bar),
  #    update the table mode back to "search" (unless nothing is found).
  observeEvent(filtered_stops(), {
    if (!is.null(filtered_stops()) && nrow(filtered_stops()) > 0) {
      table_mode("search")
    }
  }, ignoreInit = TRUE)
  
  # 6) A reactive that picks which data frame to show based on table_mode().
  table_data <- reactive({
    mode <- table_mode()
    
    if (mode == "hotspots") {
      # Show only hotspots
      df <- hotspots_filtered_data()
    } else if (mode == "all_stops") {
      # Show all bus stops
      df <- totals
    } else {
      # Default is "search"
      df <- filtered_stops()
      # If there’s no search, this could be NULL, so handle that safely:
      if (is.null(df) || nrow(df) == 0) return(NULL)
    }
    
    
    # dropping geometry
    if (inherits(df, "sf")) {
      df <- st_drop_geometry(df)
    }
    
    df
  })

  
  observe({
    # True if no text typed
    search_empty <- is.null(input$search_stop) || length(input$search_stop) == 0
    # True if no shape-based selection
    shape_empty  <- is.null(shape_selected_ids()) || length(shape_selected_ids()) == 0
    
    # If both are empty, then indeed there's nothing to show.
    if (search_empty && shape_empty) {
      shinyjs::disable("show_search_button")
    } else {
      shinyjs::enable("show_search_button")
    }
    
    # Similarly for your download button logic:
    search_mode_active <- table_mode() == "search"
    if (search_mode_active && (search_empty && shape_empty)) {
      shinyjs::disable("download_table")
    } else {
      shinyjs::enable("download_table")
    }
  })
  
  
  # 7) Render the table using table_data().
  output$filtered_stops_table <- DT::renderDataTable({
    req(table_data())  # Wait until we have some data
    table_data() %>%
      select(
        LOCATION_ID, 
        stop_name, 
        estimated_pop_density, 
        average_total_ons, 
        average_total_offs,
        white_nh,
        black,
        native,
        asian,
        pacific,
        hispanic,
        other_race,
        two_races,
        male,
        female,
        age_below_18,
        age_18_29,
        age_30_44,
        age_45_54,
        age_55_64,
        age_65_more,
        educ_no_school,
        educ_high_or_less,
        educ_bach_or_less,
        educ_master,
        educ_prof,
        educ_phd,
        english_native,	
        average_household_size,
        median_income
      )
  }, options = list(pageLength = 10, scrollX = TRUE))
  
  
  # Table title
  output$table_type <- renderText({
    mode <- table_mode()
    
    if (mode == "hotspots") {
      return("🚨 Hotspots")  # Title for Hotspots
    } else if (mode == "all_stops") {
      return("🚏 All stops")  # Title for All Stops
    } else {
      return("🔍 Search results")  # Title for Search Mode
    }
  })

  # Download table
  
  output$download_table <- downloadHandler(
    filename = function() {
      paste("stops_data", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      req(table_data())  # Ensure there's data to download
      writexl::write_xlsx(table_data(), file)  # Use writexl::write_xlsx()
    }
  )
  
  
    # Small description for each category
  output$description <- renderText({
    dataset_metadata[[input$dataset]][[2]]
  })
  
  
  output$disclaimer <- renderUI({
    HTML(
      "<u><b>Map Guidelines</b></u><br>
This map highlights <i>hotspots</i> (dense, low-ridership stops) and displays color-coded demographic data from the 2022 American Community Survey. 
The legend in the top-right corner explains the color scheme: for example, if a red-to-green gradient is selected for median income, red represents lower income, 
and green represents higher income.<br>

<u><b>Using the Left Panel</b></u><br>
Select a demographic characteristic (age, race/ethnicity, sex, household size, education level, native English speakers, median income, safety perception, or customer satisfaction). 
Then, if applicable, choose a specific subgroup to display on the map.<br><br>

Use the <b>search bar</b> to locate a bus stop by name or find specific bus routes.<br>
<b>By stops:</b> Enter a stop name to highlight matching stops (<span style=\"color: green;\">green</span> dots) and the routes that serve them.<br>
<b>By routes:</b> Enter a route number to display only that <span style=\"color: blue;\">route</span> and its associated stops.<br>

<u><b>Map Controls</b></u><br>
- Toggle <b>hotspots</b> (<span style=\"color: red;\">red</span>) and <b>all other stops</b> (<span style=\"color: grey;\">grey</span>) using the control panel in the top-right corner.<br>
- Adjust the map scale or download a snapshot from the top-left corner.<br>
- Use the <b>opacity slider</b> to control the transparency of demographic layers.<br>
- Choose different <b>color schemes</b> using the dropdown menu, including TriMet-themed options.<br>
- Click on any map element for more details.<br><br>

Refer to the Additional Help tab for more information.
    "
    )
  })
  output$help <- renderUI({
    HTML(
      "
      <u><b>Filter Hotspots by their Urgency</b></u><br>
      You can filter hotspots based on their urgency level. Higher urgency indicates bus stops with lower ridership and higher surrounding population density. 
      The slider adjusts the strictness of this cutoff: at the highest urgency level, only stops in areas with the highest population density and lowest ridership are highlighted.
      <br><br>
      
      <u><b>Using Buffer Selection to Filter Stops</b></u><br>
      In addition to the search bar on the left panel, you can select bus stops using the buffer selection tool, 
      located in the top-left corner of the map. There are three ways to define a buffer: <br>
      
      1) Manual Polygon – Click multiple points on the map to create a custom-shaped buffer. To complete the shape, click on the first point where you started. <br>

      2) Rectangle Buffer – Click and hold while dragging to expand the rectangle. Release when you reach the desired size. <br>

      3) Circle Buffer – Click at the center of your desired area, then hold and drag outward to adjust the radius. Release to finalize the buffer. <br>

      Once a buffer is created, the system will highlight the bus stops within the selected area. You can clear all buffers using the \"Clear search bar and remove buffers\" button.
      <br><br>
      
      <u><b>Expanded Table</b></u><br>
      On the Expanded Table tab, you can explore detailed data for each bus stop. This table contains a range of demographic characteristics attached to the stops, providing estimations within 1/4 radius. 
      Below, you can find the meanings of each column name: <br><br>
              LOCATION_ID - Stop location ID <br> 
              stop_name - Stop name <br>
              estimated_pop_density - Estimated population density <br>
              average_total_ons - Average total aboardings <br>
              average_total_offs - Average total alightings <br>
              white_nh - White, non-Hispanic<br>
              black - Black <br>
              native - American Indian / Alaska Native <br>
              asian - Asian <br>
              pacific - Native Hawaiian / Pacific Islander <br>
              hispanic - Latino or Hispanic <br>
              other_race - Other races <br>
              two_races - Two or more races <br>
              male - Male <br>
              female - Female <br>
              age_below_18 - People yonger than 18 <br>
              age_18_29 - People between 18 and 29 <br>
              age_30_44 - People between 30 and 44 <br>
              age_45_54 - People between 45 and 54 <br>
              age_55_64 - People between 55 and 64 <br>
              age_65_more - People older than 65 <br>
              educ_no_school - People who did not finish high school <br>
              educ_high_or_less - People who graduated from the high school but have no bachelor's degree <br>
              educ_bach_or_less - People who have a bachelor's degree <br>
              educ_master - People who have a master's degree <br>
              educ_prof - People who have a professional degree <br>
              educ_phd - People who have PhD <br>
              english_native - People who are native speakers <br>	
              average_household_size - Average household size <br>
              median_income - Median annual income
            "
      
    )
  })
  
  
  # Adjust color scheme for polygons
  
  used_color_scheme <- reactive({
    chosen_option <- input$color_scheme_choice
    color_schemes$schemes[color_schemes$names == chosen_option][[1]]
  
  })
  
  
  # Show bus routes   

  routes_to_show <- reactive({
    
    # 1) If the user is searching "By Routes"
    if (input$search_type == "routes") {
      # Grab the chosen route(s) from the search bar
      r <- input$search_route
      
      # If the user typed in at least one route
      if (!is.null(r) && length(r) > 0) {
        return(routes_lines %>% filter(rte %in% r))
      } else {
        # If no route is typed, we check shape-based or fallback
        if (!is.null(filtered_stops()) && nrow(filtered_stops()) > 0) {
          # Possibly shape-based selection gave us some stops
          valid_routes <- routes_with_stops %>%
            filter(stop_id %in% filtered_stops()$LOCATION_ID) %>%
            pull(rte)
          return(routes_lines %>% filter(rte %in% valid_routes))
        }
        # Otherwise, show all routes
        return(routes_lines)
      }
    }
    
    # 2) Otherwise, if we’re searching "By Stops" or haven't changed the search_type from 'stops':
    # If no stops are filtered, return all routes
    if (is.null(filtered_stops()) || nrow(filtered_stops()) == 0) {
      return(routes_lines)
    }
    
    # Otherwise, find all routes serving the *filtered* stops
    valid_routes <- routes_with_stops %>%
      filter(stop_id %in% filtered_stops()$LOCATION_ID) %>%
      pull(rte)
    
    routes_lines %>%
      filter(rte %in% valid_routes)
  })
  

  
  output$interactive_map <- renderLeaflet({
    req(selected_data())
    
    # Define the color palette for polygons
    palette <- colorNumeric(
      palette = used_color_scheme(),
      domain = selected_data()$calculation
    )

    map <- leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addMapPane("all_stops", zIndex = 450) %>%
      addMapPane("back", zIndex = 300) %>% 
      addMapPane("hot", zIndex = 500) %>% 
      addMapPane("search", zIndex = 600) %>%
      addMapPane("lines", zIndex = 350) %>% 
      onRender(
        "function(el, x) {
        L.easyPrint({
          sizeModes: ['Current'],
          filename: 'mymap',
          exportOnly: true,
          hideControlContainer: true
        }).addTo(this);
      }"
      ) %>% 
      addPolygons(
        data = selected_data(),
        color = "black",  
        weight = border_thickness(),    
        opacity = border_opacity(),    
        fillColor = ~palette(calculation),  
        fillOpacity = input$tract_opacity,  
        popup = ~paste("Category:", input$metrics, "<br>", "Value:", round(calculation, 2)),
        group = input$metrics,
        options = pathOptions(pane = "back")
      ) %>%
      addLegend(
        position = "topright",
        pal = palette,
        values = selected_data()$calculation[!is.na(selected_data()$calculation)],
        title = "Color scale",
        opacity = 1
      ) %>%
      addCircleMarkers(
        data = totals,
        radius = 2,
        color = "black",
        fillOpacity = 0.7,
        popup = ~paste("Bus stop location ID:", LOCATION_ID, "<br>",
                       "Bus stop address:", stop_name, "<br>",
                       "Population density within 1/4 mile:", round(estimated_pop_density), "<br>",
                       "Boardings:", average_total_ons, "<br>",
                       "Alightings:", average_total_offs, "<br>"),
        group = "All bus stops",
        options = pathOptions(pane = "all_stops")  # Lowest zIndex
      ) %>%
      addCircleMarkers(
        data = hotspots_filtered_data(),
        radius = 6,
        color = "red",
        fillOpacity = 0.7,
        popup = ~paste("Bus stop location ID:", LOCATION_ID, "<br>",
                       "Bus stop address:", stop_name, "<br>",
                       "Population density within 1/4 mile:", round(estimated_pop_density), "<br>",
                       "Boardings:", average_total_ons, "<br>",
                       "Alightings:", average_total_offs, "<br>"),
        group = "Hotspots",
        options = pathOptions(pane = "hot")  # Render above Bus stops
      )

    
    if (!is.null(filtered_stops()) && nrow(filtered_stops()) > 0) {
      map <- map %>%
        addCircleMarkers(
          data = filtered_stops(),
          radius = 4,
          color = "green",
          fillOpacity = 0.9,
          popup = ~paste("Bus stop location ID:", LOCATION_ID, "<br>",
                         "Bus stop address:", stop_name, "<br>",
                         "Population density within 1/4 mile:", round(estimated_pop_density), "<br>",
                         "Boardings:", average_total_ons, "<br>",
                         "Alightings:", average_total_offs, "<br>"),
          group = "Search results",
          options = pathOptions(pane = "search")  # Render above Hotspots and Bus stops
        )
    }
    
    map %>%
      addLayersControl(
        overlayGroups = c("All bus stops", "Hotspots", "Route lines"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>% 
      addDrawToolbar("interactive_map",
                     targetLayerId = NULL,
                     targetGroup = "All bus stops",
                     position = "topleft",
                     polylineOptions = FALSE,
                     markerOptions = FALSE,
                     circleMarkerOptions = FALSE,
                     singleFeature = TRUE,
                     polygonOptions = drawPolygonOptions(
                       shapeOptions = drawShapeOptions(
                         color = "blue",  # Polygon border color
                         fillColor = "lightblue",  # Fill color of drawn polygons
                         opacity = 1,
                         fillOpacity = 0.4
                       )
                     ),
                     rectangleOptions = drawRectangleOptions(
                       shapeOptions = drawShapeOptions(
                         color = "blue",  # Rectangle border color
                         fillColor = "lightblue",  # Fill color of rectangles
                         opacity = 1,
                         fillOpacity = 0.4
                       )
                     ),
                     circleOptions = drawCircleOptions(
                       shapeOptions = drawShapeOptions(
                         color = "blue",  # Circle border color
                         fillColor = "lightblue",  # Fill color of circles
                         opacity = 1,
                         fillOpacity = 0.4
                       ),
                       metric = FALSE
                     )
      ) %>% 
      addPolylines(data = routes_to_show(),
                   color = "blue",
                   weight = 3,
                   opacity = 1,
                   layerId = ~rte,
                   group = "Route lines",
                   popup = ~paste("Route:", rte),
                   options = pathOptions(pane = "lines")) %>%
      hideGroup("All bus stops")
  }) 
  
  
 #### USING SHAPE BUFFERS TO CHOOSE STOPS ON THE MAP

  observeEvent(input$interactive_map_draw_new_feature, {
    feature <- input$interactive_map_draw_new_feature
    if (is.null(feature)) return()
  
    geojson_string <- jsonlite::toJSON(feature, auto_unbox = TRUE)
    drawn_sf_raw <- geojson_sf(geojson_string)
  
    feat_type <- feature$properties$feature_type  
    geom_type <- unique(st_geometry_type(drawn_sf_raw))
    
    drawn_sf <- NULL
    
    if (feat_type %in% c("polygon", "rectangle") &&
        geom_type %in% c("POLYGON", "MULTIPOLYGON")) {
      
      # 1) Rectangles and freehand Polygons both come through as real POLYGON / MULTIPOLYGON
      drawn_sf <- drawn_sf_raw
      
    } else if (feat_type == "circle" && geom_type == "POINT") {
      
      # 2) Circles come as a single POINT plus a radius in meters
      radius_m <- feature$properties$radius  
      
      # Transform the center to a projected CRS so we can buffer in meters
      center_4326 <- st_transform(drawn_sf_raw, 4326)  
      
      # Buffer the center point by radius
      circle_poly_4326 <- st_buffer(center_4326, dist = radius_m)
      
      # Transform back to lat-lon 
      drawn_sf <- st_transform(circle_poly_4326, 4326)
      
    } else {
      message("User drew a geometry type we are not handling. Type: ", geom_type,
              " (feature_type=", feat_type, ")")
      return()
    }
    
    # Make sure the geometry is valid (for self-intersecting shapes, etc.)
    if (!st_is_valid(drawn_sf)) {
      drawn_sf <- st_make_valid(drawn_sf)
    }
    
    # Now you can intersect with your sf layer of bus stops, e.g. 'totals'
    selected_ids <- totals$LOCATION_ID[
      st_intersects(totals, drawn_sf, sparse = FALSE)
    ]
    
    #Save those IDs to the reactiveVal
    shape_selected_ids(selected_ids)
    updateSelectizeInput(session, "search_stop", selected = character(0))
    
    #Switch the table to "search" mode so user sees these in the table
    table_mode("search")
    
    # Update the map's markers 
    leafletProxy("interactive_map") %>%
      clearGroup("Search results") %>%
      addCircleMarkers(
        data = totals %>% filter(LOCATION_ID %in% selected_ids),
        radius = 4,
        color = "green",
        fillOpacity = 0.9,
        popup = ~paste("Bus stop location ID:", LOCATION_ID, "<br>",
                       "Bus stop address:", stop_name, "<br>",
                       "Population density within 1/4 mile:", round(estimated_pop_density), "<br>",
                       "Boardings:", average_total_ons, "<br>",
                       "Alightings:", average_total_offs, "<br>"),
        group = "Search results",
        options = pathOptions(pane = "search")  
      )
    
    # Re-draw or keep "All bus stops"
    leafletProxy("interactive_map") %>%
      clearGroup("All bus stops") %>%
      addCircleMarkers(
        data = totals,
        radius = 2,
        color = "grey",
        fillOpacity = 0.7,
        popup = ~paste("Bus stop location ID:", LOCATION_ID, "<br>",
                       "Bus stop address:", stop_name, "<br>",
                       "Population density within 1/4 mile:", round(estimated_pop_density), "<br>",
                       "Boardings:", average_total_ons, "<br>",
                       "Alightings:", average_total_offs, "<br>"),
        group = "All bus stops",
        options = pathOptions(pane = "all_stops")
      )
  })
  
}