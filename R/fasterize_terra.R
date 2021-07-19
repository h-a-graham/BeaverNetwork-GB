fasterize_terra <- function(sf_obj, terr_obj, .field){
  
  r <- fasterize::fasterize(sf_obj, raster::raster(terr_obj), field = .field)
  temploc <- tempfile(fileext = '.tif')
  raster::writeRaster(r, temploc)
  return(terra::rast(temploc))
  
}

