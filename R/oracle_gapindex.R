# Oracle testing for ongoing gapindex issue:
# https://github.com/afsc-gap-products/gapindex/issues/63

# devtools::install_github("afsc-gap-products/gapindex")
library(RODBC)
library(gapindex)
library(dplyr)
# channel <- gapindex::get_connected(check_access = F)

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

## Pull data.
gapindex_data <- gapindex::get_data(
  year_set = c(2023, 2025),
  survey_set = "GOA",
  spp_codes = 10180,   
  haul_type = 3,
  abundance_haul = "Y",
  pull_lengths = F,
  channel = channel)

## Fill in zeros and calculate CPUE
cpue <- gapindex::calc_cpue(gapdata = gapindex_data)

## Calculate stratum-level biomass, population abundance, mean CPUE and 
## associated variances
biomass_stratum <- gapindex::calc_biomass_stratum(
  gapdata = gapindex_data,
  cpue = cpue)

## Calculate aggregated biomass and population abundance across subareas,
## management areas, and regions
biomass_subareas <- gapindex::calc_biomass_subarea(
  gapdata = gapindex_data,
  biomass_stratum = biomass_stratum)

total <- biomass_subareas %>%
  filter(AREA_ID == 99903) %>%
  select(YEAR, BIOMASS_MT)



# RODBC::sqlQuery(channel = channel_products, query = "select * from USER_TS_QUOTAS;" )

# gapindex_data_ebs <- gapindex::get_data(
#   year_set = c(1982:2024),
#   survey_set = "EBS",
#   spp_codes = 21740,
#   haul_type = 3,
#   abundance_haul = "Y",
#   pull_lengths = TRUE,
#   channel = channel_products
# )
# 
# # gapindex vignette
# gapindex_data <- gapindex::get_data(
#   year_set = c(2007, 2009),
#   survey_set = "GOA",
#   spp_codes = 10261,   
#   haul_type = 3,
#   abundance_haul = "Y",
#   pull_lengths = T,
#   channel = channel)

