# ---- ghs-pop-map ----

library(sf)
library(terra)
library(leaflet)
library(dplyr)

# GHSL tile schema URL
tile_schema_url <- "/vsizip/vsicurl/https://ghsl.jrc.ec.europa.eu/download/GHSL_data_4326_shapefile.zip/WGS84_tile_schema.shp"
tiles_sf <- st_read(tile_schema_url, quiet = TRUE)
# Kampala coordinates and buffer
kampala_lon <- 32.5816
kampala_lat <- 0.3152
kampala_pt <- st_sfc(st_point(c(kampala_lon, kampala_lat)), crs = 4326)
buffer_radius <- 5000 # 5 km
kampala_buffer <- st_buffer(kampala_pt, buffer_radius)
kampala_buffer_vect <- terra::ext(vect(kampala_buffer))

# Find intersecting tiles
tiles_intersect <- tiles_sf[st_intersects(tiles_sf, kampala_buffer, sparse = FALSE), ]
tile <- tiles_intersect$tile_id

# Function to load, crop, mask, and convert raster for a given resolution
get_pop_sf <- function(res = "30ss") {
  pop_year <- 2025
  crs <- 4326
  base <- "https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/"
  folder <- paste0("GHS_POP_E",pop_year,"_GLOBE_R2023A_",crs,"_",res)
  version <- "V1_0"
  name <- paste0(folder,"_",version,"_",tile)
  virtual_path_global <- paste0("/vsizip//vsicurl/", base,
                                folder, "/V1-0/tiles/",
                                name, ".zip/", name, ".tif")
  ghs_pop_raster <- terra::rast(virtual_path_global)
  ghs_pop_cropped <- terra::crop(ghs_pop_raster, kampala_buffer_vect)
  ghs_pop_masked <- terra::mask(ghs_pop_cropped, kampala_buffer_vect)
  pop_polygons <- terra::as.polygons(ghs_pop_masked)
  pop_sf <- sf::st_as_sf(pop_polygons)
  return(pop_sf)
}

# Process both resolutions
pop_sf30ss <- get_pop_sf("30ss")
pop_sf3ss <- get_pop_sf("3ss")

# Get the name of the population column for each dataset
# This is more robust than assuming it's the first column
pop_col30ss <- names(pop_sf30ss)[1]
pop_col3ss <- names(pop_sf3ss)[1]

# Create color palettes
pal30ss <- colorNumeric(palette = "viridis", domain = pop_sf30ss[[pop_col30ss]],
                        na.color = "transparent")
pal3ss <- colorNumeric(palette = "viridis", domain = pop_sf3ss[[pop_col3ss]],
                       na.color = "transparent")

# Create the Leaflet map
leaflet() %>%
  addTiles(group = "OSM") %>%
  addPolygons(data = pop_sf30ss,
              fillColor = ~pal30ss(get(pop_col30ss)),
              color = "#BDBDC3", weight = 1, opacity = 0.5, fillOpacity = 0.5,
              popup = ~paste("Population:", get(pop_col30ss)),
              group = "30 arc sec (~ 1 km)") %>%
  addPolygons(data = pop_sf3ss,
              fillColor = ~pal3ss(get(pop_col3ss)),
              color = "#BDBDC3", weight = 1, opacity = 0.5, fillOpacity = 0.5,
              popup = ~paste("Population:", get(pop_col3ss)),
              group = "3 arc sec (~ 90 m)") %>%
  addLayersControl(
    overlayGroups = c("30 arc sec (~ 1 km)", "3 arc sec (~ 90 m)"),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  addLegend(pal = pal30ss, values = pop_sf30ss[[pop_col30ss]],
            title = "Population (30 arc sec)", group = "1 km",
            position = "bottomright") %>%
  addLegend(pal = pal3ss, values = pop_sf3ss[[pop_col3ss]],
            title = "Population (3 arc sec)", group = "100 m",
            position = "bottomright") %>%
  hideGroup("3 arc sec (~ 90 m)") # Hide the 3ss layer by default
