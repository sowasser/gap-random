# Pollock biomass and abundance from the bottom-trawl survey for Sabrina

library(here)
library(dplyr)
library(RODBC)
library(ggplot2)
library(gapindex)

# Create directory for output
wd <- here("data", "sabrina")
dir.create(wd, showWarnings = FALSE, recursive = TRUE)

year <- Sys.Date() %>% format("%Y") %>% as.numeric() 

# Connect to Oracle & pull haul information -----------------------------------
if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  source("Z:/Projects/ConnectToOracle.R")
} else {
  # For those without a ConnectToOracle file
  channel <- odbcConnect(dsn = "AFSC", 
                         uid = rstudioapi::showPrompt(title = "Username", 
                                                      message = "Oracle Username", 
                                                      default = ""), 
                         pwd = rstudioapi::askForPassword("Enter Password"),
                         believeNRows = FALSE)
}

odbcGetInfo(channel)  # check connection

# Get haul info
query_command <- paste0("select a.REGION, a.CRUISE, a.START_TIME, a.HAUL_TYPE, a.PERFORMANCE, 
                            a.STATIONID, a.GEAR_DEPTH, a.BOTTOM_DEPTH, a.GEAR_TEMPERATURE, a.HAULJOIN,
                            floor(a.CRUISE/100) year
                            from racebase.haul a
                            where a.PERFORMANCE >=0 and a.HAUL_TYPE = 3 and a.REGION = 'BS'
                            order by a.CRUISE;")

hauls <- sqlQuery(channel, query_command) %>%
  as_tibble() %>%
  janitor::clean_names() %>%
  filter(year %in% 1982:as.numeric(format(Sys.Date(), "%Y")))  # standard years

# Read in density-dependent corrected pollock biomass & combine with haul info 
ddc_cpue <- read.csv(here("data", "ddc", paste0("VAST_ddc_all_", year, ".csv")))  # density dependence corrected

biomass <- ddc_cpue %>%
  left_join(hauls, by = "hauljoin") %>%
  select(Lat = start_latitude, 
         Lon = start_longitude,
         Year = year.x,
         start_time = start_time,
         gear_temperature = gear_temperature,
         Abundance = ddc_cpue_kg_ha)  %>%
  mutate(CPUE_kg_km2 = Abundance * 100)  # convert from kg/ha to kg/km2

write.csv(biomass, here(wd, "pollock_biomass.csv"), row.names = FALSE)

# Read in density-dependent corrected pollock age comps & combine with haul info
ddc_ages <- read.csv(here("data", "ddc", paste0("VAST_ddc_alk_", year, ".csv")))  # density dependence corrected

numbers <- ddc_ages %>%
  left_join(hauls, by = "hauljoin") %>%
  select(Lat = start_latitude, 
         Lon = start_longitude,
         Year = year.x,
         start_time = start_time,
         gear_temperature = gear_temperature,
         Age = age,
         Abundance = ddc_ages_numbers_ha) %>%
  mutate(CPUE_num_km2 = Abundance * 100)  # convert from numbers/ha to numbers/km2

