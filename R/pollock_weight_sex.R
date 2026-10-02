# Weight-at-age by sex for Bering Sea pollock

library(here)
library(dplyr)
library(ggplot2)
library(viridis)
library(ggsidekick)
theme_set(theme_sleek())

specimen_raw <- read.csv(here("data", "raw_data_pollock_specimen_2024-10-15.csv")) 

specimen <- specimen_raw %>%
  filter(!is.na(weight)) %>%
  filter(age %in% 1:15) %>%
  filter(sex %in% 1:2) %>%
  mutate(sex = factor(sex, labels = c("male", "female"))) %>%
  group_by(age, sex) %>%
  mutate(median_weight = mean(weight)) 
  
ggplot(specimen, aes(x = weight, color = sex, fill = sex)) +
  geom_histogram(alpha = 0.5) +
  geom_vline(aes(xintercept = mean_weight, color = sex, linetype = sex),
             linewidth = 1) +
  scale_fill_viridis(discrete = TRUE, begin = 0.3, end = 0.7) +
  scale_color_viridis(discrete = TRUE, begin = 0.3, end = 0.7) +
  xlab("Weight") + ylab("Frequency") +
  facet_wrap(~ age, ncol = 2, scales = "free_y")
