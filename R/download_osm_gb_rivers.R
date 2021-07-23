download_osm_gb_rivers <- function(.int_dir){
  save_path <- file.path(.int_dir,'gb_rivs.gpkg')
  if (file.exists(save_path)) return(save_path)
  eng_path <- oe_download(oe_match('england')$url)
  wales_path <- oe_download(oe_match('wales')$url)
  scot_path <- oe_download(oe_match('scotland')$url)
  
  eng_gpkg <- oe_vectortranslate(eng_path, layer = "lines")
  wales_gpkg <- oe_vectortranslate(wales_path, layer = "lines")
  scot_gpkg <- oe_vectortranslate(scot_path, layer = "lines")
  
  read_big_osm <- function(os_gpkg){
    os_gpkg <- st_read(os_gpkg, query = "SELECT * FROM 'lines' WHERE waterway = 'river'
  OR waterway = 'ditch'
  OR waterway = 'drain'
  OR waterway ='brook'
  OR waterway ='canal'
  OR waterway ='derelict_canal'
  OR waterway ='disused_canal'
  OR waterway ='stream'")%>%
      select(waterway) %>% 
      st_transform(., crs=27700)
  }
  
  future::plan(future::multisession, workers = 3)
  
  gb_rivs <- list(eng_gpkg, wales_gpkg, scot_gpkg) %>%
    furrr::future_map(., ~read_big_osm(.)) %>%
    bind_rows()
  
  
  st_write(gb_rivs, save_path)
  
  return(save_path)
}
