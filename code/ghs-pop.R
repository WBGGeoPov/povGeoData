# Install the terra package if you haven't already
# install.packages("terra")

# Load the terra library
library(terra)

# Define parameters
pop_year <- 2025 # population year, 1970-2030 (five year intervals)
crs <- 4326 # coordinate reference system, 4326 = WGS84 or 54009 = Mollweide
res <- "30ss" # spatial resolution
    # for 4326/WGS84: 3ss = 3 arc seconds (~90 m) or 30ss = 30 arc seconds (~1 km)
    # for 54009/Mollweide: 100 = 100 m or 1000 = 1 km
tile <- "R6_C11"  # Tile ID
    # see https://human-settlement.emergency.copernicus.eu/download.php?ds=pop

# Construct the virtual path to the raster file
base <- "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/"
folder <- paste0("GHS_POP_E",pop_year,"_GLOBE_R2023A_",crs,"_",res)
version <- "V1_0"
name <- paste0(folder,"_",version,"_",tile)

virtual_path <- paste0("/vsizip//vsicurl/", base,
                       folder, "/V1-0/tiles/",
                       name, ".zip/", name, ".tif")

# Use the rast() function to open the raster file
# This will download the necessary parts of the file without saving the whole zip to disk
ghs_pop_raster <- rast(virtual_path)

# Print the raster object's summary to verify it's loaded correctly
print(ghs_pop_raster)

# You can now work with the raster object, for example, plot it
# Note: Plotting might take a moment as it needs to download the data
plot(ghs_pop_raster)

## Save to disk (not run)
# writeRaster(ghs_pop_raster, "FILEPATH.tif")

# Virtual path for global files !! this is a large file to download
virtual_path_global <- paste0("/vsizip//vsicurl/", base, folder, "/V1-0/",
                              folder,"_",version, ".zip/",
                              folder,"_",version, ".tif")

ghs_pop_raster_global <- rast(virtual_path_global)

print(ghs_pop_raster_global)
#  we have not downloaded the data yet, only checked the metadata

## crop remote global data to a specific area of interest (not run)
# aoi <- ext(77, 78, 38, 39) # order = xmin, xmax, ymin, ymax
# ghs_pop_raster_aoi <- crop(ghs_pop_raster_global, aoi)
# ghs_pop_raster_aoi
# plot(ghs_pop_raster_aoi)
