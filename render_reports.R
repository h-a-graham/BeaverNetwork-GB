library(here)

if (!dir.exists('extras/Regional_WT_reports')) {
  dir.create('extras/Regional_WT_reports') 
  }

regions <- c('South West')
beavNet<- c("BEAVNET")
CountySumm<- c("Csum")
WatBods<- c("WATBODS")
BHI<-c( "BHI")

rmarkdown::render(input = file.path(here(),"extras/regional_tech_report.Rmd"), 
                    output_file =file.path(here(), sprintf("extras/Regional_WT_reports/reional_tech_report_%s.pdf", regions)),
                    params = list(set_region = regions,
                                  set_beavNet= "BEAVNET",
                                  set_CountySumm= "Csum",
                                  set_WatBods= "WATBODS",
                                  set_BHI= "BHI"))

  
  rmarkdown::render(input = file.path(here(),"extras/table_test.Rmd"), 
                    output_file =file.path(here(), sprintf("extras/table_test_%s.pdf", regions)),
                    params = list(set_region = regions))
  