summarise_BeavNet <- function(bdc_aoi, polys, group_var){

  bdc_join <- bdc_aoi %>% 
    st_centroid() %>%
    st_join(polys,prepared=TRUE) %>%
    group_by(!!sym(group_var)) %>%
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
    
    filter(!is.na(group_var)) %>%
    st_drop_geometry() %>%
    right_join(polys %>% select(!!sym(group_var)), by=group_var) %>%
    rename(county=group_var)%>%
    st_as_sf()

  
}