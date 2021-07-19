
stars_rasterize(sf_obj, os_grid, .res){
  
  target_box <- sf::st_bbox(os_grid)
  ras_template <- stars::st_as_stars(target_box,
                                     dx = .res, dy = .res, values = NA_real_,
                                     crs = st_crs(os_grid))
  
  out <-stars::st_rasterize(sf_obj, ras_template, 
                            options = c("ALL_TOUCHED=TRUE")) %>%
    st_as_stars()
  
  stars::write_stars(out, 'test_outs/stars_buff_rivs_test.tif', type='Byte')
  
}