# targets commands for inspection and running

library(targets)

tar_edit() # opens the _targets.R file for editing

tar_manifest(fields = "command") # prints targets and commands

tar_glimpse() 

tar_visnetwork(label='time')

tar_make() # run the targets workflow

tar_make_futures()

tar_meta(fields = error, complete_only = TRUE) # show errors to help debugging.


tar_read(download_OS_grid)[[46]]# to view the results the arg is the target name....


tar_read(process_veg_tiles)[[3]]
# for dev - load these packages.
library(curl)
library(zip)
library(sf)
library(dplyr)
library(terra)
library(gdalio)
