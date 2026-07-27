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
                            a.STATIONID, a.START_LATITUDE, a. START_LONGITUDE, a.GEAR_DEPTH, 
                            a.BOTTOM_DEPTH, a.GEAR_TEMPERATURE, a.HAULJOIN,
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
  left_join(hauls, by = c("hauljoin", "year", "start_latitude", "start_longitude")) %>%
  select(Lat = start_latitude, 
         Lon = start_longitude,
         Year = year,
         start_time,
         gear_temperature,
         Abundance = ddc_cpue_kg_ha)  %>%
  mutate(CPUE_kg_km2 = Abundance * 100)  # convert from kg/ha to kg/km2

write.csv(biomass, here(wd, "pollock_biomass.csv"), row.names = FALSE)

# Read in density-dependent corrected pollock age comps & combine with haul info
ddc_ages <- read.csv(here("data", "ddc", paste0("VAST_ddc_alk_", year, ".csv")))  # density dependence corrected

numbers <- ddc_ages %>%
  left_join(hauls,
            by = c("Lat" = "start_latitude", "Lon" = "start_longitude", "Year" = "year")) %>%
  select(Lat,
         Lon,
         Year,
         start_time,
         gear_temperature,
         Age,
         CPUE_num) %>%
  mutate(CPUE_num_km2 = CPUE_num * 100)

write.csv(numbers, here(wd, "pollock_numbers.csv"), row.names = FALSE)

# Plot data to double check ---------------------------------------------------
library(ggsidekick)
theme_set(theme_sleek())

world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
sf::sf_use_s2(FALSE)  # turn off spherical geometry

ggplot(data = world) +
  geom_sf() +
  geom_point(data = biomass %>% filter(Abundance > 0), 
             aes(x = Lon, y = Lat, color = Abundance, fill = Abundance)) +
  coord_sf(xlim = c(-179, -157), ylim = c(53.8, 65), expand = FALSE) +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.position = "none") +
  labs(x = NULL, y = NULL) +
  facet_wrap(~ Year)

ggplot(data = world) +
  geom_sf() +
  geom_point(data = numbers %>% filter(CPUE_num > 0), 
             aes(x = Lon, y = Lat, color = CPUE_num, fill = CPUE_num)) +
  coord_sf(xlim = c(-179, -157), ylim = c(53.8, 65), expand = FALSE) +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.position = "none") +
  labs(x = NULL, y = NULL) +
  facet_wrap(~ Year)
