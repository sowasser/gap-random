### Installation --------------------------------------------------------------

# Install TMB from CRAN
install.packages("TMB")
# Install INLA - only testing version works
install.packages("INLA",repos=c(getOption("repos"),INLA="https://inla.r-inla-download.org/R/testing"), dep=TRUE)

# Install devtools
install.packages("devtools")
library(devtools)

# Install FishStatsUtils from CRAN
install_github("james-thorson/FishStatsUtils@main", INSTALL_opts="--no-staged-install")

# Install VAST
install_github("james-thorson/VAST@main", INSTALL_opts="--no-staged-install")

# Load package
library(VAST)

# load data set
# see `?load_example` for list of stocks with example data 
# that are installed automatically with `FishStatsUtils`. 
example = load_example( data_set="EBS_pollock" )

# Make settings (turning off bias.correct to save time for example)
settings = make_settings( n_x = 100, 
                          Region = example$Region, 
                          purpose = "index2", 
                          bias.correct = FALSE )

# Run model
fit = fit_model( settings = settings, 
                 Lat_i = example$sampling_data[,'Lat'], 
                 Lon_i = example$sampling_data[,'Lon'], 
                 t_i = example$sampling_data[,'Year'], 
                 b_i = example$sampling_data[,'Catch_KG'], 
                 a_i = example$sampling_data[,'AreaSwept_km2'] )

# Plot results
plot( fit )