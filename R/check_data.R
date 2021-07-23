# function to check that all data is downloaded - most cannot be automated.

check_data <- function(data_paths){
  
  check_path <- function(path, .id){
    
    if (isTRUE(file.exists(path)|dir.exists(path))){
      return(TRUE)
    } else {
      warning(paste('The Path for',.id, 'is broken...'))
      return(FALSE)
    }
  }
  
  if (FALSE %in% purrr::imap(data_paths, ~check_path(.x, .y))){
    message('There is an issue with the data sources. Check warnings for incorrect
paths. If you need to download the data, Here are the download links: 
from the following links:
CEH LCM 2019: "https://catalogue.ceh.ac.uk/documents/643eb5a9-9707-4fbb-ae76-e8e53271d1a0"
Copernicus TCD 2018: "https://land.copernicus.eu/pan-european/high-resolution-layers/forests/tree-cover-density/status-maps/tree-cover-density-2018"
National Forest Inventory 2018: https://data-forestry.opendata.arcgis.com/datasets/d3d7bfba1cba4a3b83a948f33c5777c0_0/explore 
OS vectorMap District: https://osdatahub.os.uk/downloads/open/VectorMapDistrict')
    stop("Problem with input data file paths...")
  } else {
    message('Data is good!')
  }
  
  return(data_paths)
  
}