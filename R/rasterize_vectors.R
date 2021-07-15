# ras_template <- function(terr_ras, .res){
#   res_diff <- terra::res(terr_ras)[1]/.res
#   
#   r <- rast(nrows=nrow(terr_ras)*res_diff, ncols=ncol(terr_ras)*res_diff, 
#             xmin=ext(terr_ras)[1], xmax=ext(terr_ras)[2], 
#             ymin=ext(terr_ras)[3], ymax=ext(terr_ras)[4], 
#             crs=terra::crs(terr_ras))
#   return(r)
# }

rasterize_nfi <- function(lcm_path, nfi_path, res){
  # out_path <- file.path(save_dir, 'NFI_ras.tif')
  
  lcm_ter <- terra::rast(lcm_path)
  
  # r <- ras_template(lcm_ter, res)
  
  nfi_ras <- st_read(nfi_path, 
                     query= sprintf("SELECT CATEGORY FROM \"%s\" WHERE CATEGORY = 'Woodland'",
                                    tools::file_path_sans_ext(basename(nfi_path)))) %>%
    mutate(woodland=1) %>%
    fasterize_terra(., lcm_ter, 'woodland')
  
  # terra::writeRaster(nfi_all, out_path)
  
  return(nfi_ras)
}

rasterize_vmd <- function(lcm_path, vmd_path, res){
  
  # out_path <- file.path(save_dir, 'vmd_Water_ras.tif')
  
  lcm_ter <- terra::rast(lcm_path)
  
  # r <- ras_template(lcm_ter, res)
  
  vmd_wat_ras <- st_read(vmd_path, layer='SurfaceWater_Area') %>%
    mutate(water=1) %>%
    fasterize_terra(., lcm_ter, 'water')
  
  # terra::writeRaster(vmd_wat_all, out_path)
    
  
  return(vmd_wat_ras)
  
}


