library(gdalio)
library(sf)
library(dplyr)
library(readr)
source('R/set_up_gdalio.R')



os_gridSX <- 'C:/HG_Projects/Hugh_BDC_Files/GB_Beaver_modelling/OS_Grids/OSGB_Grid_100km.shp' %>%
  st_read() %>%
  filter(TILE_NAME=='SX')


set_up_gdalio(os_gridSX, 10)


# write_lines('<GDAL_WMS>
#             <Service name=\"AGS\">
#             <ServerUrl>http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StateCityHighway_USA/MapServer</ServerUrl>
#             <BBoxOrder>xyXY</BBoxOrder>
#             <SRS>3857</SRS>
#             </Service>
#             <DataWindow><UpperLeftX>-20037508.34</UpperLeftX><UpperLeftY>20037508.34</UpperLeftY><LowerRightX>20037508.34</LowerRightX><LowerRightY>-20037508.34</LowerRightY><SizeX>512</SizeX><SizeY>512</SizeY></DataWindow>
#             </GDAL_WMS>', DTM_2020)

DTM_2020 <- tempfile(fileext = ".xml")
write_lines('<GDAL_WMS>
            <Service name=\"AGS\">
            <ServerUrl>https://environment.data.gov.uk/image/rest/services/SURVEY/LIDAR_Composite_1m_DTM_2020_Elevation/ImageServer</ServerUrl>
            <BBoxOrder>xyXY</BBoxOrder>
            <SRS>27700</SRS>
            </Service>
            <DataWindow><UpperLeftX>80000</UpperLeftX><UpperLeftY>665000</UpperLeftY><LowerRightX>660000</LowerRightX><LowerRightY>0</LowerRightY><SizeX>580000</SizeX><SizeY>665000</SizeY></DataWindow>
            </GDAL_WMS>', DTM_2020)


n <-'https://environment.data.gov.uk/image/rest/services/SURVEY/LIDAR_Composite_1m_DTM_2020_Elevation/ImageServer?f=pjson'

# gdalio::gdalio_set_default_grid()
set_up_gdalio(os_gridSX, 10)
r <- gdalio::gdalio_data(DTM_2020)

r2 <- gdalio_matrix(n)
r3 <- gdalio_to_terra(r2)
r3
terra::plot(r3)

gdalio_base <- function(dsn, ...) {
  v <- gdalio_data(dsn, ...)
  g <- gdalio_get_default_grid()
  list(x = seq(g$extent[1], g$extent[2], length.out = g$dimension[1]), 
       y = seq(g$extent[3], g$extent[4], length.out = g$dimension[2]), 
       z = matrix(v[[1]], g$dimension[1])[, g$dimension[2]:1])
}
xyz <- gdalio_base(DTM_2020)
image(xyz)