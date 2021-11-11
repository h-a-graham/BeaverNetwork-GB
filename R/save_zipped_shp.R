save_zipped_shp <- function(feature,.name, .outdir){
  
  td <- tempdir()
  sf::write_sf(feature, file.path(td, stringr::str_c(.name, '.shp')),
               delete_dsn =T)
  filelist <- Sys.glob(file.path(td, stringr::str_c(.name, '*')))
  
  zip_path <- file.path(.outdir, stringr::str_c(.name, '.zip'))
  zip::zipr(zip_path, files = filelist)
  
  purrr::map(filelist, file.remove)
}