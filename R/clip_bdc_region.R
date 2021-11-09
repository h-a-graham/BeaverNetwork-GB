
clip_bdc_region <- function(region_gpkg, region_name){
  
  bdc_path <-'D:/HG_Work/GB_Beaver_Data/OpenBeaverNetwork_GB_v0_3/OpenBeaverNetwork_GB_v0_3.gpkg'
  CEH_has <- read_sf("C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/CEH_catchments/GB_CEH_HAs_V2.gpkg")
  
  aoi <- read_sf(region_gpkg)
  
  CEH_aoi <- CEH_has %>%
    filter(st_intersects(., aoi, sparse = FALSE)[,1])
  
  bdc_aoi <- CEH_aoi$HA_NUM %>%
    purrr::map(., ~sprintf('OpenBeaverNetwork_CEH_HA_%s',.x)) %>%
    purrr::map(., ~read_sf(bdc_path,layer=.)) %>%
    bind_rows() %>%
    filter(st_intersects(., aoi, sparse = FALSE)[,1])
  
  out.dir <- file.path('bfi_out', sprintf('%s_Out', region_name))
  
  # if (!dir.exists(out.dir)) dir.create(out.dir)
  
  st_write(bdc_aoi, delete_dsn =T, file.path(out.dir, 
                              sprintf('BeaverNetwork_%s.gpkg',region_name)))
  st_write(bdc_aoi, delete_dsn =T, file.path(out.dir, 
                              sprintf('BeaverNetwork_%s.shp',region_name)))
}
