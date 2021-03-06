#install.packages("shiny")
#install.packages("shinydashboard")
#install.packages("leaflet")
#install.packages("maps")
#install.packages("tidyverse")
#install.packages("viridis")
#install.packages("leaflet.extras")
#install.packages("RColorBrewer")
#install.packages("ggplot2")
#install.packages("plotly")
#install.packages("scales")
#install.packages("shinyWidgets")
#############################################################################################
library(shiny)
library(shinydashboard)
library(leaflet)
library(maps)
library(tidyverse)
library(viridis)
library(leaflet.extras)
library(RColorBrewer)
library(ggplot2)
library(plotly)
library(scales)
library(shinyWidgets)
#### County leaflet written by Jinxu Xiang

load("Econ_county_map_modified.RData")
zoom_xjx = rep(7, length(state.abb))
zoom_xjx[c(4)] = 6
zoom_xjx[c(1,3,9,12,13,14,15,16,17,22,23,25,27,31,32,33,34,36,38,39,40,44,46)] = 8
zoom_xjx[c(6,7,18,19,28,43)] = 9
zoom_xjx[c(37)] = 10

state_choise_xjx = state.abb
names(state_choise_xjx) = state.name
state_choise_xjx = c(state_choise_xjx[1],state_choise_xjx[3:10], state_choise_xjx[12:length(state_choise_xjx)])

county_map_xjx <- function(df){
  mapcounty <- maps::map("county", regions = state.name[which(state.abb == df$State[1])], fill = TRUE, plot = FALSE)
  names <- tibble(Name = mapcounty$names) %>% 
    separate(Name, c('state', 'county'), ',') %>% 
    mutate(state = paste0(toupper(substr(state,1,1)), substr(state, 2, nchar(state)))) %>% 
    mutate(county = paste0(toupper(substr(county,1,1)), substr(county, 2, nchar(county)), ifelse(state == 'Louisiana', ' Parish', ' County')))
  
  
  
  df <- df %>% 
    right_join(names, by = c('Name' = 'county')) %>% 
    arrange(State, Year)
  values <- c(unlist(df[,4]))
  metric <- colnames(df)[4]
  chs <- df[1,5]
  year <- df[1,3]
  state <- state.name[which(state.abb == df$State[1])]
  pal <- colorBin("YlGnBu", domain = values, bins = 9)
  
  if(metric == '% of adults with less than a high school diploma' | 
     metric == '% of adults with a high school diploma only' | 
     metric == '% of adults completing some college' | 
     metric == '% of adults with a bachelor\'s degree or higher' |
     metric == 'Unemployment Rate' | 
     metric == '% of people in poverty' | 
     metric == '% of people age 0-17 in poverty' ){
    end_label = '%'
  }
  else if(metric == 'Birth rate' | 
          metric == 'Death rate' | 
          metric == 'Natural population increase rate' | 
          metric == 'Net migration rate'){
    end_label = '\u2030'
  }
  else if(metric == 'Civilian Labor Force' | metric == 'Population'){
    end_label = ' people'
  }
  else{
    end_label = '$'
  }
  
  if(chs == 1)
    labels <- sprintf(
      "<strong>%s, %s </strong><br/><strong>%s<br/>in %s</strong><br/>%s%s",    
      state, df$Name, metric, year, prettyNum(signif(values, 4),big.mark=",",scientific=FALSE), end_label)
  else if(chs == 2)
    labels <- sprintf(
      "<strong>%s, %s </strong><br/><strong>%s<br/>from %s</strong><br/>%s%s",    
      state, df$Name, metric, year, prettyNum(signif(values, 4),big.mark=",",scientific=FALSE), end_label)
  else
    labels <- sprintf(
      "<strong>%s, %s </strong><br/><strong>%s<br/>from %s</strong><br/>%s%%",    
      state, df$Name, metric, year, prettyNum(signif(values, 4),big.mark=",",scientific=FALSE))
  labels = labels%>% 
    lapply(htmltools::HTML)
  
  range <- mapcounty$range
  
  # County Map
  leaflet(data = mapcounty) %>% 
    setView(mean(range[1:2]), mean(range[3:4]), zoom_xjx[which(state_choise_xjx== df$State[1])]) %>% 
    addTiles() %>%
    addResetMapButton() %>% 
    addPolygons(
      fillColor = pal(values),
      weight = 2, 
      opacity = 1, 
      color='white',
      dashArray = 3,
      fillOpacity = .7,
      highlight = highlightOptions(
        weight = 5,
        color = "#666",
        dashArray = "",
        fillOpacity = .75,
        bringToFront = T
      ),
      label = labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", 'padding' = "10px 15px"),
        textsize = "15px",
        direction = "auto")
      ) %>%  
    addLegend(pal = pal,
            values = values,
            opacity = 0.85,
            title = NULL,
            position = "bottomright")
}
####################################################################################################
# Yuqiao Liu
load("Econ_state_map_modified.RData")
Econ_data_state <- Econ_data_state %>% mutate(Name = str_to_upper(Name))

