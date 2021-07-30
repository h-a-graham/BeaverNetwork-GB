
hack_for_bdc <- function(.os_grid, .vmd_path= 'int_files/vmd', 
                         .bfi_dir='bfi_out/bfi', 
                         .hack_path='D:/HG_Work/GB_Beaver_Data/GB_BVI_Res_v3'){
  
  if (!dir.exists(.hack_path)) dir.create(.hack_path)
  
  # vmd <- load_vmd(.vmd_path)
  
  gen_stuff <- function(.grid){
    
    g_name <- tolower(.grid$TILE_NAME)
    g_path <- file.path(.hack_path, g_name)
    if (!dir.exists(g_path)) dir.create(g_path)
    g_fname <- sprintf('%s_WaterArea.gpkg', g_name)
    
    vmd_rdsP <- list.files(.vmd_path, pattern = sprintf('%s',.grid$TILE_NAME),
                           full.names = T)
    
    readRDS(vmd_rdsP) %>%
      st_write(., file.path(g_path, g_fname), delete_dsn=T)
    
    
    bfi_files <- list.files(.bfi_dir, pattern = sprintf('%s',.grid$TILE_NAME),
                            full.names = T)
    
    file.copy(bfi_files, g_path, overwrite=T)
    
  }
  
  .os_grid %>%
    purrr::walk(., ~gen_stuff(.))
  
}