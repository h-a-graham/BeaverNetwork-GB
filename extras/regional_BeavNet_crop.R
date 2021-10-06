# crop National BDC (from python) to an AOI.

library(sf)
library(dplyr)
library(magrittr)
library(Hmisc)

bdc_path <-'D:/HG_Work/GB_Beaver_Data/OpenBeaverNetwork_GB_v0_3/OpenBeaverNetwork_GB_v0_3.gpkg'
CEH_has <- read_sf("C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/CEH_catchments/GB_CEH_HAs_V2.gpkg")

SW_aoi <- read_sf('data/regions/SW_buffer.gpkg')

plot(st_geometry(CEH_has))
plot(st_geometry(SW_aoi))

CEH_aoi <- CEH_has %>%
  filter(st_intersects(., SW_aoi, sparse = FALSE)[,1])

plot(st_geometry(CEH_aoi))

  
bdc_aoi <- CEH_aoi$HA_NUM %>%
  purrr::map(., ~sprintf('OpenBeaverNetwork_CEH_HA_%s',.x)) %>%
  purrr::map(., ~read_sf(bdc_path,layer=.)) %>%
  bind_rows() %>%
  filter(st_intersects(., SW_aoi, sparse = FALSE)[,1])


plot(st_geometry(bdc_aoi))


st_write(bdc_aoi, 'bdc_out/BeaverNetwork_SouthWest.gpkg')
st_write(bdc_aoi, 'bdc_out/BeaverNetwork_SouthWest.shp')

# ---- Create regional summary for counties. ------------
counties <- read_sf('data/regions/SW_counties.gpkg') 

source('extras/summarise_BeavNet.R')
bdc_join <- summarise_BeavNet(bdc_aoi, counties, 'ctyua19nm')
st_write(bdc_join, 'bdc_out/BeavNet_CountySumm_SouthWest.gpkg', delete_dsn =T)
st_write(bdc_join, 'bdc_out/BeavNet_CountySumm_SouthWest.shp', delete_dsn =T)
