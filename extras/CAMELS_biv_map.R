# CAMELS GB bivariate...

library(tidyverse)
library(sf)
library(tmap)
library(maptiles)

CAMELS_shp <- 'extras/data/8344e4f3-d2ea-44f5-8afa-86d2987543a9/8344e4f3-d2ea-44f5-8afa-86d2987543a9/data/CAMELS_GB_catchment_boundaries'

CAMELS_lc <- 'extras/data/8344e4f3-d2ea-44f5-8afa-86d2987543a9/8344e4f3-d2ea-44f5-8afa-86d2987543a9/data/CAMELS_GB_landcover_attributes.csv'
CAMELS_lc_df <- read_csv(CAMELS_lc)

CAMELS_sf <- read_sf(CAMELS_shp) %>%
  left_join(CAMELS_lc_df, by=c('ID'='gauge_id')) %>%
  st_make_valid()

tm_shape(CAMELS_sf) +
  tm_polygons(col='dwood_perc')


source("extras/bivariate_tmap.R")

CAMELS_SP <- as(CAMELS_sf, "Spatial")


camels_osm <- get_tiles(CAMELS_sf, crop = TRUE, zoom = 6,
                        provider=  "Stamen.TerrainBackground")

# Option 1
# Plot bivariate choroplet map (including legend)

bivariate_choropleth(CAMELS_SP, c("dwood_perc", "crop_perc"),
                     basemap=camels_osm, bm_alpha=0.7, bivmap_scale=T, 
                     bivmap_labels=c('dwood_perc', 'crop_perc'),
                     poly_alpha=0.9, scale_pos = c('right', 'bottom')) 

wfd_catch <- 'extras/data/EA_WFDRiverWaterBodyCatchmentsCycle2_GeoJSON_Full/data/WFD_River_Water_Body_Catchments_Cycle_2.json'
wfd_catch_sf <- read_sf(wfd_catch) %>%
  st_transform(27700)

bdc_join <- read_sf('bdc_out/BeavNet_CountySumm_SouthWest.gpkg')

sw_catchs <- wfd_catch_sf %>%
filter(st_intersects(., st_union(bdc_join), sparse = FALSE)[,1]) %>%
  group_by(rbd_name) %>%
  summarise()

plot(st_geometry(sw_catchs))
plot(st_geometry(bdc_join), col='red', add=T)

