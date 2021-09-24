# Import function
library(dplyr)
source("extras/bivariate_tmap.R")

bdc_join <-read_sf('bdc_out/BeavNet_CountySumm_SouthWest.gpkg') 
bdc_joinSP <- as(bdc_join, "Spatial")


bdc_osm <- get_tiles(bdc_join, crop = TRUE, zoom = 5, 
                     provider=  "Stamen.TerrainBackground",
                     apikey = '***')

# Option 1
# Plot bivariate choroplet map (including legend)

bivariate_choropleth(bdc_joinSP, c("Est_DamD", "BFI40_P_PR"),
                     basemap=bdc_osm, bm_alpha=0.7, bivmap_scale=T, 
                     bivmap_labels=c('Potential dam density', 'Habitat Suitability'),
                     poly_alpha=0.9, scale_pos = c('right', 'bottom')) 



bdc_join2 <-bdc_join %>%
  mutate(p_less_mod = BFI40_P_UN+BFI40km_LO+BFI40km_MO )
  
bdc_joinSP2 <- as(bdc_join2, "Spatial")


bivariate_choropleth(bdc_joinSP2, c("Est_DamD", "p_less_mod"),
                     basemap=bdc_osm, bm_alpha=0.7, bivmap_scale=T, 
                     bivmap_labels=c('Potential dam density', '% of Channel <=Moderate suitability'),
                     poly_alpha=0.9, scale_pos = c('right', 'bottom'),
                     biv_palette = 'BlueRed') 
