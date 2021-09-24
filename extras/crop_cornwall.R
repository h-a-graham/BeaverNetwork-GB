library(sf)
library(terra)
library(dplyr)

counties <- read_sf('QGIS/map_data/Eng_Wales_Counties.gpkg') %>%
   filter(ctyua19nm=='Cornwall')

corn <- rast('bfi_out/Cornwall_Out/bhi_CORN.tif')

corn_crop <- terra::crop(corn, counties)

plot(corn_crop)

terra::writeRaster(corn_crop, 'bfi_out/Cornwall_Out/bhi_CORN_crop.tif')