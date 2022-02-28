download_NRW_WFD_mgmt <- function(){
  nrw_wfd_poly <- read_sf(paste0('http://lle.gov.wales/services/wfs?version=',
                                 '1.0.0&request=GetFeature&typeName=inspire-',
                                 'nrw:NRW_WFD_RIVER_CATCHMENTS_C2&outputForm', 
                                 'at=application%2Fjson')) %>%
    dplyr::select('WB_NAME', "WBID")
  
  save_dir <- file.path('int_files', 'NRW_catchments')
  if (!dir.exists(save_dir)) dir.create(save_dir)
  
  save_file <- file.path(save_dir, 'NRW_WFD_catch.gpkg')
  write_sf(nrw_wfd_poly, save_file, delete_dsn =TRUE)
  return(save_file)
  
}