#  ==== packages for the targets script ====
library(targets)
library(tarchetypes)
suppressMessages(library(here))

# ==== external functions to import ====
source('R/check_data.R')
source('R/get_OS_grid.R')
source('R/warp_tcd.R')
source('R/warp_method.R')
source('R/set_up_gdalio.R')
source('R/rasterize_vectors.R')
source('R/process_veg.R')
source('R/download_osm_gb_rivers.R')
source('R/chunk_big_sf.R')
source('R/warp_bfi.R')
source('R/bfi_1km_res.R')
source('R/locl_bfi_outs.R')
source('R/mask_crop_terra.R')
source('R/hack_for_bdc.R') # won't be needed soon hopefully - needed to join up with python BDC workflow.
source('R/create_region_aois.R')
source('R/clip_bdc_region.R')
source('R/download_EA_waterbodies.R')
source('R/summarise_BeavNet.R')
source('R/save_zipped_shp.R')
source('R/render_regional_report.R')
source('R/download_NRW_WFD_mgmt.R')
future::plan(future::multisession, workers = 4)
# ==== target options ====
options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("sf", "tidyverse", "purrr", "furrr", "curl", "zip", 
                            "terra", "fasterize", "gdalio", "osmextract", 
                            "stringr", "rmarkdown", "here"))

# ==== Define raw data locations: ====
# CEH landcover 2019 20m raster
ceh_lcm19 <-'data/vegetation/FME_346E606F_1626178964646_1149/data/643eb5a9-9707-4fbb-ae76-e8e53271d1a0/gb2019lcm20m.tif'
# Copernicus TCD 2018 Data Folder
cop_tcd18 <- 'data/vegetation/TCD_2018_010m_gb_03035_v020/DATA'
# National Forest Inventory 2018 spatial vector (zipped shp format)
nfi_2018 <- 'data/vegetation/National_Forest_Inventory_Woodland_GB_2018-shp/8257a753-353e-48a5-8a6e-d69e63121aa5202041-1-1kunv01.h8eo.shp'
# OS VectorMapDistrict 
os_vmd <- 'data/vegetation/VectorMapDistrict/data/vmdvec_gb.gpkg'
# OS MAsterMapRivers (CLOSED DATA.)
os_mm_rivnet <- 'data/river_nets/os_MasterMap_Rivers/OS_MM_rivnet.gpkg'

# GB Counties 
GBCounty <- 'data/regions/GB_counties.gpkg'

# ==== BFI - desired resoltuion =====

ras_res <- 10


# ==== key folder locations ======
inter_data_dir <- file.path(here(),'int_files')
if (!dir.exists(inter_data_dir)) dir.create(inter_data_dir)

bfi_dir <- file.path(here(),'bfi_out')
if (!dir.exists(bfi_dir)) dir.create(bfi_dir)


