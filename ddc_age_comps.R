#' Starting to look at calculating age compositions from the density dependent
#' corrected length compositions produced for EBS pollock, as the standard
#' gapindex comps do not include this correction to CPUE calculations.

library(here)

# Read in DDC code output
lcomps <- read.csv(here("data", "ddc", "length_comps_densdep_corrected_2024.csv"))
alk <- read.csv(here("data", "ddc", "age_length_key_full_densdep_corrected_2024.csv"))
