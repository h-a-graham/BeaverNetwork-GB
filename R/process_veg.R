ras_template <- function(value=NA){
  g <- gdalio_get_default_grid()
  .emp <- matrix(value, nrow = g$dimension[2], ncol = g$dimension[1])
  # matrix(data=NA, g$dimension[1])[,g$dimension[2]:1, drop = FALSE]
  return(.emp)
}


veg_inference <- function(.tcd, .lcm, .nfi, .wat){
  
  reclass_tcd <- function(tcd, lcm){
    .emp <- ras_template()
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
    .Rlcm <- ras_template(value = 0)
    .Rlcm[lcm == 1] <- 5
    .Rlcm[lcm == 2] <- 3
    .Rlcm[lcm %in% c(3, 5)] <- 2
    .Rlcm[lcm %in% c(4, 6, 7, 8, 9, 10, 11)] <- 1
    return(.Rlcm)
  }
  
  add_lcm <- function(Rlcm, Rtcd_nfi){
    Rtcd_nfi[is.na(Rtcd_nfi)] <- Rlcm[is.na(Rtcd_nfi)]
    return(Rtcd_nfi)
  }
  
  reclass_conifers <- function(lcm, Rtcd_nfi_lcm){
    Rtcd_nfi_lcm[lcm == 2] <- 3
    return(Rtcd_nfi_lcm)
  }
  
  reclass_water <- function(wat_area, Rtcd_nfi_lcm_con){
    Rtcd_nfi_lcm_con[wat_area==1] <- 0
    return(Rtcd_nfi_lcm_con)
  }
  
  .Rtcd <- reclass_tcd(.tcd, .lcm)
  rm(.tcd)
  
  .Rtcd_nfi <- add_nfi(.nfi, .Rtcd)
  rm(.nfi, .Rtcd)
  
  .Rlcm <- reclass_lcm(.lcm)
  
  .Rtcd_nfi_lcm <- add_lcm(.Rlcm, .Rtcd_nfi)
  rm(.Rlcm, .Rtcd_nfi)
  
  .Rtcd_nfi_lcm_con <- reclass_conifers(.lcm, .Rtcd_nfi_lcm)
  rm(.lcm, .Rtcd_nfi_lcm)
  
  .Rtcd_nfi_lcm_con_wat <- reclass_water(.wat, .Rtcd_nfi_lcm_con)
  rm(.wat, .Rtcd_nfi_lcm_con)
  
  return(.Rtcd_nfi_lcm_con_wat)
  
}


generate_bfi <- function(.bfi, .os_grid, .osm_rivs, .vmd){
  
  hab_zone <- rasterize_water_buff(.os_grid, .osm_rivs, .vmd)
  
  .bfi[is.na(hab_zone)] <- NA
  
  return(.bfi)
}


process_veg <- function(grid_sf, lcm, tcd, nfi, vmd, osm_rivs, mm_rivs, 
                        res, bfi_save_dir){

  nfi <- readRDS(nfi)
  
  vmd <- readRDS(vmd) #%>%
    # st_cast(., 'POLYGON')
  
  
  
  
  #warp and set up rasters for math.

  set_up_gdalio(grid_sf, res) # sets default extents dims etc for warping
  
  lcm_gd <- gdalio_matrix(lcm, resample="near")
  
  tcd_gd <- gdalio_matrix(tcd, resample="cubicspline")
  
  nfi_gd <- fasterize_gdalio(.sf_obj=nfi, .field='woodland')
    
  water_gd <- fasterize_gdalio(.sf_obj= vmd, .field='water')
  
  # run the math
  bfi <- veg_inference(tcd_gd, lcm_gd, nfi_gd, water_gd) 
  rm(tcd_gd, lcm_gd, nfi_gd, water_gd)  
  #save file
  
  save_path1 <- file.path(bfi_save_dir, 'bfi',
                         sprintf('%s_GB_BFI.tif',grid_sf$TILE_NAME[1]))
  
  terra::writeRaster(gdalio_to_terra(bfi), save_path1, overwrite=TRUE,
                     gdal=c("COMPRESS=LZW", "TFW=YES"))
  
  # run the buffer clipping to make BHI.
  osm_rivs <- readRDS(osm_rivs)
  bhi_open <- generate_bfi(bfi, grid_sf, osm_rivs, vmd)
  rm(osm_rivs)  
  #save file
  save_path2 <- file.path(bfi_save_dir, 'bhi',
                         sprintf('%s_GB_BHIop.tif',grid_sf$TILE_NAME[1]))

  terra::writeRaster(gdalio_to_terra(bhi_open), save_path2, overwrite=TRUE)
  
  
  # run the buffer clipping to make MMrivers BHI.
  mm_rivs <- readRDS(mm_rivs)
  bhi_MM_rivs <- generate_bfi(bfi, grid_sf, mm_rivs, vmd)
  rm(mm_rivs)
  #save file
  save_path3 <- file.path(bfi_save_dir, 'bhi_mm_riv',
                          sprintf('%s_GB_BHI_os_mm.tif',grid_sf$TILE_NAME[1]))
  
  terra::writeRaster(gdalio_to_terra(bhi_MM_rivs), save_path3, overwrite=TRUE)

  return(c(bfi=save_path1, bhi=save_path2, bhi_mmrivs = save_path3))
  
}


map_veg_process <- function(grid_list, lcm, tcd, nfi.list, vmd.list, osmriv.list,
                            mmriv.list, res, bfi_save_dir, .nworkers){
  #create folders...
  if (!file.exists(file.path(bfi_save_dir, 'bfi'))) {
    dir.create(file.path(bfi_save_dir, 'bfi'))}
  if (!file.exists(file.path(bfi_save_dir, 'bhi'))) {
    dir.create(file.path(bfi_save_dir, 'bhi'))}
  if (!file.exists(file.path(bfi_save_dir, 'bhi_mm_riv'))) {
    dir.create(file.path(bfi_save_dir, 'bhi_mm_riv'))}
  
  future::plan(future::multisession, workers = .nworkers)
  p_list <- list(grid_list, nfi.list, vmd.list, osmriv.list, mmriv.list)
  
  saved_files <- future_pmap(p_list, 
                             ~process_veg(grid_sf=..1, lcm=lcm, tcd=tcd, nfi=..2, 
                                          vmd=..3, osm_rivs=..4, mm_rivs=..5,
                                          res=res, bfi_save_dir = bfi_save_dir))
  # 
  # message('AAAAHHHHH')
  # saved_files <- purrr::pmap(p_list, ~process_veg(..1, lcm, tcd, ..2, ..3, ..4,
  #                                                 res, bfi_save_dir))

  message('veg processed')
  return(saved_files)
  
  
}



