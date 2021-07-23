
fasterize_gdalio <- function(.sf_obj, .field){
  
  g <- gdalio::gdalio_get_default_grid()
  target_box <- sf::st_bbox(c(xmin = g$extent[[1]], ymin = g$extent[[3]], 
                              xmax = g$extent[[2]], ymax = g$extent[[4]]))
  
  ras_template <- raster::raster(raster::extent(g$extent), 
                                 nrows = g$dimension[2], 
                                 ncols = g$dimension[1], 
                                 crs = g$projection)
  
  if (nrow(.sf_obj) > 0){
    r <- fasterize::fasterize(st_collection_extract(.sf_obj, c("POLYGON")), 
                              ras_template, field = .field)
  } else {
    r <- raster::setValues(ras_template, NA, prod(g$dimension))
  }
  
  return(as.matrix(r))
  
}


rasterize_water_buff <- function(os_grid, rivs, vmd){
  
  rivs <-rivs %>%
    st_intersection(., os_grid)
  
  vmd <- vmd %>%
    st_intersection(., os_grid)
  
  bind_water <- bind_rows(rivs, vmd) %>%
    st_buffer(100) %>%
    select(geom)%>%
    st_cast('POLYGON')%>%
    mutate(buff=1) %>%
    select('buff')
  
  bw <- fasterize_gdalio(.sf_obj= bind_water, .field='buff')
  
  return(bw)
}
