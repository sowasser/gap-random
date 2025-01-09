#' Plots of the center of gravity for Bering sea walleye pollock, with the 
#' extent of the cold pool.

library(here)
library(ggplot2)
library(dplyr)
library(reshape2)
library(viridis)
library(sf)
library(rnaturalearth)
library(cowplot)
library(janitor)

library(akgfmaps)
library(coldpool)

library(ggsidekick)
theme_set(theme_sleek())

this_year <- 2024
VAST_results <- readRDS(here("COG", "VASTresults.RDS"))  # for COG 
saveDir <- here("COG")

# Get EBS bottom temperature
# coldpool:::ebs_bottom_temperature
# ebs_bt <- terra::unwrap(coldpool:::ebs_bottom_temperature)

cold_pool <- coldpool:::cold_pool_index %>%
  as_tibble() %>%
  clean_names 

cp_plot <- ggplot(cold_pool, aes(x = year, y = area_lte2_km2)) +
  geom_line() +
  ylab(expression("Cold Pool Extent (" ~ km^2 ~ ")")) + xlab("Year")
cp_plot
ggsave(cp_plot, filename = here("COG", "cp_extent.png"), 
       width = 150, height = 90, unit = "mm", dpi = 300)

cold_pool <- cold_pool %>% 
  select(-year, -last_update) %>%
  scale(center = TRUE, scale = TRUE) %>%
  as_tibble()

