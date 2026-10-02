library(here)
library(dplyr)
library(ggplot2)
library(viridis)
library(cowplot)

# Set ggplot theme
if (!requireNamespace("ggsidekick", quietly = TRUE)) {
  devtools::install_github("seananderson/ggsidekick")
}
library(ggsidekick)
theme_set(theme_sleek())

ebs <- read.csv("~/GAP/Pollock/pollock-ddc/output/2024_mb_data_2022_strata/VAST_ddc_EBSonly_2024.csv") %>%
  group_by(year) %>%
  summarize(hauls = n()) %>%
  mutate(region = "EBS") %>%
  ggplot(., aes(x = year, y = region, color = hauls)) +
  geom_point(size = 2) +
  xlab("") + ylab("") + 
  scale_color_viridis(option = "plasma")

nbs <- read.csv("~/GAP/Pollock/pollock-ddc/output/2024_mb_data_2022_strata/VAST_ddc_NBSonly_2024.csv") %>%
  group_by(year) %>%
  summarize(hauls = n()) %>%
  filter(hauls > 1) %>%
  add_row(year = 2024, hauls = 0) %>%
  mutate(region = "NBS")

nbs_plot <- ggplot() +
  geom_point(data = nbs, aes(x = year, y = region, color = hauls), size = 2) +
  geom_point(data = filter(nbs, year == 2024), aes(x = year, y = region), color = "white", size = 2.1) +
  xlab("") + ylab("") + 
  scale_color_viridis(option = "plasma")

both <- plot_grid(ebs, nbs_plot, ncol = 1)
both

ggsave(both, filename = here("plots", "region_hauls.png"),
       width = 130, height = 80, units = "mm", dpi = 300)
