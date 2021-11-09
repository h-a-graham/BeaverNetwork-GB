local_bfi_outs <- function(.osgrids, bfi_dir, region, veg_tiles, version,
                              nat_bfi, .mask=NULL){
  
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
  } else if (region == 'SouthWest') {
    tiles_needed <- c("SO", "SP", "SS", "ST", "SU", "SW", "SX", "SY", "SZ")
    suffix <-'SouthWest'
  } else if (region == 'Wales') {
    tiles_needed <- c("ST", "SS", "SN", "SM", "SH", "SJ", "SO")
    suffix <-'Wales'
  } else if (region == 'SouthEast') {
    tiles_needed <- c("SZ", "SU", "SP", "TL", "TQ", "TV", "TR", "TM")
    suffix <-'SouthEast'
  } else if (region == 'Midlands') {
    tiles_needed <- c("SO", "SJ", "SD", "SE", "SK", "SP", "TL", "TF", 
                      "TG", "TM")
    suffix <-'Midlands'
  } else if (region == 'North') {
    tiles_needed <- c("SJ", "SD", "NY", "NT", "NU", "NZ", "SE", "TA")
    suffix <-'North'
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
  
  if (!is.null(.mask)){
    mask_crop_terra(bhi_out_path, .mask, bhi_out_path)
    bhi_terr1km <- mask_crop_terra_mem(bhi_terr1km, .mask)
  }
  
  
  bhi_out_path1km <- file.path(out_dir, sprintf('bhi_1km_%s.tif', suffix))
  terra::writeRaster(bhi_terr1km, bhi_out_path1km, overwrite=TRUE)
  
  return(list(localBHI=bhi_out_path, local1kmBHI=bhi_out_path1km))

}