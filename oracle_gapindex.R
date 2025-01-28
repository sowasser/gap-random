# Oracle testing for ongoing gapindex issue:
# https://github.com/afsc-gap-products/gapindex/issues/63

devtools::install_github("afsc-gap-products/gapindex")

channel <- gapindex::get_connected(check_access = F)

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

RODBC::sqlQuery(channel = channel_products, query = "select * from USER_TS_QUOTAS;" )

gapindex_data_ebs <- gapindex::get_data(
  year_set = c(1982:2024),
  survey_set = "EBS",
  spp_codes = 21740,
  haul_type = 3,
  abundance_haul = "Y",
  pull_lengths = TRUE,
  channel = channel_products
)

# gapindex vignette
gapindex_data <- gapindex::get_data(
  year_set = c(2007, 2009),
  survey_set = "GOA",
  spp_codes = 10261,   
  haul_type = 3,
  abundance_haul = "Y",
  pull_lengths = T,
  channel = channel)

