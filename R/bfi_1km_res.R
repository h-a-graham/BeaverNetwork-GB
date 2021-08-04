bfi_1km_res<- function(.bfi_warped_out, .osgrids){
  
  
  bhi_path <- .bfi_warped_out$bhi
  bhiMM_path <- .bfi_warped_out$bhi_mmrivs
  
  bhi_1km_out <- file.path(dirname(.bfi_warped_out$bhi), 
                           'bhi_GB_1km.tif')
  bhiMM_1km_out <- file.path(dirname(.bfi_warped_out$bhi), 
                             'MM_rivs_bhi_GB_1km.tif')
  
  
  set_up_gdalio(.osgrids, 1000)
  
  bhi_terr1km <- gdalio_terra(bhi_path, resample="Average")

  
  terra::writeRaster(bhi_terr1km, bhi_1km_out, overwrite=TRUE)
  
  MMbhi_terr1km <- gdalio_terra(bhiMM_path, resample="Average")
  
  terra::writeRaster(MMbhi_terr1km, bhiMM_1km_out, overwrite=TRUE)
  
  return(c(bhi1km=bhi_1km_out, MM_bhi1km=bhiMM_1km_out))
  
  
}