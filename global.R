library(mapview)
library(dplyr)
library(ggplot2)
library(sf)
library(maps)
library(osmdata)
library(readxl)
library(tidycensus)
library(jsonlite)
library(stringr)
library(purrr)
library(tidyr)
library(shiny)
library(shinyWidgets)
library(leaflet)
library(htmltools)
library(htmlwidgets)
library(tibble)
library(shinythemes)
library(leaflegend)
library(leaflet.extras)
library(writexl)
library(shinyjs)
library(geojsonsf)
library(lwgeom)
## Loading datasets

# Bus routes
routes_lines <- st_read("data/routes.geojson") 
routes_lines <- st_transform(routes_lines, crs = 4326)

routes_with_stops <- read.csv("data/stops_and_routes.csv")

# Hotspot datasets
hotspots_level_1 <- read.csv("data/hotspots_1.csv")
hotspots_level_1 <- st_as_sf(hotspots_level_1, coords = c("X", "Y"), crs = 4326) 
hotspots_level_2 <- read.csv("data/hotspots_2.csv")
hotspots_level_2 <- st_as_sf(hotspots_level_2, coords = c("X", "Y"), crs = 4326) 
hotspots_level_3 <- read.csv("data/hotspots_3.csv")
hotspots_level_3 <- st_as_sf(hotspots_level_3, coords = c("X", "Y"), crs = 4326) 
hotspots_level_4 <- read.csv("data/hotspots_4.csv")
hotspots_level_4 <- st_as_sf(hotspots_level_4, coords = c("X", "Y"), crs = 4326) 
hotspots_level_5 <- read.csv("data/hotspots_5.csv")
hotspots_level_5 <- st_as_sf(hotspots_level_5, coords = c("X", "Y"), crs = 4326) 

# All bus stops dataset

totals <- read.csv("data/all_stops_data.csv")

totals <- totals %>% 
  drop_na() %>% 
  mutate(across(white:english_native, ~ round(.x, digits = 0))) %>%
  mutate(estimated_pop_density = round(estimated_pop_density, 0)) %>% 
  mutate(across(average_household_size:median_income, ~ round(.x, digits = 1)))
totals <- st_as_sf(totals, coords = c("X", "Y"), crs = 4326) 
totals <- totals %>% 
  select(LOCATION_ID:geometry)


# Age, race and sex datasets (adults)
age_dataset <- st_read("data/age_dataset.geojson")
race_dataset <- st_read("data/race_dataset.geojson")
sex_dataset <- st_read("data/sex_dataset.geojson")
household_dataset <- st_read("data/total_household_dataset.geojson")
education_dataset <- st_read("data/education_dataset.geojson")
language_dataset <- st_read("data/language_dataset.geojson")
median_income_dataset <- st_read("data/median_income_dataset.geojson")
safety_zipcode <- st_read("data/safety_zipcode.geojson")
approval_zipcode <- st_read("data/approval_zipcode.geojson")

# Getting variables from the ACS for search
var_df <- load_variables(2022, "acs5", cache = TRUE)


# Datasets metadata

datasets <- list(
  "Age" = age_dataset,
  "Race" = race_dataset,
  "Sex" = sex_dataset,
  "Household size" = household_dataset,
  "Education" = education_dataset,
  "Language" = language_dataset,
  "Median income" = median_income_dataset,
  "Safety perception" = safety_zipcode,
  "Riders approval" = approval_zipcode
)

dataset_metadata <- list(
  "Age" = list(
    metrics = unique(age_dataset$age),
    "The proportion of the population in the selected age group (%) in a given tract."
  ),
  "Race" = list(
    metrics = unique(race_dataset$race),
    "The proportion of the population that belongs to the selected race or ethnicity (%) in a given tract."
  ),
  "Sex" = list(
    metrics = unique(sex_dataset$sex),
    "The proportion of the population identified as the selected sex group (%) in a given tract."
  ),
  "Household size" = list(
    metrics = unique(household_dataset$average_household),
    "The average number of people living in a household in a given tract."
  ),
  "Education" = list(
    metrics = unique(education_dataset$education_group),
    "The proportion of people with the selected level of education as their highest completed level (%) in a given tract. 
    Each group represents the highest level of education completed. 
    For example, people in the 'Bachelor’s degree' group also include those who completed high school or some college work."
  ),
  "Language" = list(
    metrics = unique(language_dataset$language),
    "The proportion of the population who are native English speakers (%) in a given tract."
  ),
  "Median income" = list(
    metrics = unique(median_income_dataset$median),
    "The median income ($) of households in a given tract during the past 12 months."
  ),
  "Safety perception" = list(
    metrics = unique(safety_zipcode$mode_t),
    "The average safety score (1: Not safe at all to 7: Very safe) for a chosen mode of transport (Bus or MAX) in a given ZIP area."
  ),
  "Riders approval" = list(
    metrics = unique(approval_zipcode$approval_t),
    "The average approval score (1: Strongly disapprove to 5: Strongly approve) for a chosen mode of transport (Bus or MAX) in a given ZIP area."
  )
)


esriPlugin <- htmlDependency("leaflet.esri", "1.0.3",
                             src = c(href = "https://cdn.jsdelivr.net/leaflet.esri/1.0.3/"),
                             script = "esri-leaflet.js"
)

registerPlugin <- function(map, plugin) {
  map$dependencies <- c(map$dependencies, list(plugin))
  map
}

jsfile <- "https://rawgit.com/rowanwins/leaflet-easyPrint/gh-pages/dist/bundle.js"



color_schemes <- tibble(names = c("Red to green (diverging)", 
                                  "Green to red (diverging)", 
                                  "Brown to jade green (diverging)" , 
                                  "TriMet blue to orange (diverging)",
                                  "TriMet orange to blue (diverging)",
                                  "Blue (sequential)", 
                                  "Jade green (sequential)"), 
                            schemes = list(c("#D1441E", "yellow", "green"), 
                                           c("green", "yellow", "#D1441E"), 
                                           c("#a6611a", "#dfc27d", "#f5f5f5", "#80cdc1", "#018571"), 
                                           c("#084C8D", "#8FD0F2", "#D1441E", "#D2462A"),
                                           c("#D2462A", "#D1441E", "#8FD0F2", "#084C8D"),
                                           "Blues",
                                           c("#edf8fb", "#b2e2e2", "#66c2a4", "#2ca25f", "#006d2c")
                                           )
                        )

                          

