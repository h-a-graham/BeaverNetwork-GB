split_grid_iter <- function(.list, .n){
  split(.list, cut(seq_along(.list), .n, labels = FALSE), drop=F)
  
}
