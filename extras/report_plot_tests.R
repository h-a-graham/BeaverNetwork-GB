
library(sf)
library(tmap)
library(stars)
library(maptiles)
library(dplyr)
library(tidyr)

bdc <- read_sf(file.path(here::here(),'bdc_out/BeaverNetwork_SouthWest.gpkg'))

bdc_osm <- get_tiles(bdc, crop = TRUE, zoom = 8)

tm_shape(bdc_osm, bbox=st_bbox(bdc))+
  tm_rgb(alpha=0.4,legend.show = FALSE)+
tm_shape(bdc,)+
  tm_lines( col='BDC', lwd=0.6, style = 'fixed', breaks = c(0,0.1,1,4,15,32),
            palette=c('black','orange','yellow','green','blue'),
            labels = c('None: 0', 'Rare: 0-1','Occasional: 1-4', 
                       'Frequent: 4-15', 'Pervasive: 15-30'),
            title.col = 'Beaver Dam Capaity (dams/km)')+
  tm_compass(position=c("right", "top")) +
  tm_scale_bar(position=c("right", "beaver")) +
  tm_layout(legend.title.fontfamily='mono',
            legend.text.fontfamily='mono')
  

bhi <- stars::read_stars(file.path(here::here(),'bfi_out/SouthWest_Out/bhi_SouthWest.tif'))

# tm_shape(bdc_osm)+
#   tm_rgb(alpha=0.4,legend.show = FALSE)+
tm_shape(bhi) +
  tm_raster(palette='-viridis',
            labels = c('Unsuitable: 0-1', 'Barely: 2','Moderate: 3', 
                       'Suitable: 4', 'Highly Suitable: 5'),
            title = 'Beaver Forage Index') +
  tm_compass(position=c("right", "top")) +
  tm_scale_bar(position=c("right", "bottom"))+
  tm_layout(legend.title.fontfamily='serif',
            legend.text.fontfamily='serif')





bdc_join <- read_sf('bdc_out/BeavNet_CountySumm_SouthWest.gpkg')

bdc_LongJ <- bdc_join %>%
  select(county, BDC_MEAN, BDC_P_PERV , BFI40_P_PR, Est_DamD) %>%
  pivot_longer(c('BDC_MEAN', 'BDC_P_PERV' , 'BFI40_P_PR', 'Est_DamD'))

tm_shape(bdc_LongJ) +
  tm_polygons(col='value', pal='viridis', alpha=0.7,title = "") +
  tm_facets(by="name", free.scales=T) +
  tm_layout(panel.show = TRUE,
            panel.labels = c("mean BDC (dams/km)", "% Pervasive Dam Capacity", 
                             "% Preferred Habitat", 
                             'Estimated Dam Density(dams/km)'))+
  tm_compass(position=c("right", "top")) +
  tm_scale_bar(position=c("right", "bottom"))
  

#------------ tables... ----------------------------------
library(tibble)
library(gt)

