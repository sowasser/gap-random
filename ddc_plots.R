# Comparison of 2022 density-dependent correction to pollock survey data with
# and without NBS data from 2018 included in the calculation.

library(here)
library(dplyr)
library(sf)
library(rnaturalearth)
library(ggplot2)
library(viridis)
library(ggsidekick)
theme_set(theme_sleek())

world <- ne_countries(scale = "medium", returnclass = "sf")
sf_use_s2(FALSE)  # turn off spherical geometry


### Plot raw pollock data -----------------------------------------------------
pollock_specimen <- readRDS(here("DDC comparison", "pollock_specimen_2023.rds"))

specimen_map <- ggplot(data = world) +
  geom_sf() +
  geom_point(data = pollock_specimen,
             aes(x = start_longitude, y = start_latitude), 
             color = "slateblue", size = 0.5, alpha = 0.3) +
  coord_sf(xlim = c(-179, -157), ylim = c(54, 66), expand = FALSE) +
  theme(axis.text.x=element_blank(), axis.ticks.x=element_blank(),
        axis.text.y=element_blank(), axis.ticks.y=element_blank()) +
  facet_wrap(~ year)

ggsave(specimen_map, filename = here("plots", "specimen_map.png"), 
       width = 200, height = 200, units = "mm", dpi = 300)
  

### Calculate difference between two datasets ---------------------------------
# Read in DDC code results
ddc2023 <- read.csv(here("DDC comparison", "ddc_2023", "VAST_ddc_all_2023.csv"))
ddc2022_Lukas <- read.csv(here("DDC comparison", "ddc_2022_Lukas", "VAST_ddc_all_2022.csv"))

# Plot 2018 data
ggplot(data = world) +
  geom_sf() +
  geom_point(data = ddc2023 %>% filter(year == 2018),
             aes(x = start_longitude, y = start_latitude, 
                 size = ddc_cpue_kg_ha, color = ddc_cpue_kg_ha, alpha = ddc_cpue_kg_ha)) +
  coord_sf(xlim = c(-179, -157), ylim = c(54, 66), expand = FALSE) +
  scale_color_viridis(option = "mako", discrete = FALSE, direction = -1, end = 0.9) +
  xlab(" ") + ylab(" ")

# Plot 2023 data
ddc2023_map <- ggplot(data = world) +
  geom_sf() +
  geom_point(data = ddc2023 %>% filter(year == 2023),
             aes(x = start_longitude, y = start_latitude, 
                 size = ddc_cpue_kg_ha, color = ddc_cpue_kg_ha, alpha = ddc_cpue_kg_ha)) +
  coord_sf(xlim = c(-179, -157), ylim = c(54, 66), expand = FALSE) +
  scale_color_viridis(option = "mako", discrete = FALSE, direction = -1, end = 0.9) +
  xlab(" ") + ylab(" ")
ddc2023_map

ggsave(ddc2023_map, filename = here("plots", "ddc_2023.png"), 
       width = 200, height = 200, units = "mm", dpi = 300)


# Plot difference between them 
ddc_diff <- ddc2023 %>% filter(year < 2023)
ddc_diff$difference <- ((ddc_diff$ddc_cpue_kg_ha - ddc2022_Lukas$ddc_cpue_kg_ha) / ddc2022_Lukas$ddc_cpue_kg_ha) * 100
is.na(ddc_diff$difference) <- 0

limit <- max(abs(ddc_diff$difference)) * c(-1, 1)
diff_plot <- ggplot(data = world) +
  geom_sf() +
  geom_point(data = ddc2022_NBS18,
             aes(x = start_longitude, y = start_latitude, 
                 size = abs(difference), color = difference, alpha = abs(difference))) +
  coord_sf(xlim = c(-179, -157), ylim = c(54, 66), expand = FALSE) +
  scale_color_gradientn(colors = pals::brewer.prgn(100), limit = limit) +
  theme(axis.text.x=element_blank(), axis.ticks.x=element_blank(),
        axis.text.y=element_blank(), axis.ticks.y=element_blank()) +
  xlab(" ") + ylab(" ") + labs(color = "% difference",
                               size = "% difference",
                               alpha = "% difference") +
  facet_wrap(~ year)
diff_plot

ggsave(diff_plot, filename = here("plots", "ddc_difference_2023.png"), 
       width = 200, height = 200, units = "mm", dpi = 300)

