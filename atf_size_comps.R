library(ggplot2)
library(viridis)
library(reshape2)
library(dplyr)
library(here)
library(ggsidekick)
theme_set(theme_sleek())

atf_slope <- read.csv(here("data", "atf_slope_comps.csv"))
colnames(atf_slope)[3:27] <- c("10", "16", "18", "20", "22", "24", "26", "28", 
                               "30", "32", "34", "36", "38", "40", "43", "46", 
                               "49", "52", "55", "58", "61", "64", "67", "70", "75")
atf_slope <- melt(atf_slope, id.vars = c("Year", "Sex"), variable.name = "Bin")

atf_slope_comps <- ggplot(atf_slope, aes(x = Bin, y = value)) +
  geom_bar(stat = "identity") +
  facet_grid(Year ~ Sex)
atf_slope_comps
