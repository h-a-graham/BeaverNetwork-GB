# function to use gdal warp approach
warp_method <- function(ras.list, file_name){
    
    if (class(ras.list[[1]])=='character') {
      src_list <- as.character(ras.list)
    } else {
      src_list <- lapply(ras.list, FUN=function(x) terra::sources(x[[1]])[,1]) %>%
        as.character()
    }
    
    sf::gdal_utils(util = "warp",
                   source = src_list,
                   destination = file_name,
                   options = c("-co", "COMPRESS=LZW"))
    
    message('warp worked!')
    return(file_name)

}