# ==== Target list ====
list(
  # checks existence of data sources...
  tar_target(data_check, 
             check_data(c(ceh_lcm=ceh_lcm19,
                              cop_tcd=cop_tcd18, 
                              nfi=nfi_2018, 
                              os_vec=os_vmd))),
  # Download the OS 100m Grid - basis of chunking rasters.
  tar_target(download_OS_grid,
             get_OS_grid()),
  # Download OSM river network with {osmextract}
  tar_target(OSM_rivNet_download,
             download_osm_gb_rivers(inter_data_dir)),
  # Download EA water body areas for summary stats at the end.
  tar_target(download_EA_catchments,
             download_EA_waterbodies()),
  # Download NRW WFD Management Catchments for summary stats at the end.
  tar_target(download_NRW_catchments,
             download_NRW_WFD_mgmt()),
  # mosaic and warp TCD data
  tar_target(mosaic_tcd, 
             warp_tcd(cop_tcd18, inter_data_dir)),
  # create path list for nfi blocks
  tar_target(chunk_nfi,
             chunk_big_sf(nfi_2018, download_OS_grid,
                          'nfi', inter_data_dir, .nworkers=10)),
  # create path list for OS vmd water blocks
  tar_target(chunk_vmd,
             chunk_big_sf(os_vmd, download_OS_grid,
                          'vmd', inter_data_dir, .nworkers=15)),
  # create path list for OSM river network
  tar_target(chunk_osm_rivs,
             chunk_big_sf(OSM_rivNet_download, download_OS_grid,
                          'osm_rivers', inter_data_dir, .nworkers=18)),
  tar_target(chunk_MM_rivs,
             chunk_big_sf(os_mm_rivnet, download_OS_grid,
                          'mm_rivers', inter_data_dir, .nworkers=5)), # minimise workers - the river network is v detailed

  # create national nfi raster

  tar_target(proc_veg_tiles,
             map_veg_process(download_OS_grid, ceh_lcm19, mosaic_tcd,
                             chunk_nfi, chunk_vmd,chunk_osm_rivs, chunk_MM_rivs,
                             ras_res, bfi_dir, .nworkers=5)), # could increase workers to 5/6 but...
  tar_target(warp_gb_bfi,
             warp_bfi(proc_veg_tiles, bfi_dir, .nworkers=3)), # only needs 3 as we only have 3 rasters

  tar_target(hack_for_py,
             hack_for_bdc(download_OS_grid)), # Remove this target once we refactor python BDC code.
  tar_target(resample_BHI_1km,
             bfi_1km_res(warp_gb_bfi, bind_rows(download_OS_grid))),
  #Regional BFI data
  tar_target(Scotland_BHI_ouputs,
             local_bfi_outs(bind_rows(download_OS_grid), bfi_dir, 'Scotland',
                               proc_veg_tiles, 'bhi_mmrivs', warp_gb_bfi)),
  tar_target(Cornwall_BHI_ouputs,
             local_bfi_outs(bind_rows(download_OS_grid), bfi_dir, 'Cornwall',
                            proc_veg_tiles, 'bhi', warp_gb_bfi, 
                            generate_WLT_regions('Cornwall', GBCounty))),
  tar_target(SouthWest_BHI_ouputs,
             local_bfi_outs(bind_rows(download_OS_grid), bfi_dir, 'SouthWest',
                            proc_veg_tiles, 'bhi', warp_gb_bfi, 
                            generate_WLT_regions('SouthWest', GBCounty))),
  tar_target(SouthEast_BHI_ouputs,
             local_bfi_outs(bind_rows(download_OS_grid), bfi_dir, 'SouthEast',
                            proc_veg_tiles, 'bhi', warp_gb_bfi, 
                            generate_WLT_regions('SouthEast', GBCounty))),
  tar_target(Midlands_BHI_ouputs,
             local_bfi_outs(bind_rows(download_OS_grid), bfi_dir, 'Midlands',
                            proc_veg_tiles, 'bhi', warp_gb_bfi, 
                            generate_WLT_regions('Midlands', GBCounty))),
  tar_target(North_BHI_ouputs,
             local_bfi_outs(bind_rows(download_OS_grid), bfi_dir, 'North',
                            proc_veg_tiles, 'bhi', warp_gb_bfi, 
                            generate_WLT_regions('North', GBCounty))),
  tar_target(Wales_BHI_ouputs,
             local_bfi_outs(bind_rows(download_OS_grid), bfi_dir, 'Wales',
                            proc_veg_tiles, 'bhi', warp_gb_bfi, 
                            generate_WLT_regions('Wales', GBCounty))),
  #Regional BDC data
  tar_target(SouthWest_BDC_ouputs,
             clip_bdc_region(GBCounty, 'SouthWest', download_EA_catchments)),
  tar_target(SouthEast_BDC_ouputs,
             clip_bdc_region(GBCounty, 'SouthEast', download_EA_catchments)),
  tar_target(Midlands_BDC_ouputs,
             clip_bdc_region(GBCounty, 'Midlands', download_EA_catchments)),
  tar_target(North_BDC_ouputs,
             clip_bdc_region(GBCounty, 'North', download_EA_catchments)),
  tar_target(Wales_BDC_ouputs,
             clip_bdc_region(GBCounty, 'Wales', download_NRW_catchments,
                             country='Wales')),
  tar_target(Cornwall_BDC_ouputs,
             clip_bdc_region(GBCounty, 'Cornwall', download_EA_catchments)),
  tar_target(SouthWestReport,
             render_regional_report(normalizePath("R/regional_tech_report.Rmd"),
                                    region='South-West', 
                                    beavNet=toString(SouthWest_BDC_ouputs$bdcnet), 
                                    CountySumm=toString(SouthWest_BDC_ouputs$countysum), 
                                    WatBods= toString(SouthWest_BDC_ouputs$watbods), 
                                    BHI = toString(SouthWest_BHI_ouputs$localBHI),
                                    BHI1km = toString(SouthWest_BHI_ouputs$local1kmBHI),
                                    out_dir=dirname(toString(SouthWest_BHI_ouputs$localBHI)),
                                    file_ab='SouthWest', 
                                    scale_pos=c("left", "top"),
                                    biv_leg = c(0.1, 0.85))),
  tar_target(SouthEastReport,
             render_regional_report(normalizePath("R/regional_tech_report.Rmd"),
                                    region='South-East', 
                                    beavNet=toString(SouthEast_BDC_ouputs$bdcnet), 
                                    CountySumm=toString(SouthEast_BDC_ouputs$countysum), 
                                    WatBods= toString(SouthEast_BDC_ouputs$watbods), 
                                    BHI = toString(SouthEast_BHI_ouputs$localBHI),
                                    BHI1km = toString(SouthEast_BHI_ouputs$local1kmBHI),
                                    out_dir=dirname(toString(SouthEast_BHI_ouputs$localBHI)),
                                    file_ab='SouthEast', 
                                    scale_pos=c("left", "bottom"),
                                    biv_leg = c(0.2, 0.2))),
  tar_target(WalesReport,
             render_regional_report(normalizePath("R/regional_tech_report.Rmd"),
                                    region='Wales', 
                                    beavNet=toString(Wales_BDC_ouputs$bdcnet), 
                                    CountySumm=toString(Wales_BDC_ouputs$countysum), 
                                    WatBods= toString(Wales_BDC_ouputs$watbods), 
                                    BHI = toString(Wales_BHI_ouputs$localBHI),
                                    BHI1km = toString(Wales_BHI_ouputs$local1kmBHI),
                                    out_dir=dirname(toString(Wales_BHI_ouputs$localBHI)),
                                    file_ab='Wales', 
                                    scale_pos=c("left", "top"),
                                    biv_leg = c(0.3, 0.85),
                                    WB_names= 'NRW WFD Water Body')),
  tar_target(MidlandsReport,
             render_regional_report(normalizePath("R/regional_tech_report.Rmd"),
                                    region='Midlands', 
                                    beavNet=toString(Midlands_BDC_ouputs$bdcnet), 
                                    CountySumm=toString(Midlands_BDC_ouputs$countysum), 
                                    WatBods= toString(Midlands_BDC_ouputs$watbods), 
                                    BHI = toString(Midlands_BHI_ouputs$localBHI),
                                    BHI1km = toString(Midlands_BHI_ouputs$local1kmBHI),
                                    out_dir=dirname(toString(Midlands_BHI_ouputs$localBHI)),
                                    file_ab='Midlands', 
                                    scale_pos=c("right", "top"),
                                    biv_leg = c(0.8, 0.8))),
  tar_target(NorthReport,
             render_regional_report(normalizePath("R/regional_tech_report.Rmd"),
                                    region='North',
                                    beavNet=toString(North_BDC_ouputs$bdcnet), 
                                    CountySumm=toString(North_BDC_ouputs$countysum), 
                                    WatBods= toString(North_BDC_ouputs$watbods), 
                                    BHI = toString(North_BHI_ouputs$localBHI),
                                    BHI1km = toString(North_BHI_ouputs$local1kmBHI),
                                    out_dir=dirname(toString(North_BHI_ouputs$localBHI)),
                                    file_ab='North', 
                                    scale_pos=c("right", "top"),
                                    biv_leg = c(0.1, 0.85)))

  
)