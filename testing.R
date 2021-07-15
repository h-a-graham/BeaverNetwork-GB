library(terra)
source('R/set_up_gdalio.R')
source('R/warp_method.R')
source('R/process_veg.R')

.tcd <- terra::rast('int_files/tcd_ter2.tif')

.lcm <- terra::rast('int_files/lcm_ter.tif')

.nfi <- terra::rast('int_files/nfi_ter.tif')

.wat <- terra::rast('int_files/water_ras.tif')
# .emp[]<- 0

reclass_tcd <- function(tcd, lcm){
  .emp <- ras_template(lcm)
  .emp[tcd > 0 & tcd <3] <- 2
  .emp[tcd >= 3 & tcd <10] <- 3
  .emp[tcd >= 10 & tcd <50] <- 4
  .emp[tcd >= 50 & tcd <=100] <- 5
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


terra::writeRaster(.Rtcd_nfi_lcm_con_wat, 'test_outs/BFI_test1.tif')

terra::plot(.Rtcd)
terra::plot(.Rtcd_nfi)
terra::plot(.Rtcd_nfi_lcm_con_wat)
terra::plot(.tcd, add=T)

