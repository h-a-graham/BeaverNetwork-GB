#  ==== packages for the targets script ====
library(targets)

# ==== external functions to import ====
source('R/check_data.R')
source('R/get_OS_grid.R')
source('R/warp_tcd.R')
source('R/warp_method.R')
source('R/set_up_gdalio.R')
source('R/fasterize_terra.R')
source('R/rasterize_vectors.R')
source('R/process_veg.R')
source('R/load_big_vectors.R')
source('R/split_grid_iter.R')

future::plan(future::multisession, workers = 2)
# ==== target options ====
options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("sf", "tidyverse", "purrr", "curl", "zip", "terra",
                            "fasterize", "gdalio"))

# ==== Define raw data locations: ====
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

# ==== BFI - desired resoltuion =====

ras_res <- 10


# ==== key folder locations ======
inter_data_dir <- 'int_files'
if (!dir.exists(inter_data_dir)) dir.create(inter_data_dir)

bfi_dir <- 'bfi_out'
if (!dir.exists(bfi_dir)) dir.create(bfi_dir)

# inter_data_dir <- 'int_files'
# if (!dir.exists(inter_data_dir)) dir.create(inter_data_dir)
# ==== Target list ====
list(
  # checks existence of data sources...
  tar_target(data_check, 
             check_data(c(ceh_lcm=ceh_lcm19,
                              cop_tcd=cop_tcd18, 
                              nfi=nfi_2018, 
                              os_vec=os_vmd,
                              os_ORN=os_orn))),
  # Download the OS 100m Grid - basis of chunking rasters.
  tar_target(download_OS_grid,
             get_OS_grid()),
  # mosaic and warp TCD data
  tar_target(mosaic_tcd, 
             warp_tcd(cop_tcd18, inter_data_dir)),
  #create working chunks
  tar_target(split_iterator,
             split_grid_iter(download_OS_grid[46:47], 2)),
  
  # create national nfi raster
  tar_target(proc_veg_tilesChunk1,
             map_veg_process(split_iterator[[1]],ceh_lcm19, mosaic_tcd,
                             nfi_2018, os_vmd, ras_res,
                             os_orn, bfi_dir)),
  tar_target(proc_veg_tilesChunk2,
             map_veg_process(split_iterator[[2]],ceh_lcm19, mosaic_tcd,
                             nfi_2018, os_vmd, ras_res,
                             os_orn, bfi_dir))
)
