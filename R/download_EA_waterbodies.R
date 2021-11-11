
download_EA_waterbodies <- function(){
  read_rbd <- function(x){
    url <- sprintf('https://environment.data.gov.uk/catchment-planning/RiverBasinDistrict/%s.geojson',x)
    read_sf(url)
  }
  
  x <-2:13 %>% 
    .[.!=10]
  
  rbds <- x %>%
    lapply(read_rbd)%>% 
    bind_rows() %>%
    st_make_valid()
  
  st_crs(rbds) <- st_crs(4326)
  rbds <- rbds %>%
    st_transform(27700)
  
  rbds_poly <- rbds %>%
    filter(.,st_is(.,c("POLYGON", "MULTIPOLYGON"))) %>%
    filter(! water.body.type %in% c( "{ \"string\": \"Coastal Water\", \"lang\": \"en\" }",
                                     "{ \"string\": \"Groundwater Body\", \"lang\": \"en\" }",
                                     "{ \"string\": \"Surface water transfer\", \"lang\": \"en\" }")) 
  
  save_dir <- file.path('int_files', 'EA_waterbodies')
  if (!dir.exists(save_dir)) dir.create(save_dir)
  
  save_file <- file.path(save_dir, 'EAwaterbodyareas.gpkg')
  write_sf(rbds_poly, save_file)
  return(save_file)
}
