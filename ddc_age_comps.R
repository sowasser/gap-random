#' Starting to look at calculating age compositions from the density dependent
#' corrected length compositions produced for EBS pollock, as the standard
#' gapindex comps do not include this correction to CPUE calculations.

library(here)
library(dplyr)
library(ggplot2)

# Read in DDC code output
length_comps <- read.csv(here("data", "ddc", "length_comps_densdep_corrected_2024.csv"))
specimen <- read.csv(here("data", "ddc", "raw_data_pollock_specimen_2024-10-15.csv")) 

# Set up ALK with specimen data -----------------------------------------------
# Subset the specimen dataframe for easier manipulation
spec <- specimen %>% 
  select(year, stratum, length, age) %>%
  filter(complete.cases(.))  # remove NAs in any column

# Plot lengths to see distribution
ggplot(spec, aes(x = length)) +
  geom_histogram(binwidth = 10) +
  theme_bw()

# Calculate age bins
lbins <- cut(spec$length, 
             breaks = seq(min(spec$length), max(spec$length), by = 10), 
             right = FALSE)

# Create new ALK
alk_counts <- data.frame(spec, lbins) %>%
  group_by(year, stratum, lbins, age) %>%
  summarise(count = n())

alk_totals <- alk_counts %>%
  group_by(year, stratum, lbins) %>%
  summarize(total_fish = sum(count))

new_alk <- alk_counts %>%
  left_join(alk_totals, by = c("year", "stratum", "lbins")) %>%
  group_by(year, stratum) %>%
  mutate(prob = count / total_fish) %>%
  select(year, stratum, lbins, age, prob)

# Apply ALK to length comps ---------------------------------------------------
# Subset the length comp dataframe for easier manipulation
lcomps <- length_comps %>%
  group_by(year, stratum, length) %>%
  summarize(count = n())