Summ_poly_desc <- tibble::tibble(
  `Variable Short Name` =
    c('BDC_TOT','BDC_MEAN','BDC_STD',
      'BDC_P_NONE', 'BDC_P_RARE','BDC_P_OCC','BDC_P_FREQ','BDC_P_PERV',
      'BDCkm_NONE','BDCkm_RARE','BDCkm_OCC','BDCkm_FREQ','BDCkm_PERV',
      'BFI40_P_UN','BFI40_P_LO','BFI40_P_MO','BFI40_P_HI','BFI40_P_PR',
      'BFI40km_UN','BFI40km_LO','BFI40km_MO','BFI40km_HI','BFI40km_PR' ,
      'Est_nDam','Est_nDamLC','Est_nDamUC',
      'Est_DamD', 'Est_DamDLC','Est_DamDUC', 'TOT_km'
      ),
  `Variable Full Name` = 
    c('Total Beaver Dam Capacity (n dams)', 
      'Average Beaver Dam Capacity (dams/km), weighted by reach length',
      'Beaver Dam Capacity standard deviation (dams/km), weighted by reach length.',
      'Proportion of river network in ‘None’ BDC category (%)',
      'Proportion of river network in ‘Rare’ BDC category (%)',
      'Proportion of river network in ‘Occasional’ BDC category (%)',
      'Proportion of river network in ‘Frequent’ BDC category (%)',
      'Proportion of river network in ‘Pervasive’ BDC category (%)',
      'Length of river network in ‘None’ BDC category (km)',
      'Length of river network in ‘Rare’ BDC category (km)',
      'Length of river network in ‘Occasional’ BDC category (km)',
      'Length of river network in ‘Frequent’ BDC category (km)',
      'Length of river network in ‘Pervasive’ BDC category (km)',
      'Proportion of river network with ‘unsuitable’ beaver forage (%)',
      'Proportion of river network with ‘low suitability’ beaver forage (%)',
      'Proportion of river network with ‘moderate suitability’ beaver forage (%)',
      'Proportion of river network with ‘high suitability’ beaver forage (%)',
      'Proportion of river network with ‘preferred’ beaver forage (%)',
      'Length of river network with ‘unsuitable’ beaver forage (km)',
      'Length of river network with ‘low suitability’ beaver forage (km)',
      'Length of river network with ‘moderate suitability’ beaver forage (km)',
      'Length of river network with ‘high suitability’ beaver forage (km)',
      'Length of river network with ‘preferred’ beaver forage (km)',
      'Estimated Number of dams',
      'Estimated Number of dams (Lower 95% Confidence limit)',
      'Estimated Number of dams (Upper 95% Confidence limit)',
      'Estimated dam density',
      'Estimated dam density (Lower 95% Confidence limit)',
      'Estimated dam density (Upper 95% Confidence limit)',
      'Total length of river network (km)'
      ),
  Description =
    c('The Beaver dam Capacity of the region (n dams). For areas larger than a single beaver territory, it would not be expected to see a system at (or even close to) dam capacity. For estimating dam numbers at or greater than the catchment scale use ‘Est_nDam’.',
      'The average Beaver Dam Capacity across the region. Reach length is used as a weighting as reach lengths vary.',
      'The standard deviation of Beaver Dam Capacity within the region. Provides an understanding of BDC variability. Weighted by reach length.',
      'The percentage of the river network, within the area of interest, which has no capacity to support dams.',
      'The percentage of the river network, within the area of interest, which has the capacity to support 0-1 dams/km.',
      'The percentage of the river network, within the area of interest, which has the capacity to support 1-4 dams/km.',
      'The percentage of the river network, within the area of interest, which has the capacity to support 4-15 dams/km.',
      'The percentage of the river network, within the area of interest, which has the capacity to support 15-30 dams/km.',
      'The length of the river network, within the area of interest, which has no capacity to support dams.',
      'The length of the river network, within the area of interest, which has the capacity to support 0-1 dams/km.',
      'The length of the river network, within the area of interest, which has the capacity to support 1-4 dams/km.',
      'The length of the river network, within the area of interest, which has the capacity to support 4-15 dams/km.',
      'The length of the river network, within the area of interest, which has the capacity to support 15-30 dams/km.',
      'Percentage of river network, within the area of interest, where the mean of the upper 50% of BFI raster cell values, within 40m of the bank, is <= 1.',
      'Percentage of river network, within the area of interest, where the mean of the upper 50% of BFI raster cell values, within 40m of the bank, is 1 > 2.',
      'Percentage of river network, within the area of interest, where the mean of the upper 50% of BFI raster cell values, within 40m of the bank, is 2 > 3.',
      'Percentage of river network, within the area of interest, where the mean of the upper 50% of BFI raster cell values, within 40m of the bank, is 3 > 4.',
      'Percentage of river network, within the area of interest, where the mean of the upper 50% of BFI raster cell values, within 40m of the bank, is 4 > 5.',
      'Length of river network, within the area of interest, where the mean of the upper 50% of BFI raster cell values, within 40m of the bank, is <=1.',
      'Length of river network, within the area of interest, where the mean of the upper 50% of BFI raster cell values, within 40m of the bank, is 1 > 2.',
      'Length of river network, within the area of interest, where the mean of the upper 50% of BFI raster cell values, within 40m of the bank, is 2 > 3.',
      'Length of river network, within the area of interest, where the mean of the upper 50% of BFI raster cell values, within 40m of the bank, is 3 > 4.',
      'Length of river network, within the area of interest, where the mean of the upper 50% of BFI raster cell values, within 40m of the bank, is 4 > 5.',
      'The estimated number of dams that may be built, assuming that all reaches within the area of interest contain beaver activity.',
      'The lower 95% confidence limit for estimated number of dams that are likely to be built within the area of interest.',
      'The Upper 95% confidence limit for estimated number of dams that are likely to be built within the area of interest.',
      'The estimated dam density (dams/km) within the area of interest, assuming that all reaches contain beaver activity.',
      'The lower 95% confidence limit for estimated dam density (dams/km) within the area of interest.',
      'The Upper 95% confidence limit for estimated dam density (dams/km) within the area of interest.',
      'Sum of all channel lengths within are of interest.'
      ))

gt(Summ_poly_desc) %>%
  tab_header(
    title = "County Summary Stats Variable Descriptions"
  )
