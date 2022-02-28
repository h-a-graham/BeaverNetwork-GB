# Render report...

render_regional_report <- function(report, region, beavNet, CountySumm, WatBods, BHI,
                                   BHI1km,out_dir, file_ab, scale_pos, biv_leg,
                                   WB_names='EA Water Body'){
  f_path <- file.path(out_dir, sprintf("reional_tech_report_%s.pdf", region))
  if (file.exists(f_path)) file.remove(f_path)
  message(sprintf("Rendering %s report...", region))
  
  rmarkdown::render(input = report, 
                    output_file = f_path,
                    params = list(set_region = region,
                                  set_beavNet= beavNet,
                                  set_CountySumm= file.path(here(),CountySumm),
                                  set_WatBods= file.path(here(),WatBods),
                                  set_BHI= BHI,
                                  set_BHI1km = BHI1km,
                                  set_file_ab = file_ab,
                                  set_leg_pos = scale_pos,
                                  set_biv_leg =biv_leg,
                                  set_WB_names = WB_names))
  
  
}


