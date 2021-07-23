set_up_gdalio <- function(OS_grid, res){
  
  bounds <- OS_grid %>%
    st_bbox() %>%
    round()
  
  grid0 <- list(extent = c(bounds$xmin, bounds$xmax, bounds$ymin, bounds$ymax ), 
                dimension = c((bounds$ymax-bounds$ymin)/res,
                              (bounds$xmax-bounds$xmin)/res), 
                projection = st_crs(OS_grid)$wkt)
  gdalio_set_default_grid(grid0)
  
}


gdalio_to_terra <- function(.gdalio){
  g <- gdalio_get_default_grid()
  r <- terra::rast(terra::ext(g$extent), nrows = g$dimension[2], ncols = g$dimension[1], crs = g$projection)
  
  r <- terra::setValues(r, .gdalio)
}

gdalio_matrix <- function(dsn, anti_rotate=TRUE, ...) {
  v <- gdalio_data(dsn, ...)
  g <- gdalio_get_default_grid()
  
  m <- matrix(v[[1]], g$dimension[1])[,g$dimension[2]:1, drop = FALSE]
  
  if (isTRUE(anti_rotate)){
     return(apply(t(m),2,rev))
  } else {
    return(m)
  }
  
}
