load_nfi <- function(nfi){
  nfi <- sf::read_sf(nfi, 
                 query= sprintf("SELECT CATEGORY FROM \"%s\" WHERE CATEGORY = 'Woodland'
                                AND IFT_IOA NOT IN (
                                'Assumed woodland',
                                'Cloud \\ shadow',
                                'Failed','Felled', 
                                'Ground prep', 
                                'Uncertain', 
                                'Windblow',
                                'Young trees')",
                                tools::file_path_sans_ext(basename(nfi)))) %>%
    mutate(woodland=1) 
  return(nfi)
}

load_vmd <- function(vmd){
  vmd <-  sf::read_sf(vmd, layer='SurfaceWater_Area') %>%
    mutate(water=1) 
  return(vmd)
}

# soon to be defunt - leave in for now...
# load_orn <- function(os_orn){
#   os_orn <- 'data/river_nets/oprvrs_gpkg_gb/data/oprvrs_gb.gpkg' %>%
#     sf::read_sf(layer='WatercourseLink') 
#   return(os_orn)
#   
# }


chunk_big_sf <- function(.svec_path, .os_gridList, .dataName, .int_dir, 
                         .nworkers){
  
  save_dir <- file.path(.int_dir, .dataName)
  if (!dir.exists(save_dir)) dir.create(save_dir)
  
  riv_grid_int <- function(.grid, .svecpath, .save_dir){

    
    if (.dataName == 'nfi'){
      big_sf <- load_nfi(.svecpath)
    } else if (.dataName == 'vmd'){
      big_sf <- load_vmd(.svecpath)
    } else if (.dataName == 'osm_rivers'){
      big_sf <- sf::read_sf(.svecpath)
    } else if (.dataName == 'mm_rivers'){
      big_sf <- sf::read_sf(.svecpath)
    } else {
      stop("The .dataName argument is incorrect!")
    }
    
    g_name <- .grid$TILE_NAME
    
    clipped <- big_sf %>%
      st_intersection(.grid)
    
    save_name <-file.path(.save_dir, sprintf('%s_%s.rds', g_name, .dataName))
    saveRDS(clipped, save_name)
    return(save_name)
  }
  
  # future::plan(future::multisession, workers = parallel::detectCores()-2)
  future::plan(future::multisession, workers = .nworkers)
  .os_gridList %>%
    furrr::future_map(., ~riv_grid_int(., .svec_path, save_dir))
  
}