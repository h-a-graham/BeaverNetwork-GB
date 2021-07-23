warp_tcd <- function(tcd_dir, save_dir){
  
  f_name <- file.path(save_dir, "TCD_warped.tif")
  
  tcd_tifs <- list.files(tcd_dir, pattern = "\\.tif$", full.names=T)
  
  w_tcd_path <- warp_method(tcd_tifs, f_name)
  
  return(w_tcd_path)
}