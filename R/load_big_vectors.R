load_nfi <- function(nfi){
  nfi <- st_read(nfi, 
                 query= sprintf("SELECT CATEGORY FROM \"%s\" WHERE CATEGORY = 'Woodland'",
                                tools::file_path_sans_ext(basename(nfi)))) %>%
    mutate(woodland=1) 
  return(nfi)
}

load_vmd <- function(vmd){
  vmd <-  st_read(vmd, layer='SurfaceWater_Area') %>%
    mutate(water=1) 
  return(vmd)
}
 
load_orn <- function(os_orn){
  os_orn <- 'data/river_nets/oprvrs_gpkg_gb/data/oprvrs_gb.gpkg' %>%
    st_read(layer='WatercourseLink') 
  return(os_orn)
  
}