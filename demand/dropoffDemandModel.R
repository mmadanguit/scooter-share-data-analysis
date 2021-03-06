library(tidyverse)
library(sf)
library(mapview)
dropoffDemandMap <- function(fol){
  tripsPerTract <- read_csv(paste(c(fol, "tripsPerTract.csv"), collapse=''))
  # setwd("~/Documents/github/pvd_summer/")
  # tripsPerTract is imported csv with all trips per tract data
  trips <- tripsPerTract %>% select(c('TRACT','event_time','n')) 
  
  # CONSTRUCT TRIPS INFO
  dt <- as.data.frame(str_split_fixed(trips$event_time, " ", 2)) # separate date and time
  trips <- trips %>% select(c('TRACT','n')) %>% cbind(DATE = dt$V1, TIME = dt$V2) %>%
    filter(TRACT <= 37) %>% group_by(TRACT) %>% filter(DATE > "2019-01-01")
  
  
  # LOAD GEODATA AND SIMPLIFY TRACT #s
  geoData <- readRDS("censusData/riDataGeo.Rds")
  geoData$TRACT = as.double(geoData$NAME %>% str_remove_all("\\p{Letter}") %>% 
                              str_remove_all("\\N{Comma}") %>%
                              str_remove_all("\\h")) # white space
  geoData <- geoData %>% arrange(geoData$TRACT)
  
  # CREATE FILLED IN TRIPS DATA
  days <- as.character(seq(as.Date("2019/1/1 00:00:00"), by = "day", length.out = 365)) # data for a whole year
  tracts <- geoData$TRACT # all the tracts
  tripsF <- data.frame(TRACT = rep(c(tracts), times=length(days))) %>% # tract entry for each day
    arrange(TRACT) %>% # sort by tract
    mutate(n = 0, DATE = rep(c(days), times=length(tracts)), TIME = NA) %>% # add date entry for every tract
    group_by(TRACT) %>% filter(!DATE %in% trips$DATE) %>% # remove existing data points
    bind_rows(trips) %>% arrange(DATE, .by_group=TRUE) %>% # add existing trips data
    mutate(DAY = weekdays(as.Date(DATE))) # enter weekday 
  # trips$DAY <- weekdays(as.Date(trips$DATE))
  trips <- tripsF
  
  
  
  # days <- days %>% discard(days %in% trips$day)  # filter by tract 
  # for each tract, create a day entry
  
  # DAILY DEMAND
  # time <- subset(trips, DATE > "2020-01-03" & DATE < "2020-01-10") # filter by time period
  demand <- trips %>% filter(DATE >= "2019-03-20" & DATE <= "2019-10-31") %>% 
    summarize(avgYear=mean(n), stdYear=sd(n), zeroYear = sum(n == 0)) #  whole period
  demand <- demand %>% mutate(
    trips %>% filter(DATE >= "2019-03-20" & DATE <= "2019-06-20") %>% # spring
      summarize(avgSpring=mean(n), stdSpring=sd(n), zeroSpring = sum(n == 0)),
    trips %>% filter(DATE >= "2019-06-21" & DATE <= "2019-09-22") %>% # summer
      summarize(avgSummer=mean(n), stdSummer=sd(n), zeroSummer = sum(n == 0)),
    trips %>% filter(DATE >= "2019-09-23" & DATE <= "2019-10-31") %>% # fall
      summarize(avgFall=mean(n), stdFall=sd(n), zeroFall = sum(n == 0)),
    trips %>% filter(DATE >= "2019-04-01" & DATE <= "2019-04-30") %>% # april
      summarize(avgApril=mean(n), stdApril=sd(n), zeroApril = sum(n == 0)),
    trips %>% filter(DATE >= "2019-05-01" & DATE <= "2019-05-31") %>% # may
      summarize(avgMay=mean(n), stdMay=sd(n), zeroMay = sum(n == 0)),
    trips %>% filter(DATE >= "2019-06-01" & DATE <= "2019-06-30") %>% # june
      summarize(avgJune=mean(n), stdJune=sd(n), zeroJune = sum(n == 0)),
    trips %>% filter(DATE >= "2019-07-01" & DATE <= "2019-07-31") %>% # july
      summarize(avgJuly=mean(n), stdJuly=sd(n), zeroJuly = sum(n == 0)),
    trips %>% filter(DATE >= "2019-08-01" & DATE <= "2019-08-31") %>% # august
      summarize(avgAug=mean(n), stdAug=sd(n), zeroAug = sum(n == 0)),)
  
  demandGeo <- geoData %>% filter(as.logical(match(geoData$TRACT, demand$TRACT)))
  demand <- demand %>% mutate(GEOMETRY = demandGeo$geometry, NAME = demandGeo$NAME) # add geometry data
  demand <- st_as_sf(demand)
  
  time <- trips %>% subset(DATE == "2020-01-07")
  pal <- mapviewPalette("mapviewSpectralColors")
  # print(mv)
  mv <- mapview(demand, zcol = "avgAug", col.regions = pal(20))
  return(mv)
}


