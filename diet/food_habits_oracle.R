# Accessing the Food Habits database

library(RODBC)
library(here)

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

# Download Food Habits oracle tables 
nodc <- sqlQuery(con, "select * from foodlab.nodc")
preylength <- sqlQuery(con, "select * from foodlab.preylen")
fl_haul <- sqlQuery(con, "select * from foodlab.haul")
predprey <- sqlQuery(con, "select * from foodlab.predprey")

# Write tables to .csv
write.csv(nodc, here(path, "foodlab_nodc.csv"), row.names = FALSE)
write.csv(preylength, here(path, "foodlab_preylength.csv"), row.names = FALSE)
write.csv(fl_haul, here(path, "foodlab_haul.csv"), row.names = FALSE)
write.csv(predprey, here(path, "foodlab_predprey.csv"), row.names = FALSE)


# Get racebase tables
race_catch <- sqlQuery(con, "select * from racebase.catch") #Takes several minutes to download 
race_length <- sqlQuery(con, "select * from racebase.length") #Takes several minutes to download 
race_haul <- sqlQuery(con, "select * from racebase.haul") #Takes several minutes to download 
race_specimen <- sqlQuery(con, "select * from racebase.specimen") #Takes several minutes to download 
race_stratum <- sqlQuery(con, "select * from racebase.stratum") #Takes several minutes to download 
race_stations <- sqlQuery(con, "select * from racebase.stations") #Takes several minutes to download 
race_species_classification <- sqlQuery(con, "select * from racebase.species_classification") #Takes several minutes to download 
race_cruise <- sqlQuery(con, "select * from racebase.cruise") #Takes several minutes to download 
