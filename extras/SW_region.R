#SW Datasets.

library(dplyr)
library(sf)
library(tmap)
library(targets)
# if (!file.exists('SW_data')){
#   dir.create('SW_data')
# }

#  --------- Read SW county polygons ------------------

SW_boundaries <- read_sf('QGIS/map_data/Eng_Wales_Counties.gpkg') %>%
  filter(ctyua19nm %in% c('Devon', 'Cornwall', 'Plymouth', 'Torbay',
                          grep('Somerset', unique(.$ctyua19nm), value=T),
                          grep('Gloucestershire', unique(.$ctyua19nm), value=T),
                          grep('Bournemouth', unique(.$ctyua19nm), value=T),
                          'Bristol, City of', 'Wiltshire', 'Dorset', 'Avon',
                          'Swindon', 'Hampshire', 'Isle of Wight'))

plot(st_geometry(SW_boundaries), col = sf.colors(10, categorical = TRUE), border = 'grey',
     axes = TRUE, lwd=0.2)


tm_shape(SW_boundaries) +
  tm_polygons(col='ctyua19nm', title='Counties')

# 
write_sf(SW_boundaries, 'data/regions/SW_counties.gpkg')


OS_grid <- tar_read(download_OS_grid) %>%
  bind_rows() %>%
  filter(st_intersects(., st_union(SW_boundaries), sparse = FALSE)[,1])


tm_shape(SW_boundaries) +
  tm_polygons(col='ctyua19nm', title='Counties') +
  tm_shape(OS_grid) +
  tm_polygons(alpha=0) +
  tm_text('TILE_NAME')
  
OS_grid %>% pull('TILE_NAME')


# buffered area
mask <- read_sf('data/regions/SW_counties.gpkg') %>%
  st_union() %>%
  st_buffer(5000) %>%
  st_as_sf() %>%
  mutate(val=1)

write_sf(mask, 'data/regions/SW_buffer.gpkg')


# -- EA Waterbodies

library(tidyverse)
library(sf)
library(tmap)

read_rbd <- function(x){
  url <- sprintf('https://environment.data.gov.uk/catchment-planning/RiverBasinDistrict/%s.geojson',x)
  read_sf(url)
}

x <-2:13 %>% 
  .[.!=10]

rbds <- x %>%
  lapply(read_rbd)%>% 
  bind_rows() %>%
  st_make_valid()

st_crs(rbds) <- st_crs(4326)
rbds <- rbds %>%
  st_transform(27700)

bdc_join <- read_sf('bdc_out/BeavNet_CountySumm_SouthWest.gpkg')

rbds_poly <- rbds %>%
  filter(.,st_is(.,c("POLYGON", "MULTIPOLYGON"))) %>%
  filter(st_intersects(., st_union(bdc_join), sparse = FALSE)[,1]) %>%
  filter(! water.body.type %in% c( "{ \"string\": \"Coastal Water\", \"lang\": \"en\" }",
                                   "{ \"string\": \"Groundwater Body\", \"lang\": \"en\" }" ))
filter(water.body.type %in% c("{ \"string\": \"River\", \"lang\": \"en\" }",
                              "{ \"string\": \"Transitional Water\", \"lang\": \"en\" }"))

write_sf(rbds_poly, 'extras/data/SW_waterbodyareas.gpkg')
# rbds_line <- rbds %>%
#   filter(.,st_is(.,c("LINESTRING", "MULTILINESTRING")))%>%
#   filter(st_intersects(., st_union(bdc_join), sparse = FALSE)[,1])


tmap_mode("view")
tm_basemap(server='Esri.WorldImagery')+
  tm_shape(rbds_poly) +
  tm_polygons(col = "name")


source('extras/summarise_BeavNet.R')
bn_SW <- read_sf('bdc_out/BeaverNetwork_SouthWest.gpkg')
wb_bn_sum <- summarise_BeavNet(bn_SW, rbds_poly, 'name') %>%
  rename(waterbody=county)

st_write(wb_bn_sum, 'bdc_out/BeavNet_EA_WaterBods_SouthWest.gpkg', delete_dsn =T)
st_write(wb_bn_sum, 'bdc_out/BeavNet_EA_WaterBods_SouthWest.shp', delete_dsn =T)

tmap_mode("view")
tm_basemap(server='Esri.WorldImagery')+
  tm_shape(wb_bn_sum) +
  tm_polygons(col = "BDC_MEAN")
