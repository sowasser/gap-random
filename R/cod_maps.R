library(gapindex)
library(here)
library(dplyr)
library(purrr)
library(RODBC)
library(ggplot2)
library(sf)
library(rnaturalearth)
library(classInt)
library(akgfmaps)
library(stars)
library(viridis)


if (!requireNamespace("ggsidekick", quietly = TRUE)) {
  pak::pkg_install("seananderson/ggsidekick")
}
library(ggsidekick)
theme_set(theme_sleek())

# Create directory for output
wd <- here("data", "cod maps")
dir.create(wd, showWarnings = FALSE, recursive = TRUE)

# Connect to Oracle & ---------------------------------------------------------
if (file.exists("Z:/Projects/ConnectToOracle.R")) {
  source("Z:/Projects/ConnectToOracle.R")
} else {
  # For those without a ConnectToOracle file
  channel <- odbcConnect(
    dsn = "AFSC", 
    uid = rstudioapi::showPrompt(
      title = "Username", 
      message = "Oracle Username", 
      default = ""
    ), 
    pwd = rstudioapi::askForPassword("Enter Password"),
    believeNRows = FALSE
  )
}

odbcGetInfo(channel)  # check connection

# Pull cod data & calculate CPUE ----------------------------------------------
# Separate for EBS & NBS as combined area pulls haven't been tested
cod_data_ebs <- get_data(
  year_set = c(2024:2026),
  survey_set = "EBS",
  spp_codes = 21720,   
  haul_type = 3,
  abundance_haul = "Y",
  pull_lengths = FALSE,
  channel = channel
)
cod_cpue_ebs <- calc_cpue(gapdata = cod_data_ebs)

cod_data_nbs <- get_data(
  year_set = c(2024:2026),
  survey_set = "NBS",
  spp_codes = 21720,   
  haul_type = 3,
  abundance_haul = "Y",
  pull_lengths = FALSE,
  channel = channel
)
cod_cpue_nbs <- calc_cpue(gapdata = cod_data_nbs)

cod_cpue <- bind_rows(cod_cpue_ebs, cod_cpue_nbs) %>%
  mutate(CPUE_KGHA = CPUE_KGKM2 / 100) # convert to kg/ha 

# Create maps -----------------------------------------------------------------
# # Generate inverse-distance weighted spatial surface
cod_cpue <- cod_cpue %>% filter(YEAR == 2025)
idw_out <- make_idw_map(
    region = "bs.all",
    in.crs = "+proj=longlat", # Set input coordinate reference system
    out.crs = "EPSG:3338", # Set output coordinate reference system
    grid.cell = c(20000, 20000), # 20x20km grid
    LATITUDE = cod_cpue$LATITUDE_DD_START,
    LONGITUDE = cod_cpue$LONGITUDE_DD_START,
    CPUE_KGHA = cod_cpue$CPUE_KGHA
)

bs_layers <- get_base_layers(select.region = "bs.all", set.crs = "EPSG:3338")

grid_sf <- st_as_sf(idw_out$extrapolation.grid, as_points = FALSE)

clipped_grid <- st_intersection(grid_sf, st_union(bs_layers$survey.area))

ggplot() +
  geom_sf(data = clipped_grid, aes(fill = factor(var1.pred)), color = NA) +
  geom_sf(data = bs_layers$akland) +
  coord_sf(
    xlim = bs_layers$plot.boundary$x,
    ylim = bs_layers$plot.boundary$y,
    crs = 3338,
    expand = FALSE
  ) +
  scale_fill_viridis(option = "mako", discrete = TRUE, direction = -1) +
  labs(fill = "CPUE (kg/ha)")
