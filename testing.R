source('R/chunk_big_sf.R')
source('R/get_OS_grid.R')
source('R/check_data.R')
source('R/get_OS_grid.R')
source('R/warp_tcd.R')
source('R/warp_method.R')
source('R/set_up_gdalio.R')
source('R/rasterize_vectors.R')
source('R/process_veg.R')
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
library(osmextract)
library(targets)
# ==== Define raw data locations: ====
# CEH landcover 2019 20m raster
ceh_lcm19 <-'data/vegetation/FME_346E606F_1626178964646_1149/data/643eb5a9-9707-4fbb-ae76-e8e53271d1a0/gb2019lcm20m.tif'
# Copernicus TCD 2018 Data Folder
mosaic_tcd <- 'int_files/TCD_warped.tif'
# National Forest Inventory 2018 spatial vector (zipped shp format)
nfi_2018 <- 'data/vegetation/National_Forest_Inventory_Woodland_GB_2018-shp/8257a753-353e-48a5-8a6e-d69e63121aa5202041-1-1kunv01.h8eo.shp'
# OS VectorMapDistrict 
os_vmd <- 'data/vegetation/VectorMapDistrict/data/vmdvec_gb.gpkg'

# OS open Rivers
os_orn <- 'data/river_nets/oprvrs_gpkg_gb/data/oprvrs_gb.gpkg'

# ==== BFI - desired resoltuion =====
source(system.file("raster_format/raster_format.codeR", package = "gdalio", mustWork = TRUE))
ras_res <- 10
bfi_dir <- 'bfi_out'
if (!dir.exists(bfi_dir)) dir.create(bfi_dir)

os_grid <- 'C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/OS_Grids/OSGB_Grid_100km.shp' %>%
  st_read() %>%
  filter(TILE_NAME=='SX')

set_up_gdalio(os_grid, 10)
t <- gdalio_terra(mosaic_tcd)
terra::plot(t)
t <- gdalio_matrix(mosaic_tcd)
image(t)
gdalio_matrix(nfi_2018)
  
fullgrid <- get_OS_grid()

out <- map_veg_process(list(os_grid), ceh_lcm19, mosaic_tcd,
                             nfi_2018, os_vmd, ras_res,
                             os_orn, bfi_dir)


fullgrid[1:20]






os_gridST <- 'C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/OS_Grids/OSGB_Grid_100km.shp' %>%
  st_read() %>%
  filter(TILE_NAME=='ST')



rivers_englandST = oe_get(
  os_gridST,
  quiet = FALSE,
  boundary=os_gridST,
  query = "SELECT * FROM 'lines' WHERE waterway = 'river'
  OR waterway = 'ditch'
  OR waterway = 'drain'
  OR waterway ='brook'
  OR waterway ='canal'
  OR waterway ='derelict_canal'
  OR waterway ='disused_canal'
  OR waterway ='stream'"
) %>%
  select(waterway)

unique(rivers_englandST$waterway)

plot(st_geometry(rivers_englandST))

st_write(rivers_englandST, 'test_outs/OSM_rivers_testST.gpkg')



tests <- tar_read(create_osm_tiles)

SX_test <- readRDS(tests[[1]])

plot(st_geometry(SX_test))

SX_test %>% st_transform(., crs=27700)


os_gridST <- 'C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/OS_Grids/OSGB_Grid_100km.shp' %>%
  st_read() %>%
  filter(TILE_NAME=='SH')



eng_path <- oe_download(oe_match('england')$url)
wales_path <- oe_download(oe_match('wales')$url)
scot_path <- oe_download(oe_match('scotland')$url)

eng_gpkg <- oe_vectortranslate(eng_path, layer = "lines")
wales_gpkg <- oe_vectortranslate(wales_path, layer = "lines")
scot_gpkg <- oe_vectortranslate(scot_path, layer = "lines")

