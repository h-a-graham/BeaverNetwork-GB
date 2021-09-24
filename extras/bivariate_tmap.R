# Header ------------------------------------------------------------------
# Bivariate choropleth map in R
# using tmap
#
# Bivariate color schemes
# http://www.joshuastevens.net/cartography/make-a-bivariate-choropleth-map/
#
# Author: Stefano De Sabbata
# Date: 23 November 2018

library(sp)
library(spdep)
library(tmap)
library(classInt)
library(grid)
library(gridExtra)
library(lattice)


# Color scheme ------------------------------------------------------------
biv_col_pals <- function(biv_palette){
  if (biv_palette=='BlueOrange') {
    bvColors <- c("#FFFFFF","#FAB186","#F3742D",
                  "#97D0E7","#B0988C","#AB5F37",
                  "#18AEE5","#407B8F","#5C473D")
  } else if (biv_palette=='BlueRed'){
    bvColors <- c("#e8e8e8","#e4acac","#c85a5a",
                  "#b0d5df","#ad9ea5","#985356",
                  "#64acbe","#627f8c","#574249")
  } else if (biv_palette=='GreenPurple'){
    bvColors <- c("#f3f3f3","#c2f0ce","#8ae1ae",
                  "#eac5dd","#9ec5d3","#7ec5b1",
                  "#e6a2d0","#bb9fce","#7a8eae")
  } else stop("I don't have that palette!!!!!")
  
  return(bvColors)
}

# Print bivariate map -----------------------------------------------------
# The function below calls the function that creates the map
# then adds a square legend and prints the plot

bivariate_choropleth <- function (

    # Function parameters
    bivmap_dataset,         # A SpatialPoligonDataFrame
    bivmap_vars,            # A vector of characters containing the name of the two variables
    bivmap_labels=NA,       # A vector of characters containing the labels for the two variables, to use in the legend
    bivmap_style='quantile',# Classification type for the bins
    bivmap_scale=FALSE,      # Use a scale bar
    basemap=NULL,
    bm_alpha = 0.5,
    scale_pos=c("left", "top"),
    northarrow = TRUE,
    north_pos=c("right", "top"),
    poly_alpha=1,
    biv_palette ='BlueOrange'
  ) {
  
  bvColors <-biv_col_pals(biv_palette)
  
  # Create the bivatiate map
  bivmap <- get_bivariate_choropleth(
    # Passs parameters on
    # except labels
    bivmap_dataset,
    bivmap_vars,
    bivmap_style,
    bivmap_scale,
    basemap=basemap,
    bm_alpha = bm_alpha,
    scale_pos=scale_pos,
    northarrow = northarrow,
    north_pos=north_pos,
    poly_alpha=poly_alpha,
    bvColors=bvColors
  )
  
  if (is.na(bivmap_labels)){
    bivmap_labels <- bivmap_vars
  }
  
  # Print map
  suppressWarnings(print( bivmap ))
  
  # Create the square legend
  vp <- viewport(x=.1, y=.85, width=.3, height=.3, angle = 0) # change angle for diamond but labelling becomes a bit weird...
  pushViewport(vp)
  # grid.multipanel(newpage = FALSE)
  print(levelplot(
    matrix(1:9, nrow=3), 
    axes=FALSE, 
    col.regions=bvColors,
    xlab=list(label=bivmap_labels[1],cex=0.6, fontfamily='serif'), 
    ylab=list(label=bivmap_labels[2],cex=0.6,fontfamily='serif'), 
    cuts=8, 
    colorkey=FALSE,
    scales=list(draw=0)),
    newpage=FALSE)
  
  # Pop viewport
  popViewport()
}



# Create bivariate map ----------------------------------------------------
# This function actually creates the bivariate map using tmap

get_bivariate_choropleth <- function (
  
  # Function parameters
  bivmap_dataset,         # A SpatialPoligonDataFrame
  bivmap_vars,            # A vector of characters containing the name of the two variables
  bivmap_style='quantile',# Classification type for the bins
  bivmap_scale=FALSE ,     # Use a scale bar
  basemap=NULL,
  bm_alpha = 0.5,
  scale_pos=c("left", "top"),
  northarrow = TRUE,
  north_pos=c("right", "top"),
  poly_alpha=1,
  bvColors='BlueOrange'
) {
  
  
  # Extract the two specified colums
  # excluding rows with na and infinite values
  #bivmap_sdf <- bivmap_dataset[
  #  !is.na(bivmap_dataset@data[, bivmap_vars[1]]) &
  #    !is.na(bivmap_dataset@data[, bivmap_vars[2]]) &
  #    !is.infinite(bivmap_dataset@data[, bivmap_vars[1]]) &
  #    !is.infinite(bivmap_dataset@data[, bivmap_vars[2]])
  #  ,bivmap_vars]
  bivmap_sdf <- bivmap_dataset[, bivmap_vars]
  
  # Renaming the variables to simplify the code below
  colnames(bivmap_sdf@data) <- c("xvar","yvar")
  
  # Create the 3-class categorization per each variable
  bivmap_sdf$xcat <- findCols(classIntervals( bivmap_sdf$xvar, n=3, bivmap_style))
  cat(bivmap_vars[1], "breaks (x-axis):\n")
  print(classIntervals( bivmap_sdf$xvar, n=3, bivmap_style))
  #
  bivmap_sdf$ycat <- findCols(classIntervals( bivmap_sdf$yvar, n=3, bivmap_style))
  cat(bivmap_vars[2], "breaks (y-axis):\n")
  print(classIntervals( bivmap_sdf$yvar, n=3, bivmap_style))
  
  # Combine the above into one 9-class categorization
  bivmap_sdf$bicat <- bivmap_sdf$xcat + (3 * (bivmap_sdf$ycat - 1))
  
  bivmap_sdf$bicol <- bvColors[bivmap_sdf$bicat]
  bivmap_sdf$bicol <- ifelse(is.na(bivmap_sdf$bicol), "#bdbdbd", bivmap_sdf$bicol)
  
  # Double-check created datasets if necessary
  #View(bivmap_sdf@data)
  #View(cbind(bivmap_sdf@data, bivmap_dataset@data))
  
  # Create the map
  if (!is.null(basemap)) {
    bivmap <- tm_shape(basemap, bbox=st_bbox(bivmap_sdf))+
      tm_rgb(alpha=bm_alpha,legend.show = FALSE)+
      tm_shape(bivmap_sdf) + 
      # Fill
      tm_polygons(
        "bicol", alpha=poly_alpha) +
      # Remove frame
      tm_layout(frame=T) +
      # Add rhe legend
      tm_legend(scale=0.75)

    if (isTRUE(northarrow)){
      bivmap <- bivmap + tm_compass(position=north_pos)
    }  
  } else {
    bivmap <- 
      tm_shape(bivmap_sdf) + 
      # Fill
      tm_polygons(
        "bicol", alpha=poly_alpha) +
      # Remove frame
      tm_layout(frame=T) +
      # Add rhe legend
      tm_legend(scale=0.75) +

    if (isTRUE(northarrow)){
      bivmap <- bivmap + tm_compass(position=north_pos)
    }  
  }

  
  if (bivmap_scale) {
    bivmap <- bivmap  +
      # Add scale bar
      tm_scale_bar(
        position=scale_pos)
  }
  
  # Return bivariate map
  bivmap 

}