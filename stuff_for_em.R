library(rvest)

yrs <- 1950:2024

# searches <- data.frame("type" = "dummy", 
#                        "search" = "%22as+of+my+last+knowledge+update%22+-%22ChatGPT%22")

searches <- data.frame(type = "Bottom trawls", 
                       search = '"bottom trawl" OR "beam trawl" OR "otter trawl" OR "trawl" OR "groundfish" OR "shelfish" ') 

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Passive-acoustic", 
                                        search = '"Acoustic" OR "pelagic" OR "near-bottom" OR "near-surface" OR "mooring" OR "drone" OR "passive acoustics" OR "hydrophone" '))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Acoustic trawls", 
                                        search = '"Acoustic" OR "pelagic" OR "near-bottom" OR "near-surface" OR "active acoustics" OR "pelagic trawl" OR "trawl" OR "Mid water trawl" OR "Mid-water trawl" OR "Midwater trawl"'))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Mid-water trawls", 
                                        search = '"Mid water trawl" OR "Mid-water trawl" OR "Midwater trawl" OR "pelagic" OR "" OR "Acoustic" OR "pelagic" OR "near-bottom" OR "near-surface" '))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Dredge", 
                                        search = '"dredge" OR "benthos" OR "groundfish" OR "shelfish"'))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "eDNA", 
                                        search = '"edna" OR "e-dna"'))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Stationary gear", 
                                        search = '"stationary gear" OR "pot" OR "trap" OR "HOOK AND LINE" OR "HOOK & LINE" OR "LONGLINE" OR "groundfish" OR "shelfish" OR "pelagic" '))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Visual methods", 
                                        search = '"camera" OR "scuba" OR "video" OR "HABCAM"'))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Mark-recapture", 
                                        search = '"mark-recapture" OR "mark recapture" OR "mark recovery" OR "ptag" OR "foy tag" '))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Aerial surveys", 
                                        search = '"drone" OR "drones" OR "lidar" OR "plane" OR "aerial" OR "SURFACE" OR "Mid-water" OR "midwater" OR "mid water" ' ))


searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "All FIS", 
                                        search = '"survey" '))

searches$search <- paste0('"Fishery independent survey" OR "Fisheries independent survey" OR "Fishery-independent survey" OR "Fisheries-independent survey" OR "fish survey" OR "ecosystem survey" OR "Fishery independent data" OR ', searches$search)

searches$search <- gsub(pattern = '"', replacement = "%22", x = searches$search)
searches$search <- gsub(pattern = ' OR ', replacement = "|", x = searches$search)
# searches$search <- gsub(pattern = ' AND ', replacement = "+", x = searches$search)
searches$search <- gsub(pattern = ' ', replacement = "+", x = searches$search)

for (searches0 in 7:length(searches$search)){
  numpubs <- c()
  print(searches0)
  for (yr in yrs) {
    print(yr)
    url <- paste0("https://scholar.google.com/scholar?q=",searches$search[searches0],"&as_ylo=",yr,"&as_yhi=", yr)
    
    page <- read_html(url) %>%
      html_nodes(".gs_ab_mdw") %>%
      html_text()
    
    numpubs <- dplyr::bind_rows(
      numpubs, 
      data.frame("type" = searches$type[searches0], 
                 "search" = searches$search[searches0],
                 "year" = yr, 
                 "pubs" = as.numeric(gsub(",", "", stringr::str_extract(page[[2]], "\\d{1,3}(,\\d{3})*")))))
    
  }
  write.csv(x = numpubs, file = here::here("data", paste0("numpubs_", searches0,".csv")))
  
}