read_big_osm <- function(os_gpkg){
  os_gpkg <- st_read(os_gpkg, query = "SELECT * FROM 'lines' WHERE waterway = 'river'
  OR waterway = 'ditch'
  OR waterway = 'drain'
  OR waterway ='brook'
  OR waterway ='canal'
  OR waterway ='derelict_canal'
  OR waterway ='disused_canal'
  OR waterway ='stream'")%>%
    select(waterway) %>% 
    st_transform(., crs=27700)
}

future::plan(future::multisession, workers = 3)

gb_rivs <- list(eng_gpkg, wales_gpkg, scot_gpkg) %>%
  furrr::future_map(., ~read_big_osm(.)) %>%
  bind_rows()

st_write(gb_rivs, 'test_outs/gb_rivs.gpkg')

#---------------------------------------------------#

os_gridST <- 'C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/OS_Grids/OSGB_Grid_100km.shp' %>%
  st_read() %>%
  filter(TILE_NAME=='ST')

library(targets)
library(tidyverse)

source('R/process_veg.R')
source('R/rasterize_vectors.R')
bfi_dir <- 'bfi_out'
map_veg_process(tar_read(download_OS_grid)[30:31], ceh_lcm19, mosaic_tcd,
                           tar_read(chunk_nfi)[1:2], tar_read(chunk_vmd)[1:2], tar_read(chunk_osm_rivs)[1:2],
                           10, bfi_dir)

source('R/split_grid_iter.R')
o <- split_iters(list(1,2,3, 4), list(1,2,3, 4), list(1,2,3, 4), list(1,2,3, 4), 2)
o[[1]]


nest_list <- tar_read(proc_veg_tiles)

bfi_list <- purrr::map(nest_list, ~.['bfi']) %>% unlist() %>% unname()
bhi_list <- purrr::map(nest_list, ~.['bhi']) %>% unlist() %>% unname()


# 

mm_dirs <-list.dirs('C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/Raw_Data/mastermap-water/2018_10/gml')

future::plan(future::multisession, workers = 10)

mm_riv_sf <- mm_dirs %>%
  purrr::map(., ~list.files(., pattern = "\\.gpkg$", full.names =T)) %>%
  .[lapply(.,length)>0] %>%
  furrr::future_map(., ~sf::st_read(.) %>% dplyr::select(geom)) %>%
  bind_rows()

sf::write_sf(mm_riv_sf, 'data/river_nets/os_MasterMap_Rivers/OS_MM_rivnet.gpkg')





nfi_2018 <- 'data/vegetation/National_Forest_Inventory_Woodland_GB_2018-shp/8257a753-353e-48a5-8a6e-d69e63121aa5202041-1-1kunv01.h8eo.shp'
full <- st_read(nfi_2018)

full %>% 
  filter(CATEGORY=='Woodland',
         ! IFT_IOA %in% c('Assumed woodland','Cloud \\ shadow',
         'Failed','Felled', 'Ground prep', 'Uncertain', 'Windblow')) %>%
  select(IFT_IOA) %>%
  st_drop_geometry() %>%
  unique()

source('R/chunk_big_sf.R')
.nfi <- load_nfi(nfi_2018)

st_write(.nfi, 'test_outs/test_nfi2.gpkg', delete_dsn = T)


source('R/hack_for_bdc.R')

hack_for_bdc(tar_read(download_OS_grid))


warp_method()


# 
sbd <- st_read('D:/HG_Work/GB_Beaver_Data/BeaverNetwork-scot/SummStats_BeaverNetwork_Scot/ScottishBasinDistrict_SummStats.shp')

plot(st_geometry(sbd))

st_bbox(sbd)


##
file.path(dirname( tar_read(warp_gb_bfi)$bhi), 'Scotland_Out')

source('R/scotland_bfi_outs.R')
scotland_bfi_outs(bind_rows(tar_read(download_OS_grid)), tar_read(warp_gb_bfi))


fullgrid <- bind_rows(tar_read(download_OS_grid))

scot_grid <- fullgrid %>%
  st_filter(sbd, .pred = st_intersects)

scot_grid$TILE_NAME

plot(st_geometry(scot_grid), add=T)


# bhi_list <- purrr::map(tar_read(proc_veg_tiles), ~.['bhi']) %>% unlist() %>% unname()
bhi_mm_list <- purrr::map(tar_read(proc_veg_tiles), ~.['bhi_mmrivs']) %>% unlist() %>% unname()
grep(sprintf('%s_GB_BHI_os_mm', 'SX'), bhi_mm_list, value=TRUE)


### -----------

#masking test

big_R <- terra::rast(tar_read(SouthWest_BHI_ouputs)$localBHI)

plot(big_R)

mask <- read_sf('data/regions/SW_counties.gpkg') %>%
  st_union() %>%
  st_buffer(5000) %>%
  st_as_sf() %>%
  mutate(val=1)

crop_R <- terra::crop(big_R, mask)

mask_R <- terra::mask(crop_R, as(mask, 'SpatVector'))

plot(mask_R)

tfile <- tempfile(fileext = '.tif')
mask_R <- fasterize::fasterize(mask, raster = raster::raster(big_R))

dim(mask_R)

r <- terra::rast(terra::ext(raster::extent(mask_R)), nrows = dim(mask_R)[1], 
                 ncols = dim(mask_R)[2], crs = raster::crs(mask_R))
  
r <- terra::setValues(r, as.matrix(mask_R))


raster::writeRaster(mask_R, tfile)

mask_Rt <- terra::rast(tfile)

masked_R <- terra::mask(big_R, mask_R)


plot(mask_R)



mask <- read_sf('data/regions/SW_counties.gpkg') %>%
  st_union() %>%
  st_buffer(5000) %>%
  st_as_sf() %>%
  mutate(val=1)

write_sf(mask, 'data/regions/SW_buffer.gpkg')





mask_crop_terra <- function(ras_path, vec_path, out_path){
  big_R <- terra::rast(ras_path)
  
  crop_R <- terra::crop(big_R, vec_path)
  
  mask_R <- terra::mask(crop_R, vect(vec_path))
  
  terra::writeRaster(mask_R, out_path, overwrite=TRUE)
}


mask_raster <- function(ras_path, vec_path, out_ras){
  # if (file.exists(out_ras)) (file.remove(out_ras))
  
  sf::gdal_utils('warp',
             source=ras_path,
             destination = tempfile(fileext = '.tif'),
             options = c('-cutline', vec_path,
                         '-crop_to_cutline', ras_path))
}

microbenchmark::microbenchmark(

mask_raster(tar_read(SouthWest_BHI_ouputs)$localBHI,
            normalizePath('test_outs/SW_aoi.gpkg'),
            normalizePath('test_outs/SW_MASK_v2.tif')),

mask_terra(tar_read(SouthWest_BHI_ouputs)$localBHI,
           normalizePath('test_outs/SW_aoi.gpkg'),
           normalizePath('test_outs/SW_MASK_v3.tif')),
times = 1L)

