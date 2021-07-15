set_up_gdalio <- function(OS_grid, res){
  
  bounds <- OS_grid %>%
    st_bbox()
  
  grid0 <- list(extent = c(bounds$xmin, bounds$xmax, bounds$ymin, bounds$ymax ), 
                dimension = c((bounds$ymax-bounds$ymin)/res,
                              (bounds$xmax-bounds$xmin)/res), 
                projection = st_crs(OS_grid)$wkt)
  gdalio_set_default_grid(grid0)
  
}



gdalio_terra <- function(dsn, ...) {
  v <- gdalio_data(dsn, ...)
  g <- gdalio_get_default_grid()
  r <- terra::rast(terra::ext(g$extent), nrows = g$dimension[2], ncols = g$dimension[1], crs = g$projection)
  if (length(v) > 1) terra::nlyr(r) <- length(v)
  terra::setValues(r, matrix(unlist(v), prod(g$dimension)))
}


# gdalio_stars <- function(dsn, ...) {
#   v <- gdalio_data(dsn, ...)
#   g <- gdalio_get_default_grid()
#   aa <- array(unlist(v), c(g$dimension[1], g$dimension[2], length(v)))#[,g$dimension[2]:1, , drop = FALSE]
#   if (length(v) == 1) aa <- aa[,,1, drop = TRUE]
#   r <- stars::st_as_stars(sf::st_bbox(c(xmin = g$extent[1], ymin = g$extent[3], xmax = g$extent[2], ymax = g$extent[4])),
#                           nx = g$dimension[2], ny = g$dimension[1], values = aa) %>% 
#     sf::st_set_crs(., g$projection) %>%
#     st_flip(., which=2)
#   r
# }