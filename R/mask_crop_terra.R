mask_crop_terra <- function(ras_path, vec_path, out_path){
  big_R <- terra::rast(ras_path)
  
  crop_R <- terra::crop(big_R, vec_path)
  
  mask_R <- terra::mask(crop_R, vect(vec_path))
  
  terra::writeRaster(mask_R, out_path, overwrite=TRUE)
}

mask_crop_terra_mem <- function(ras_terr, vec_path){
 
  crop_R <- terra::crop(ras_terr, vec_path)
  
  mask_R <- terra::mask(crop_R, vect(vec_path))
  
  return(mask_R)
}