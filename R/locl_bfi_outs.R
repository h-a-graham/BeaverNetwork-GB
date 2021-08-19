local_bfi_outs <- function(.osgrids, bfi_dir, region, veg_tiles, version,
                              nat_bfi){
  
  out_dir <- file.path(bfi_dir, sprintf('%s_Out', region))
  
  if (!dir.exists(out_dir)) dir.create(out_dir)
  
  if (region=='Scotland'){
    tiles_needed <- c("NA", "NB", "NC", "ND", "NF", "NG", "NH", "NJ", "NK", "NL",
                      "NM", "NN", "NO", "NR", "NS", "NT", "NU", "NW", "NX", "NY",
                      "SD", "NZ", "SE")
    suffix <- 'SCOT'
  } else if (region == 'Cornwall') {
    tiles_needed <- c("SW", "SX", "SS")
    suffix <- 'CORN'
  }
  
  
  bhi_mm_list <- purrr::map(veg_tiles, ~.[version]) %>% unlist() %>% unname()
  
  get_file <- function(tilename){
    if (version=='bhi_mmrivs'){
      grep(sprintf('%s_GB_BHI_os_mm', tilename), bhi_mm_list, value=TRUE)
    } else if (version=='bhi'){
      grep(sprintf('%s_GB_BHI', tilename), bhi_mm_list, value=TRUE)
    }
  }
  
  bhi_list <- tiles_needed %>%
    purrr::map(., ~get_file(.))
  
  
  bhi_out_path <- file.path(out_dir, sprintf('bhi_%s.tif', suffix))
  warp_method(bhi_list, bhi_out_path)
  
  bounds <- filter(.osgrids, TILE_NAME %in% c(tiles_needed))
  
  # Now for 1km data.
  set_up_gdalio(bounds, 1000)
  
  if (version=='bhi_mmrivs'){
    bhi_terr1km <- gdalio_terra(nat_bfi$bhi_mmrivs, resample="Average")
  } else if (version=='bhi'){
    bhi_terr1km <- gdalio_terra(nat_bfi$bhi, resample="Average")
  }
  
  bhi_out_path1km <- file.path(out_dir, sprintf('bhi_1km_%s.tif', suffix))
  terra::writeRaster(bhi_terr1km, bhi_out_path1km, overwrite=TRUE)
  
  return(list(localBHI=bhi_out_path, local1kmBHI=bhi_out_path1km))

}