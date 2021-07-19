# ras_template <- function(terr_ras, .res){
#   res_diff <- terra::res(terr_ras)[1]/.res
#   
#   r <- rast(nrows=nrow(terr_ras)*res_diff, ncols=ncol(terr_ras)*res_diff, 
#             xmin=ext(terr_ras)[1], xmax=ext(terr_ras)[2], 
#             ymin=ext(terr_ras)[3], ymax=ext(terr_ras)[4], 
#             crs=terra::crs(terr_ras))
#   return(r)
# }

rasterize_nfi <- function(lcm_ter, .nfi){

    fasterize_terra(.nfi, lcm_ter, 'woodland')
  
}

rasterize_vmd <- function(lcm_ter, .vmd){
 
    fasterize_terra(.vmd, lcm_ter, 'water')
  
}

rasterize_water_buff <- function(bfi, os_grid, os_orn, vmd){
  
  os_orn <-os_orn %>%
    st_intersection(., os_grid)
  
  vmd <- vmd %>%
    st_intersection(., os_grid)
  
  bind_water <- bind_rows(os_orn, vmd) %>%
    st_buffer(100) %>%
    select(geom)%>%
    st_cast('POLYGON')%>%
    mutate(water=1)
  
  bw <- fasterize_terra(bind_water, bfi, 'water')
  return(bw)
}
