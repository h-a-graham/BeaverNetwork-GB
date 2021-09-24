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


bdc_join <- bdc_aoi %>% 
  st_centroid() %>%
  st_join(counties,prepared=TRUE) %>%
  group_by(ctyua19nm) %>%
  # Calculate all summary metrics for each polygon.
  summarise(BDC_TOT = sum(BDC),
            BDC_MEAN = weighted.mean(BDC, Length_m),
            BDC_STD = sqrt(Hmisc::wtd.var(BDC, Length_m)),
            
            BDC_P_NONE = sum(BDC_cat == "None")/n()*100,
            BDC_P_RARE = sum(BDC_cat == "Rare")/n()*100,
            BDC_P_OCC = sum(BDC_cat == "Occasional")/n()*100,
            BDC_P_FREQ = sum(BDC_cat == "Frequent")/n()*100,
            BDC_P_PERV = sum(BDC_cat == "Pervasive")/n()*100,
            BDCkm_NONE = sum(Length_m[BDC_cat == "None"])/1000,
            BDCkm_RARE = sum(Length_m[BDC_cat == "Rare"])/1000,
            BDCkm_OCC = sum(Length_m[BDC_cat == "Occasional"])/1000,
            BDCkm_FREQ = sum(Length_m[BDC_cat == "Frequent"])/1000,
            BDCkm_PERV = sum(Length_m[BDC_cat == "Pervasive"])/1000,
            
            BFI40_P_UN = sum(BFI_cat == "Unsuitable")/n()*100,
            BFI40_P_LO = sum(BFI_cat == "Low")/n()*100,
            BFI40_P_MO = sum(BFI_cat == "Moderate")/n()*100,
            BFI40_P_HI = sum(BFI_cat == "High")/n()*100,
            BFI40_P_PR = sum(BFI_cat == "Preferred")/n()*100,
            BFI40km_UN = sum(Length_m[BFI_cat=='Unsuitable'])/1000,
            BFI40km_LO = sum(Length_m[BFI_cat=='Low'])/1000,
            BFI40km_MO = sum(Length_m[BFI_cat=='Moderate'])/1000,
            BFI40km_HI = sum(Length_m[BFI_cat=='High'])/1000,
            BFI40km_PR = sum(Length_m[BFI_cat=='Preferred'])/1000,
            
            Est_nDam = sum(Est_nDam),
            Est_nDamLC = sum(Est_nDamLC),
            Est_nDamUC = sum(Est_nDamUC),
            Est_DamD = sum(Est_nDam)/(sum(Length_m)/1000),
            Est_DamDLC = sum(Est_nDamLC)/(sum(Length_m)/1000),
            Est_DamDUC = sum(Est_nDamUC)/(sum(Length_m)/1000),
            
            TOT_km = sum(Length_m)) %>%
  
  filter(!is.na(ctyua19nm)) %>%
  st_drop_geometry() %>%
  right_join(counties %>% select(ctyua19nm), by='ctyua19nm') %>%
  rename(county=ctyua19nm)%>%
  st_as_sf()

st_write(bdc_join, 'bdc_out/BeavNet_CountySumm_SouthWest.gpkg', delete_dsn =T)
st_write(bdc_join, 'bdc_out/BeavNet_CountySumm_SouthWest.shp', delete_dsn =T)