mapStates = maps::map("state", fill = TRUE, plot = FALSE)
names <- tibble(Name=str_to_upper(mapStates$names)) %>% 
  separate(Name, c('Name', 'sub'), ':') %>% 
  select(Name)

state_map <- function(df, input_metric, chs, start_year, end_year=NULL){
  unit <- unit_lyq(input_metric, chs)
  pal <- colorBin("YlGnBu", domain = df$Value)
  
  if(chs != 'Specific year'){
    labels <- sprintf(
      "<strong>%s<br/>%s<br/>From %s to %s</strong><br/>%s %s",
      df$Name, input_metric, start_year, end_year, prettyNum(signif(df$Value, 4),big.mark=",",scientific=FALSE), unit) %>%
      lapply(htmltools::HTML)
  }
  else{
    labels <- sprintf(
      "<strong>%s<br/>%s<br/>%s</strong><br/>%s %s",
      df$Name, input_metric, start_year, prettyNum(signif(df$Value, 4), big.mark=",",scientific=FALSE), unit) %>%
      lapply(htmltools::HTML)
  }
  
  
  #State Map
  leaflet(data = mapStates) %>%  
    setView(-96, 37.8, 4.3) %>%
    addTiles() %>%
    addResetMapButton() %>% 
    addPolygons(
      fillColor = pal(df$Value),
      weight = 2,
      opacity = 1,
      color='white',
      dashArray = 3,
      fillOpacity = .7,
      highlightOptions = highlightOptions(weight = 4,
                                          color = "#666",
                                          dashArray = "",
                                          fillOpacity = .75,
                                          bringToFront = T
      ),  
      label = labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", 'padding' = "10px 15px"),
        textsize = "15px",
        direction = "auto")
    ) %>%
    addLegend(pal = pal,
              values = df$Value,
              opacity = 0.85,
              title = NULL,
              position = "bottomright")
}

unit_lyq <- function(input_metric, chs){
  if(chs == '%Change by time') '%'
  else{
    if(input_metric %in% colnames(Econ_data_state[c(4:7, 9, 12, 14, 16, 17)])) '%'
    else if(input_metric %in% colnames(Econ_data_state[c(10, 11)])) '\u2030'
    else if(input_metric %in% colnames(Econ_data_state[c(8, 13)])) 'people'
    else if(input_metric %in% colnames(Econ_data_state)[15]) 'dollars'
  }
}
  
###########################################################################################
##Specific Stats
####Zidi Hong
theme_set(theme_light())
index1<-function(df){
  df[,3]%>%unlist()
}
index2<-function(df){
  df[,4]%>%unlist()
}
index<-function(df){
  df%>%select(-Name,-Year,-State)%>%unlist()
}

abb_zh = with(Econ_data_county %>% 
  select(State) %>%unique() %>% c(), State)
name_zh = c(state.name[1:8], 'Washington D.C', state.name[9:50], 'Puerto Rico')
names(abb_zh) = name_zh

###########################################################################################

## Vikki Sui
load("counties_new.RData")
basemetric_choice <- c("Education", "Employment", "Population")
metric_choice <- counties_new$Metric %>% unique()
state_choice <-counties_new$State %>% unique()
