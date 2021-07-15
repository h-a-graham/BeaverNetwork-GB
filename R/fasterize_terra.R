fasterize_terra <- function(sf_obj, terr_obj, .field){
  
  r <- fasterize::fasterize(sf_obj, raster::raster(terr_obj), field = .field)
  
  return(terra::rast(r))
  
}

