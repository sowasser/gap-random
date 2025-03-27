# Accessing the Food Habits database

library(RODBC)
library(here)
library(dplyr)

if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  source("Z:/Projects/ConnectToOracle.R")
} else {
  # For those without a ConnectToOracle file
  channel <- get_connected()
}

# check to see if connection has been established
odbcGetInfo(channel_products)

con <- channel_products  # rename channel for ease

path <- here("diet", "tables")  # set file path for saving data

# Get Food Lab tables, either from Oracle or read them in from local drive
get_data <- function(new_tables) {
  if(new_tables == TRUE) {
    nodc <- sqlQuery(con, "select * from foodlab.nodc")  # taxonomic info
    preylength <- sqlQuery(con, "select * from foodlab.preylen")  # prey length
    fl_haul <- sqlQuery(con, "select * from foodlab.haul")  # foodhabits haul info
    predprey <- sqlQuery(con, "select * from foodlab.predprey")  # predator info
    
    # Write tables to .csv
    write.csv(nodc, here(path, "foodlab_nodc.csv"), row.names = FALSE)
    write.csv(preylength, here(path, "foodlab_preylength.csv"), row.names = FALSE)
    write.csv(fl_haul, here(path, "foodlab_haul.csv"), row.names = FALSE)
    write.csv(predprey, here(path, "foodlab_predprey.csv"), row.names = FALSE)
  }
  
  if(new_tables == FALSE) {
    nodc <- read.csv(here(path, "foodlab_nodc.csv"))
    preylength <- read.csv(here(path, "foodlab_preylength.csv"))
    fl_haul <- read.csv(here(path, "foodlab_haul.csv"))
    predprey <- read.csv(here(path, "foodlab_predprey.csv"))
  }
  
  return(list(nodc = nodc, 
              preylength = preylength,
              fl_haul = fl_haul,
              predprey = predprey))
}

tables <- get_data(new_tables = FALSE)
nodc <- tables$nodc
preylength <- tables$preylength
fl_haul <- tables$fl_haul
predprey <- tables$predprey


# Hake stuff ------------------------------------------------------------------
# Get pacific hake taxonomic ID
hake_nodc <- nodc[grep("hake", nodc$NAME), "NODC"]

# Find records of hake-as-prey
hake_preylength <- preylength %>% filter(PREY_NODC == hake_nodc)
hake_predprey <- predprey %>% filter(PREY_NODC == hake_nodc)

# Find hake predator species 
pred_nodc <- nodc %>% filter(NODC %in% unique(hake_predprey$PRED_NODC))


# Get racebase tables ---------------------------------------------------------
race_catch <- sqlQuery(con, "select * from racebase.catch") #Takes several minutes to download 
race_length <- sqlQuery(con, "select * from racebase.length") #Takes several minutes to download 
race_haul <- sqlQuery(con, "select * from racebase.haul") #Takes several minutes to download 
race_specimen <- sqlQuery(con, "select * from racebase.specimen") #Takes several minutes to download 
race_stratum <- sqlQuery(con, "select * from racebase.stratum") #Takes several minutes to download 
race_stations <- sqlQuery(con, "select * from racebase.stations") #Takes several minutes to download 
race_species_classification <- sqlQuery(con, "select * from racebase.species_classification") #Takes several minutes to download 
race_cruise <- sqlQuery(con, "select * from racebase.cruise") #Takes several minutes to download 
