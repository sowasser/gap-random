library(here)
library(dplyr)
library(RODBC)
library(ggplot2)
library(gapindex)

# Create directory for output
wd <- here("data", "lorenzo")
dir.create(wd, showWarnings = FALSE, recursive = TRUE)

# Connect to Oracle & ---------------------------------------------------------
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

# CATCH -----------------------------------------------------------------------
catch <- sqlQuery(
  channel, 
  paste0(
    "SELECT A.YEAR, TO_CHAR(B.START_TIME,'DD/MM') DAY_MONTH, 
    TO_CHAR(B.START_TIME,'HH24:MI') TIME24HR, 
    B.REGION, B.VESSEL, B.CRUISE, B.HAUL, B.HAULJOIN, 
    COALESCE(C.SPECIES_CODE,21720) SPECIES_CODE, 
    COALESCE(C.WEIGHT,0) WEIGHT, COALESCE(C.NUMBER_FISH,0) NUMBER_FISH, 
    B.SUBSAMPLE, B.DURATION, B.DISTANCE_FISHED, B.NET_WIDTH, B.STATIONID, 
    B.STRATUM, B.START_LATITUDE, B.END_LATITUDE, B.START_LONGITUDE, 
    B.END_LONGITUDE, B.BOTTOM_DEPTH, B.GEAR_DEPTH, 
    B.SURFACE_TEMPERATURE, B.GEAR_TEMPERATURE
    FROM RACE_DATA.V_CRUISES A
    JOIN RACEBASE.HAUL B
    ON (B.CRUISEJOIN = A.CRUISEJOIN)
    LEFT OUTER JOIN RACEBASE.CATCH C
    ON (C.HAULJOIN = B.HAULJOIN)
    AND C.SPECIES_CODE in (21720, 21740)
    WHERE A.YEAR >= 1982
    AND B.REGION = 'BS'
    AND B.ABUNDANCE_HAUL = 'Y'
    ORDER BY B.CRUISE DESC, B.VESSEL, B.HAUL ASC"
  )
) %>%
  as_tibble()

catch_pcod <- catch %>% filter(SPECIES_CODE == 21720) 
catch_pollock <- catch %>% filter(SPECIES_CODE == 21740)

write.csv(catch_pcod, here(wd, "catch_pcod.csv"), row.names = FALSE)
write.csv(catch_pollock, here(wd, "catch_pollock.csv"), row.names = FALSE)

# LENGTH ----------------------------------------------------------------------
length <- sqlQuery(
  channel, 
  paste0(
    "SELECT A.YEAR, 
    B.VESSEL, B.REGION, B.HAUL, B.HAULJOIN, B.STRATUM, B.STATIONID, 
    C.SPECIES_CODE, C.LENGTH, C.SEX, C.FREQUENCY,
    B.START_LONGITUDE LON, B.START_LATITUDE LAT
    FROM RACE_DATA.V_CRUISES A
    JOIN RACEBASE.HAUL B
    ON (B.CRUISEJOIN = A.CRUISEJOIN)
    JOIN RACEBASE.LENGTH C
    ON (C.HAULJOIN = B.HAULJOIN)
    WHERE A.YEAR >= 1982
    AND B.REGION = 'BS'
    AND B.ABUNDANCE_HAUL = 'Y'
    AND C.SPECIES_CODE in (21720, 21740)
    ORDER BY A.YEAR desc, B.VESSEL, B.HAUL ASC"
  )
) %>%
  as_tibble()

length_pcod <- length %>% filter(SPECIES_CODE == 21720) 
length_pollock <- length %>% filter(SPECIES_CODE == 21740)

write.csv(length_pcod, here(wd, "length_pcod.csv"), row.names = FALSE)
write.csv(length_pollock, here(wd, "length_pollock.csv"), row.names = FALSE)
