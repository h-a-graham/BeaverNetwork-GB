library(terra)
library(sf)
library(dplyr)
source('R/set_up_gdalio.R')
source('R/warp_method.R')
source('R/process_veg.R')
source('R/fasterize_terra.R')
source('R/rasterize_vectors.R')
source('R/load_big_vectors.R')
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


os_grid <- 'C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/OS_Grids/OSGB_Grid_100km.shp' %>%
  st_read() %>%
  filter(TILE_NAME=='SX')
  
os_orn <- 'data/river_nets/oprvrs_gpkg_gb/data/oprvrs_gb.gpkg' #%>%
  st_read(layer='WatercourseLink') %>%
  st_intersection(., os_grid)

os_vmd <- 'data/vegetation/VectorMapDistrict/data/vmdvec_gb.gpkg' #%>%
  st_read(., layer='SurfaceWater_Area') %>%
  st_intersection(., os_grid)


bind_water <- bind_rows(os_orn, os_vmd) %>%
  st_buffer(100) %>%
  select(geom)%>%
  st_cast('POLYGON')%>%
  mutate(water=1)

bw <- fasterize_terra(bind_water, .lcm, 'water')


# nfi <- load_nfi(nfi)
vmd <- load_vmd(os_vmd)
os_orn <- load_orn(os_orn)
hab_zone <- rasterize_water_buff(.lcm, os_grid, os_orn, vmd)

.lcm[is.na(hab_zone)] <- hab_zone
r2 <- generate_bfi(.lcm, os_grid, os_orn, vmd)

plot(r2)

plot(.lcm)

plot(bind_water)

terra::writeRaster(.Rtcd_nfi_lcm_con_wat, 'test_outs/BFI_test1.tif')

terra::plot(.Rtcd)
terra::plot(.Rtcd_nfi)
terra::plot(.Rtcd_nfi_lcm_con_wat, col=RColorBrewer::brewer.pal(6, "Dark2"))
plot(st_geometry(os_grid), add=T, lwd=10)
plot(st_geometry(os_orn), add=T, lwd=5)
terra::plot(.tcd, add=T)


source('R/check_data.R')
source('R/get_OS_grid.R')
source('R/warp_tcd.R')
source('R/warp_method.R')
source('R/set_up_gdalio.R')
source('R/fasterize_terra.R')
source('R/rasterize_vectors.R')
source('R/process_veg.R')
source('R/load_big_vectors.R')

library(sf)
library(tidyverse)
library(purrr)
library(furrr)
library(curl)
library(zip)
library(terra)
library(fasterize)
library(gdalio)
library(stars)

os_grid <- 'C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/OS_Grids/OSGB_Grid_100km.shp' %>%
  st_read() %>%
  filter(TILE_NAME=='SX')

os_orn <- 'data/river_nets/oprvrs_gpkg_gb/data/oprvrs_gb.gpkg' %>%
st_read(layer='WatercourseLink') %>%
  st_intersection(., os_grid)

os_vmd <- 'data/vegetation/VectorMapDistrict/data/vmdvec_gb.gpkg' %>%
st_read(., layer='SurfaceWater_Area') %>%
  st_intersection(., os_grid)


bind_water <- bind_rows(os_orn, os_vmd) %>%
  st_buffer(100) %>%
  select(geom)%>%
  st_cast('POLYGON')%>%
  mutate(water=1)

target_box <- sf::st_bbox(os_grid)
target_res <- 10
xdim <- as.numeric((target_box[3]-target_box[1])/target_res)
ydim <- as.numeric((target_box[4]-target_box[2])/target_res)
ras_template <- stars::st_as_stars(target_box,
                                   dx = target_res, dy = target_res, values = NA_real_,
                                   crs = st_crs(os_grid))

out <-stars::st_rasterize(bind_water, ras_template, 
                          options = c("ALL_TOUCHED=TRUE")) %>%
  st_as_stars()

stars::write_stars(out, 'test_outs/stars_buff_rivs_test2.tif', type='Byte')

plot(out)
.lcm <- stars::read_stars('int_files/lcm_ter.tif')

library(osmextract)

os_gridST <- 'C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/OS_Grids/OSGB_Grid_100km.shp' %>%
  st_read() %>%
  filter(TILE_NAME=='ST')



rivers_englandST = oe_get(
  os_gridST,
  quiet = FALSE,
  boundary=os_gridST,
  query = "SELECT * FROM 'lines' WHERE waterway IS NOT NULL"
)


natural_englandST = oe_get(
  os_gridST,
  # layer='multipolygons',
  quiet = FALSE,
  boundary=os_gridST
  # query = "SELECT * FROM 'multipolygons' WHERE natural IS NOT NULL"
)

plot(sf::st_geometry(rivers_englandST))

st_write(rivers_englandST, 'test_outs/OSM_rivers_testST.gpkg')
st_write(natural_englandST, 'test_outs/OSM_natural_testST.gpkg')
# CEH landcover 2019 20m raster
ceh_lcm19 <-'data/vegetation/FME_346E606F_1626178964646_1149/data/643eb5a9-9707-4fbb-ae76-e8e53271d1a0/gb2019lcm20m.tif'
# Copernicus TCD 2018 Data Folder
cop_tcd18 <- 'data/vegetation/TCD_2018_010m_gb_03035_v020/DATA'
# National Forest Inventory 2018 spatial vector (zipped shp format)
nfi_2018 <- 'data/vegetation/National_Forest_Inventory_Woodland_GB_2018-shp/8257a753-353e-48a5-8a6e-d69e63121aa5202041-1-1kunv01.h8eo.shp'
# OS VectorMapDistrict 
os_vmd <- 'data/vegetation/VectorMapDistrict/data/vmdvec_gb.gpkg'

# OS open Rivers
os_orn <- 'data/river_nets/oprvrs_gpkg_gb/data/oprvrs_gb.gpkg'


# 
bind_water <- bind_rows(os_orn, os_vmd) %>%
  st_buffer(100) %>%
  select(geom)%>%
  st_cast('POLYGON')%>%
  mutate(water=1)






# ==== BFI - desired resoltuion =====

ras_res <- 10

bfi_dir <- 'bfi_out'
if (!dir.exists(bfi_dir)) dir.create(bfi_dir)

out <- map_veg_process(list(os_grid), ceh_lcm19, "int_files/TCD_warped.tif",
                           nfi_2018, os_vmd, ras_res,
                           os_orn, bfi_dir)


