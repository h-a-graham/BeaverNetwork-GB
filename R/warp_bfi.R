warp_bfi <- function(.path_lists, .bfi_dir, .nworkers){
  
  bfi_list <- purrr::map(.path_lists, ~.['bfi']) %>% unlist() %>% unname()
  bhi_list <- purrr::map(.path_lists, ~.['bhi']) %>% unlist() %>% unname()
  bhi_mm_list <- purrr::map(.path_lists, ~.['bhi_mmrivs']) %>% unlist() %>% unname()
  
  bfi_p <- file.path(.bfi_dir, 'bfi_GB.tif')
  bhi_p <- file.path(.bfi_dir, 'bhi_GB.tif')
  bhi_mm_p <- file.path(.bfi_dir, 'MM_rivs_bhi_GB.tif')
  
  future::plan(future::multisession, workers = .nworkers)
  
  gb_ras_files <- furrr::future_map2(.x = list(bfi_list, bhi_list, bhi_mm_list),
                                     .y = list(bfi_p, bhi_p, bhi_mm_p),
                                     ~warp_method(.x, .y))
  names(gb_ras_files) <- c('bfi', 'bhi', 'bhi_mmrivs')
  
  return(gb_ras_files)
  
}