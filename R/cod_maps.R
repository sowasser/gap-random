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

# Set inputs ------------------------------------------------------------------
species <- 21720  # adult cod only; could generalize to include juvenile cod.
this_year <- as.numeric(format(Sys.Date(), "%Y"))
years <- (this_year - 2):this_year

# Pull cod data & calculate CPUE ----------------------------------------------
# Separate for EBS & NBS as combined area pulls haven't been tested
cod_data_ebs <- get_data(
  year_set = c(2024:2026),
  survey_set = "EBS",
  spp_codes = species,   
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
# Get survey extent from akgfmaps
bs_all_layers   <- get_base_layers(select.region = "bs.all", set.crs = "EPSG:3338")
bs_south_layers <- get_base_layers(select.region = "bs.south", set.crs = "EPSG:3338")
bs_north_layers <- get_base_layers(select.region = "bs.north", set.crs = "EPSG:3338")

# Set breaks for CPUE scale across all years
pos_vals <- cod_cpue$CPUE_KGHA[cod_cpue$CPUE_KGHA > 0 & !is.na(cod_cpue$CPUE_KGHA)]
pos_breaks <- classIntervals(pos_vals, n = 5, style = "fisher")$brks

# Strictly finite breaks (no -Inf or Inf)
max_val <- ceiling(max(cod_cpue$CPUE_KGHA, na.rm = TRUE))
global_breaks <- c(0, round(pos_breaks[-1]))
global_breaks[length(global_breaks)] <- max_val  # Ensure max value is included

# Generate bin labels using global_breaks
bin_labels <- c(
  "No catch",
  paste0("0 – ", format(global_breaks[2], big.mark = ",")),
  paste0(format(global_breaks[2], big.mark = ","), " – ", format(global_breaks[3], big.mark = ",")),
  paste0(format(global_breaks[3], big.mark = ","), " – ", format(global_breaks[4], big.mark = ",")),
  paste0(format(global_breaks[4], big.mark = ","), " – ", format(global_breaks[5], big.mark = ",")),
  paste0(format(global_breaks[5], big.mark = ","), " – ", format(global_breaks[6], big.mark = ","))
)

# Make inverse distance weighted spatial surface for each year
no_nbs <- years[!(years %in% cod_cpue_nbs$YEAR)]  # subset of years w/ no NBS for plotting

idw_list <- lapply(years, function(yr) {
  df_yr <- cod_cpue %>% filter(YEAR == yr)
  
  # Select region and mask based on whether NBS was surveyed
  if (yr %in% no_nbs) {
    target_region <- "bs.south"
    survey_mask   <- bs_south_layers$survey.area
  } else {
    target_region <- "bs.all"
    survey_mask   <- bs_all_layers$survey.area
  }
  
  idw_out <- make_idw_map(
    region = target_region, 
    in.crs = "+proj=longlat",
    out.crs = "EPSG:3338",
    set.breaks = global_breaks,
    LATITUDE = df_yr$LATITUDE_DD_START,
    LONGITUDE = df_yr$LONGITUDE_DD_START,
    CPUE_KGHA = df_yr$CPUE_KGHA
  )
  
  grid_stars <- idw_out$extrapolation.grid
  
  if (!is.null(grid_stars)) {
    # Crop raster grid to year-appropriate survey boundary
    masked_stars <- grid_stars[survey_mask] 
    
    # Convert stars object to sf polygons
    grid_sf <- st_as_sf(masked_stars, as_points = FALSE)
    grid_sf$YEAR <- yr
    
    return(grid_sf)
  }
  return(NULL)
})

# Combine all years and plot
idw_all <- do.call(rbind, idw_list[!sapply(idw_list, is.null)])

sf_use_s2(FALSE)  # spherical geometry switched off
ggplot() +
  geom_sf(data = idw_all, aes(fill = factor(var1.pred)), color = NA) +
  geom_sf(data = bs_all_layers$akland) + 
  coord_sf(
    xlim = bs_all_layers$plot.boundary$x,
    ylim = bs_all_layers$plot.boundary$y,
    expand = FALSE
  ) +
  scale_fill_viridis(
    option = "mako", 
    discrete = TRUE, 
    direction = -1, 
    labels = bin_labels, 
    drop = FALSE
  ) +
  labs(fill = "CPUE (kg/ha)") +
  facet_wrap(~ YEAR, axes = "all")
