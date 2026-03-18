# Simple plot of the survey and strata
library(sf)
library(akgfmaps)
library(rnaturalearth)
library(ggsidekick)
library(viridis)
library(here)

# Get layers from akgfmaps 
grid <- get_base_layers(select.region = "bs.all", 
                        design.year = 2026)

# Simplify survey names for the plot
grid$survey.area$SURVEY_NAME <- c("EBS", "NBS")  

# Choose labels to add to plot & move the St. Matt's point for cleaner plotting
labels <- grid$place.labels[c(1, 3), ] 
labels[labels$lab == "St. Matthew", ]$x <- -172
labels[labels$lab == "St. Matthew", ]$y <- 60

# Get land area and crop for faster plotting
bs_sf <- st_crop(rnaturalearth::ne_countries(scale = "medium", returnclass = "sf"), 
                 xmin = -179, xmax = -150, ymin = 52, ymax = 68)

# Get full extent of the survey area for smart plot boundaries
bbox <- st_bbox(grid$survey.area)

ggplot() +
  geom_sf(data = grid$survey.grid, color = c("gray85"), fill = "NA") +
  geom_sf(data = grid$survey.strata, aes(color = STRATUM), 
          fill = "NA", linewidth = 0.7) +
  geom_sf(data = grid$survey.area, aes(linetype = SURVEY_NAME), 
          fill = "NA", linewidth = 1, color = "gray40") +
  geom_sf(data = bs_sf) +
  # geom_sf_text(data = grid$survey.strata, aes(label = STRATUM, color = STRATUM)) +
  geom_text(data = labels, aes(label = lab, x = x, y = y), color = "gray40") +
  coord_sf(xlim = c(bbox["xmin"], bbox["xmax"]), 
           ylim = c(bbox["ymin"], bbox["ymax"]), expand = TRUE) +
  scale_color_viridis(option = "turbo", begin = 0.1) +
  xlab("") + ylab("") + labs(linetype = "Survey") +
  guides(color = "none") +
  theme_sleek()

ggsave(filename = here("plots", "survey_map.png"), 
       width = 6, height = 5, units = "in", dpi = 300)
