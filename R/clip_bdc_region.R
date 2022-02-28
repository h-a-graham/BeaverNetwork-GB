
clip_bdc_region <- function(counties_gpkg, region_name, ea_watbod, 
                            country='England'){
  
  bdc_path <-'D:/HG_Work/GB_Beaver_Data/OpenBeaverNetwork_GB_v0_3/OpenBeaverNetwork_GB_v0_3.gpkg'
  CEH_has <- read_sf("C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/CEH_catchments/GB_CEH_HAs_V2.gpkg")
  
  
  aoi_gpkg <- generate_WLT_regions(region_name, counties_gpkg)
  
  aoi <- read_sf(aoi_gpkg)
  
  CEH_aoi <- CEH_has %>%
    filter(st_intersects(., aoi, sparse = FALSE)[,1])
  
  bdc_aoi <- CEH_aoi$HA_NUM %>%
    purrr::map(., ~sprintf('OpenBeaverNetwork_CEH_HA_%s',.x)) %>%
    purrr::map(., ~read_sf(bdc_path,layer=.)) %>%
    bind_rows() %>%
    filter(st_intersects(., aoi, sparse = FALSE)[,1])
  
  out.dir <- file.path('bfi_out', sprintf('%s_Out', region_name))
  
  # if (!dir.exists(out.dir)) dir.create(out.dir)
  
  bdc_out_gpkg <- file.path(out.dir, sprintf('BeaverNetwork_%s.gpkg',region_name))
  st_write(bdc_aoi, delete_dsn =T, bdc_out_gpkg)
  
  save_zipped_shp(bdc_aoi, sprintf('BeaverNetwork_%s',region_name), out.dir)
  # st_write(bdc_aoi, delete_dsn =T, file.path(out.dir, 
  #                             sprintf('BeaverNetwork_%s.shp',region_name)))
  
  
  
  # Get sumarries of polygons
  
  counties <- read_sf(counties_gpkg) %>%
    filter(ctyua19nm %in% region_counties(region_name))
  
  County_summs <- summarise_BeavNet(bdc_aoi, counties, "ctyua19nm")
  county_summs_gpkg <-  file.path(out.dir, 
                                  sprintf('BeavNet_CountySumm_%s.gpkg',region_name))
  st_write(County_summs, delete_dsn =T, county_summs_gpkg)
  
  save_zipped_shp(County_summs, 
                  sprintf('BeavNet_CountySumm_%s',region_name), 
                  out.dir)
  
  watbod.sf <- read_sf(ea_watbod) %>%
    filter(st_intersects(., st_union(counties), sparse = FALSE)[,1])
  
  catch_type <- if (country=='England') 'EA_WaterBods' else 'NRW_WFD_WaterBods'
  grp_name <- if (country=='England') 'name' else 'WB_NAME'
       
  EA_WB_summs <- summarise_BeavNet(bdc_aoi, watbod.sf, grp_name)
  watbods_gpkg <- file.path(out.dir, 
                               sprintf('BeavNet_%s_%s.gpkg',catch_type,
                                       region_name))
  st_write(EA_WB_summs, delete_dsn =T, watbods_gpkg)
  
  save_zipped_shp(EA_WB_summs, 
                  sprintf('BeavNet_%s_%s',catch_type,region_name), 
                  out.dir)
  
  return(list(bdcnet = normalizePath(bdc_out_gpkg),
              countysum = county_summs_gpkg,
              watbods = watbods_gpkg))
}
