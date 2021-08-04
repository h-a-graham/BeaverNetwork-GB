scotland_bfi_outs <- function(.osgrids, bfi_files){
  
  scot_dir <- file.path(dirname(bfi_files$bhi_mmrivs), 'Scotland_Out')
  
  if (!dir.exists(scot_dir)) dir.create(scot_dir)
  
  tiles_needed <- c("NA", "NB", "NC", "ND", "NF", "NG", "NH", "NJ", "NK", "NL",
                    "NM", "NN", "NO", "NR", "NS", "NT", "NU", "NW", "NX", "NY",
                    "SD", "NZ", "SE")
  
  bhi_mm_list <- purrr::map(tar_read(proc_veg_tiles), ~.['bhi_mmrivs']) %>% unlist() %>% unname()
  
  get_file <- function(tilename){
    grep(sprintf('%s_GB_BHI_os_mm', tilename), bhi_mm_list, value=TRUE)
  }
  
  bhi_list <- tiles_needed %>%
    purrr::map(., ~get_file(.))
  
  bhi_scot_path <- file.path(scot_dir, 'bhi_SCOT.tif')
  warp_method(bhi_list, bhi_scot_path)
  
  bounds <- filter(.osgrids, TILE_NAME %in% c(tiles_needed))
  
  # Now for 1km data.
  set_up_gdalio(bounds, 1000)
  
  bhi_terr1km <- gdalio_terra(bfi_files$bhi_mmrivs, resample="Average")
  bhi_scot_path1km <- file.path(scot_dir, 'bhi_1km_SCOT.tif')
  terra::writeRaster(bhi_terr1km, bhi_scot_path1km, overwrite=TRUE)
  
  return(list(scotBHI=bhi_scot_path, scot1kmBHI=bhi_scot_path1km))

}