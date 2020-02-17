library(shiny)
library(shinydashboard)
library(htmlwidgets)
library(leaflet)
library(maps)
library(tidyverse)
library(RColorBrewer)

load("../output/Econ_state_map.RData")

Econ_data_state <- Econ_data_state %>% 
                    filter(Name!="Alaska" | Name!="Hawaii") %>% 
                    mutate(Name=gsub('Lousiana', 'Louisiana', Name))
                    
  

mapStates = maps::map("state", fill = TRUE, plot = FALSE)

state_map <- function(df){
  df$values <- df[,3] 
  names <- tibble(Name=str_to_upper(mapStates$names)) %>% 
    separate(Name, c('Name', 'sub'), ':') %>% 
    select(Name)
  
  df <- df %>% 
    mutate(Name = str_to_upper(Name)) %>% 
    right_join(names)
  
  pal <- colorBin("YlOrRd", domain = df$values, bins=9)
  labels <- sprintf(
    "<strong>%s</strong><br/>%g ",    #unit: people / mi<sup>2</sup>
    df$Name, df$values
  ) %>% lapply(htmltools::HTML)
  
  # State Map
  leaflet(data = mapStates) %>% 
    setView(-96, 37.8, 4) %>% 
    addTiles() %>%
    addPolygons(
      fillColor = pal(df$values),
      weight = 2, 
      opacity = 1, 
      color='white',
      dashArray = 3,
      fillOpacity = .7,
      highlight = highlightOptions(
        weight = 5,
        color = "#666",
        dashArray = " ",
        fillOpacity = .75,
        bringToFront = T
      ),
      label = labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", 'padding' = "10px 15px", 'box-shadow' = '3px 3px rgba(0,0,0,0.25)'),
        textsize = "15px",
        direction = "auto")) %>% 
  addLegend(pal = pal, values = df$values, opacity = 0.85, title = NULL,
  position = "bottomright")
}