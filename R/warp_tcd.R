warp_tcd <- function(tcd_dir, save_dir){
  
  f_name <- file.path(save_dir, "TCD_warped.tif")
  
  tcd_tifs <- list.files(tcd_dir, pattern = "\\.tif$", full.names=T)
  
  w_tcd_path <- warp_method(tcd_tifs, f_name)
  
  # outras <- terra::rast(w_tcd_path)
  # outras[outras > 100] <- NA
  # terra::writeRaster(outras, w_tcd_path)
  return(w_tcd_path)
}