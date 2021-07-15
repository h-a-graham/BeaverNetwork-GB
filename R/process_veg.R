ras_template <- function(terr_ras, value=NA){
  
  .emp <- terra::rast(nrows=terra::nrow(terr_ras), ncols=terra::ncol(terr_ras),
                   xmin=terra::ext(terr_ras)[1], xmax=terra::ext(terr_ras)[2],
                   ymin=terra::ext(terr_ras)[3], ymax=terra::ext(terr_ras)[4],
                   crs=terra::crs(terr_ras))
  .emp[]<- value
  return(.emp)
}


veg_inference <- function(.tcd, .lcm, .nfi, .wat){
  
  reclass_tcd <- function(tcd, lcm){
    .emp <- ras_template(lcm)
    .emp[tcd > 0 & tcd <3] <- 2
    .emp[tcd >= 3 & tcd <10] <- 3
    .emp[tcd >= 10 & tcd <50] <- 4
    .emp[tcd >= 50 & tcd <=100] <- 5
    .emp[is.na(lcm)] <- NA
    return(.emp)
  }
  
  add_nfi <- function(nfi, Rtcd){
    Rtcd[is.na(Rtcd) & nfi == 1] <- 5
    return(Rtcd)
  }
  
  reclass_lcm <- function(lcm){
    .Rlcm <- ras_template(lcm, value = 0)
    .Rlcm[lcm == 1] <- 5
    .Rlcm[lcm == 2] <- 3
    .Rlcm[lcm %in% c(3, 5)] <- 2
    .Rlcm[lcm %in% c(4, 6, 7, 8, 9, 10, 11)] <- 1
    return(.Rlcm)
  }
  
  add_lcm <- function(Rlcm, Rtcd_nfi){
    Rtcd_nfi[is.na(Rtcd_nfi)] <- Rlcm
    return(Rtcd_nfi)
  }
  
  reclass_conifers <- function(lcm, Rtcd_nfi_lcm){
    .conifer <- lcm
    .conifer[lcm == 2] <- 1
    .conifer[lcm != 2] <- NA
  
    Rtcd_nfi_lcm[.conifer == 1] <- 3
    return(Rtcd_nfi_lcm)
  }
  
  reclass_water <- function(wat_area, Rtcd_nfi_lcm_con){
    Rtcd_nfi_lcm_con[wat_area==1] <- 0
    return(Rtcd_nfi_lcm_con)
  }
  
  .Rtcd <- reclass_tcd(.tcd, .lcm)
  
  .Rtcd_nfi <- add_nfi(.nfi, .Rtcd)
  
  .Rlcm <- reclass_lcm(.lcm)
  
  .Rtcd_nfi_lcm <- add_lcm(.Rlcm, .Rtcd_nfi)
  
  .Rtcd_nfi_lcm_con <- reclass_conifers(.lcm, .Rtcd_nfi_lcm)
  
  .Rtcd_nfi_lcm_con_wat <- reclass_water(.wat, .Rtcd_nfi_lcm_con)
  
  return(.Rtcd_nfi_lcm_con_wat)
  
}



process_veg <- function(grid_sf, lcm, tcd, nfi, vmd, res, bfi_save_dir){
  
  set_up_gdalio(grid_sf, res) # sets default extents dims etc for warping
  
  lcm_ter <- gdalio_terra(lcm, resample="near")
  
  tcd_ter <- gdalio_terra(tcd, resample="cubicspline")
  
  nfi_ter <- rasterize_nfi(lcm_ter, nfi, res)
  
  water_ras <- rasterize_vmd(lcm_ter, vmd, res)
  

  
  bfi <- veg_inference(tcd_ter, lcm_ter, nfi_ter, water_ras)
  save_path <- file.path(bfi_save_dir, 
                         sprintf('%s_GB_BFI.tif',grid_sf$TILE_NAME[1]))
  
  terra::writeRaster(bfi, save_path)
  
  return(save_path)
  
}


map_veg_process <- function(grid_list, lcm, tcd, nfi, vmd, res, bfi_save_dir){
  future::plan(multisession, workers = 2) # only 2 workers because this uses lots of RAM.
  grid_list %>%
    future_map(., ~process_veg(., lcm, tcd, nfi, vmd, res, bfi_save_dir))
  
}



