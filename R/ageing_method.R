# Ageing method codes from RACEBASE

library(RODBC)
library(tibble)
library(janitor)
library(dplyr)
library(ggplot2)
library(ggsidekick)
theme_set(theme_sleek())

# Connect to Oracle
if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  source("Z:/Projects/ConnectToOracle.R")
} else {
  channel <- gapindex::get_connected(check_access = FALSE)
}

# Construct simple query of specimen data for pollock, yfs, and p. cod
species_list <- c(21740, 10210, 21720)
query_command <- paste0(
  "select a.REGION, a.CRUISE, a.HAUL,",
  " a.SPECIES_CODE, round(a.LENGTH/10)*10 length, a.SEX, a.WEIGHT,",
  " a.AGE, a.AGE_DETERMINATION_METHOD",
  " from racebase.specimen a",
  " where a.species_code in (", paste(species_list, collapse = ","), ")",
  " and a.region = 'BS'",
  " order by cruise, vessel, haul;"
)

specimen_orig <- sqlQuery(channel, query_command) %>% 
  as_tibble() %>% 
  clean_names() 

# See which species are using FTNIR (age determination method code 12)
specimen_orig %>%
  filter(age_determination_method == "12") %>%
  group_by(species_code) %>%
  summarise(n = n())

# Annual numbers of specimens aged with FTNIR
pollock_ages <- specimen_orig %>%
  filter(species_code == 21740) %>%
  group_by(cruise, age_determination_method) %>%
  summarise(n = n()) %>%
  filter(age_determination_method != "NA") %>%
  mutate(year = cruise %/% 100) %>%
  ungroup() %>%
  mutate(age_determination_method = case_when(
    age_determination_method == "12" ~ "FTNIR",
    TRUE ~ "Other"
  )) %>%
  group_by(year, age_determination_method) %>%
  summarise(n = sum(n)) %>%
  ungroup() 

ggplot(pollock_ages, aes(x = year, y = n, fill = age_determination_method)) +
  geom_col() +
  labs(x = "Year", y = "Number of specimens aged", fill = "Ageing method") 
