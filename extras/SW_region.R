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