cog <- function(results = VAST_results, dir = saveDir, save_data = FALSE, save_plots = TRUE) {
  # ---------------------------------------------------------------------------
  cog <- data.frame(results$Range$COG_Table)
  cog$Year <- as.numeric(cog$Year)
  cog$COG_hat <- as.numeric(cog$COG_hat)
  cog$SE <- as.numeric(cog$SE)
  
  cog$m[cog$m == 1] <- "Easting (km)"
  cog$m[cog$m == 2] <- "Northing (km)"
  
  # Original plot - UTM 
  ts <- ggplot(cog %>% filter(Year != 2020), aes(x = Year, y = COG_hat)) +
    geom_line() +
    geom_ribbon(aes(ymin = (COG_hat - SE), ymax = (COG_hat + SE)), alpha = 0.2) +
    xlab("") + ylab("") +
    facet_wrap(~ m, ncol = 1, scales = "free_y") +
    theme(plot.background = element_rect(fill = "transparent"))
  
  # Convert to lat/long using akgfmaps package and plot
  cog_east <- cog %>% filter(m == "Easting (km)" & Year != 2020)
  cog_east <- cog_east[, 2:4]  # get rid of ID column and not sure what to do with SE!
  colnames(cog_east)[2] <- "Easting (km)"
  
  cog_north <- cog %>% filter(m == "Northing (km)" & Year != 2020)
  cog_north <- cog_north[, 2:4]
  colnames(cog_north)[2] <- "Northing (km)"
  
  cog_latlon <- cbind.data.frame(X = cog_east[, 2], Y = cog_north[, 2])
  # CRS information for VAST outputs here: 
  # https://github.com/James-Thorson-NOAA/FishStatsUtils/blob/main/R/project_coordinates.R
  cog_latlon <- transform_data_frame_crs(cog_latlon, 
                                         coords = c("X", "Y"), 
                                         in.crs = "+proj=utm +datum=WGS84 +units=km +zone=2",
                                         out.crs = "+proj=longlat +datum=WGS84")
  cog_latlon$Year <- cog_east$Year
  
  # Include error in COG estimate before transformation to get min & max values
  cog_min <- cbind.data.frame(X = cog_east[, 2] - cog_east[, 3], 
                              Y = cog_north[, 2] - cog_north[, 3])
  cog_min <- transform_data_frame_crs(cog_min, 
                                      coords = c("X", "Y"), 
                                      in.crs = "+proj=utm +datum=WGS84 +units=km +zone=2",
                                      out.crs = "+proj=longlat +datum=WGS84")
  
  cog_max <- cbind.data.frame(X = cog_east[, 2] + cog_east[, 3], 
                              Y = cog_north[, 2] + cog_north[, 3])
  cog_max <- transform_data_frame_crs(cog_max, 
                                      coords = c("X", "Y"), 
                                      in.crs = "+proj=utm +datum=WGS84 +units=km +zone=2",
                                      out.crs = "+proj=longlat +datum=WGS84")
  cog_error <- cbind.data.frame(cog_latlon, 
                                xmin = cog_min$X, xmax = cog_max$X,
                                ymin = cog_min$Y, ymax = cog_max$Y)
  
  # Plot on a map
  world <- ne_countries(scale = "medium", returnclass = "sf")
  sf_use_s2(FALSE)  # turn off spherical geometry
  map <- ggplot(data = world) +
    geom_sf() +
    geom_point(data = cog_latlon,
               aes(x = X, y = Y, color = Year), size = 1) +
    # geom_errorbar(data = cog_error,
    #               aes(x = X, y = Y, ymin = ymin,ymax = ymax, color = Year), alpha = 0.8) +
    # geom_errorbarh(data = cog_error,
    #                aes(x = X, y = Y, xmin = xmin,xmax = xmax, color = Year), alpha = 0.8) +
    coord_sf(xlim = c(-179, -157), ylim = c(54, 65), expand = FALSE) +
    scale_color_viridis(option = "plasma", discrete = FALSE, end = 0.9) +
    scale_x_continuous(breaks = c(-178, -158)) +
    scale_y_continuous(breaks = c(55, 64)) +
    labs(x = NULL, y = NULL) +
    theme(plot.background = element_rect(fill = "transparent"))
  
  cog_error2 <- cog_error[-1, c(1:2)]
  cog_error2[nrow(cog_error2) + 1, ] <- NA
  colnames(cog_error2) <- c("X2", "Y2")
  cog_error2 <- cbind.data.frame(cog_error, cog_error2) 
  
  # Plot as scatter (sparkleplot) ---------------------------------------------
  # Add columns for the cold pool extent and the sign for plotting
  cog_error$cp <- cold_pool$area_lte2_km2
  cog_error <- cog_error %>%
    mutate(cp_sign = case_when(cp > 0 ~ "Above",
                               cp < 0 ~ "Below"))
  
  sparkle <- ggplot(data = cog_error, aes(x = X, y = Y, color = Year)) +
    geom_point(aes(shape = cp_sign, size = abs(cp)), alpha = 0.7) +
    scale_shape_manual(values = c("+", "_")) +
    scale_size(name = "Difference", range = c(5, 15)) +
    guides(shape = guide_legend(override.aes = list(size = 8), order = 1), 
           size = guide_legend(override.aes = list(size = seq(from = 3, to = 6, length.out = 4)),
                               order = 2)) +
    # With arrow
    # geom_segment(data = cog_error2 %>% filter(Year >= this_year - 10), 
    #              aes(x = X, y = Y, xend = X2, yend = Y2), 
    #              alpha = 0.8, arrow = arrow(length = unit(0.03, "npc"))) +
    # Without arrow
    # geom_segment(data = cog_error2 %>% filter(Year >= this_year - 10), 
    #              aes(x = X, y = Y, xend = X2, yend = Y2), 
    #              alpha = 0.8) +
    geom_errorbar(aes(ymin = ymin, ymax = ymax, color = Year), alpha = 0.4) +
    geom_errorbarh(aes(xmin = xmin, xmax = xmax, color = Year), alpha = 0.4) +
    scale_color_viridis(option = "plasma", discrete = FALSE, end = 0.9) +
    xlab("Longitude (°W)") + ylab("Latitude (°N)") + labs(shape = "Cold Pool Extent") +
    theme(plot.background = element_rect(fill = "transparent"))
  
  # Inset map into sparkleplot -----------------------------------------
  inset <- ggdraw() +
    draw_plot(plot = sparkle) +
    draw_plot(plot = map +
                theme(legend.position = "none") +
                guides(x = "none", y = "none"), 
              x = 0.81, y = 0.75, width = 0.21, height = 0.21) 
  
  # Combine sparkleplot and time-series plot
  all <- plot_grid(inset, ts)
  all
  
  # Another inset for using independently
  inset2 <- ggdraw() +
    draw_plot(plot = sparkle) +
    draw_plot(plot = map +
                theme(legend.position = "none") +
                guides(x = "none", y = "none"), 
              x = 0.60, y = 0.76, width = 0.21, height = 0.21) 
  
  if(save_data == TRUE) {
    # Save COG as UTM (easting/northing)
    write.csv(cog, file = here(dir, "COG_utm.csv"), row.names = FALSE)
    
    # Save COG as lat/long (without error)
    cog_latlon <- cog_latlon[, c(3, 2, 1)]
    colnames(cog_latlon) <- c("Year", "Latitude", "Longitude")
    write.csv(cog_latlon, file = here(dir, "COG_latlong.csv"), row.names = FALSE)
  }
  
  if(save_plots == TRUE) {
    # ggsave(ts, filename = here(dir, "COG_utm.png"),
    #        width = 150, height = 180, unit = "mm", dpi = 300, bg = "white")
    ggsave(map, filename = here(dir, "COG_map.png"),
           width = 110, height = 90, unit = "mm", dpi = 300,  bg = "white")
    ggsave(sparkle, filename = here(dir, "COG_sparkle.png"),
           width = 150, height = 100, unit = "mm", dpi = 300,  bg = "white")
    # ggsave(all, filename = here(dir, "COG_all.png"),
    #        width = 250, height = 100, unit = "mm", dpi = 300,  bg = "white")
    # ggsave(inset2, filename = here(dir, "COG_inset.png"),
    #        width = 130, height = 100, unit = "mm", dpi = 300,  bg = "white")
  }
  
  return(list(table = cog_latlon, table_error = cog_error, 
              ts = ts, map = map, sparkle = sparkle, all = all, inset = inset2))
}

cog_plots <- cog()
# Map insert may look funny here because of the dimensions of the Rstudio plotting window. Check saved plot!
# cog_plots$all
cog_plots$sparkle
