get_OS_grid <- function(){
  grid_url <- 'https://github.com/charlesroper/OSGB_Grids/archive/refs/heads/master.zip'
  
  grid_folder <- tempfile(fileext = '.zip')
  unzipped_loc <- tempdir()
  curl_download(grid_url, grid_folder)
  
  unzip(grid_folder, exdir = unzipped_loc)
  
  OS_100km_grid <- file.path(unzipped_loc, 'OSGB_Grids-master', 
                             'Shapefile', 'OSGB_Grid_100km.shp') %>%
    st_read() %>%
    select(TILE_NAME) %>%
    group_by(TILE_NAME) %>%
    group_split()
  
}