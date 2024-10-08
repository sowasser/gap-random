library(rvest)

yrs <- 1950:2024

searches <- data.frame(type = "Bottom trawls", 
                       search = '"bottom trawl" OR "beam trawl" OR "otter trawl" OR "trawl" OR "groundfish" OR "shelfish" OR ("Fishery independent" OR "Fisheries independent" OR "Fishery-independent" OR "Fisheries-independent" OR "ecosystem survey" OR "Fishery independent data" OR "survey" OR "marine" OR "ocean" )') 

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Passive-acoustic", 
                                        search = ' "passive acoustic" OR acoustic OR "mooring" OR "drone"  OR "hydrophone" OR "saildrone" OR "near bottom" OR "near surface" OR marine OR "Fishery independent" OR "Fisheries independent" OR "Fishery independent" OR "Fisheries independent" OR "ecosystem survey" OR "Fishery independent data" OR survey OR marine OR ocean "passive" -acoustic '))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Acoustic trawls", 
                                        search = ' "active acoustic" OR acoustic OR pelagic OR "near bottom" OR "near surface" OR marine OR "Fishery independent" OR "Fisheries independent" OR "Fishery independent" OR "Fisheries independent" OR "ecosystem survey" OR "Fishery independent data" OR survey OR marine OR ocean "acoustic" -passive '))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Mid-water trawls", 
                                        search = ' ("Mid water trawl" OR "Mid-water trawl" OR "Midwater trawl") AND ("marine" OR "ocean" OR "ecology" OR "biology" OR "fauna" OR "pelagic") OR ("Fishery independent" OR "Fisheries independent" OR "Fishery-independent" OR "Fisheries-independent" OR "ecosystem survey" OR "Fishery independent data" OR "survey" OR "near-bottom" OR "near-surface") ) '))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Dredge", 
                                        search = '"dredge" AND "benthos" AND ("marine" OR "ocean" OR "ecology" OR "biology" OR "fauna" OR "groundfish" OR "shelfish" OR "survey") ) '))
searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "eDNA", 
                                        search = '"edna" OR "e-dna" AND ("marine" OR "ocean" OR "ecology" OR "biology" OR "fauna") '))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Stationary gear", 
                                        search = ' "stationary gear" OR "pot" OR "trap" OR "HOOK AND LINE" OR "HOOK & LINE" OR "LONGLINE" AND ("marine" OR "ocean" OR "ecology" OR "biology" OR "fauna" OR "survey") ')) 

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Visual methods", 
                                        search = ' "camera" OR "scuba" OR "snorkel" OR "video" OR "HABCAM" AND ("marine" OR "ocean" OR "ecology" OR "biology" OR "fauna" OR "survey") '))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Mark-recapture", 
                                        search = ' "mark-recapture" OR "mark recapture" OR "mark recovery" OR "ptag" OR "foy tag" OR "tagging" OR "tracking AND ("marine" OR "ocean" OR "ecology" OR "biology" OR "fauna") '))

searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "Aerial surveys", 
                                        search = ' "drone" OR "lidar" OR "airplane" OR "helicopter" OR "aerial" OR "imagery" OR "fauna" ("surface" OR "Mid-water" OR "midwater" OR "mid water") AND ("marine" OR "ocean" OR "ecology" OR "biology" OR "fauna" OR "survey") -"pollution" -"oil" -"oil spill" ' ))


searches <- dplyr::bind_rows(searches, 
                             data.frame(type = "All FIS", 
                                        search = ' "Fishery independent survey" OR "Fisheries independent survey" OR "Fishery-independent survey" OR "Fisheries-independent survey" OR "fish survey" OR "ecosystem survey" OR "Fishery independent data" OR "survey" OR "monitor" AND ("marine" OR "ocean" OR "ecology" OR "biology" OR "fauna" OR "groundfish" OR "shelfish" OR "pelagic") '))


searches$search <- gsub(pattern = '"', replacement = "%22", x = searches$search)
searches$search <- gsub(pattern = ' OR ', replacement = "|", x = searches$search)
# searches$search <- gsub(pattern = ' AND ', replacement = "+", x = searches$search)
searches$search <- gsub(pattern = ' ', replacement = "+", x = searches$search)

for (searches0 in 8:length(searches$search)){
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
  write.csv(x = numpubs, file = here::here(paste0("numpubs_", searches0,".csv")))
  
}
