# Install packages if you haven't already
# install.packages("terra")
# install.packages("sf")
# install.packages("exactextractr")
# install.packages("ggplot2")

# Load packages
library(terra)
library(sf)
library(exactextractr)
library(ggplot2)

#------------------------------------------------------------------------------#
# 1. Calculate zonal statistics (mean of cell values)

# Create a sample raster layer
# Create a 10x10 raster with values from 1 to 100
raster_data <- rast(matrix(1:100, nrow = 10, ncol = 10))
# Set the extent and coordinate reference system (CRS)
ext(raster_data) <- c(0, 10, 0, 10)
crs(raster_data) <- "EPSG:4326"

# Create a sample polygon (sf) object
# Define two polygons
poly1 <- st_polygon(list(rbind(c(1, 1), c(4, 1), c(4, 4), c(1, 4), c(1, 1))))
poly2 <- st_polygon(list(rbind(c(6, 6), c(9, 6), c(9, 9), c(6, 9), c(6, 6))))

# Create an sf object with a data frame
polygons_sf <- st_as_sf(
  data.frame(
    id = c("A", "B"),
    geometry = st_sfc(poly1, poly2, crs = "EPSG:4326")
  )
)

# Plot the raster and vector data together
raster_df <- as.data.frame(raster_data, xy = TRUE)
colnames(raster_df)[3] <- "value"

plot <- ggplot() +
  geom_raster(data = raster_df, aes(x = x, y = y, fill = value)) +
  geom_sf(data = polygons_sf, fill = NA, color = "red", linewidth = 1) +
  scale_fill_viridis_c() +
  coord_sf(crs = "EPSG:4326") +
  labs(
    title = "Raster and Vector Data Overlay",
    x = "Longitude",
    y = "Latitude",
    fill = "Value"
  ) +
  theme_minimal()

print(plot)

# Use exact_extract to find the mean value of the raster within each polygon
zonal_stats <- exact_extract(raster_data, polygons_sf, "mean")

# Combine results and print
# The result is a vector, which can be added as a new column to the polygon data
polygons_sf$mean_value <- zonal_stats
print("Polygons with calculated mean raster value:")
print(polygons_sf)

#------------------------------------------------------------------------------#
# 2. Calculate multiple statistics at once
zonal_stats_multiple <- exact_extract(raster_data,
                                      polygons_sf,
                                      c("min", "max", "mean", "count"),
                                      append_cols = "id")
print("Polygons with multiple zonal statistics:")
print(zonal_stats_multiple)

#------------------------------------------------------------------------------#
# 3. Calculate weighted zonal statistics

# Create a second raster for WEIGHTS
# Let's create a weight raster where weights increase from bottom-left to top-right
# This will give more importance to cells with higher values in our value_raster
weight_matrix <- matrix(1:100, nrow = 10, ncol = 10, byrow = TRUE)
weight_raster <- rast(weight_matrix)
ext(weight_raster) <- c(0, 10, 0, 10)
crs(weight_raster) <- "EPSG:4326"

value_raster <- raster_data # use existing raster for values

# Name the layers in the rasters for clarity in the output
names(value_raster) <- "value"
names(weight_raster) <- "weight"

# Calculate Weighted Zonal Statistics
# To calculate a weighted mean, we provide the weight_raster to the `weights` argument.
# We also name the summary operation to make the output column clear.
zonal_stats_weighted <- exact_extract(
  x = value_raster,
  y = polygons_sf,
  fun = c("mean", "weighted_mean" = "mean"), # Calculate both simple and weighted mean
  weights = weight_raster,
  append_cols = "id"
)

# Print the results
print("Comparison of simple mean vs. weighted mean:")
print(zonal_stats_weighted)

#------------------------------------------------------------------------------#
# 4. Summarize categorical rasters

# Create a sample CATEGORICAL raster for land cover
# Categories: 1=Water, 2=Forest, 3=Urban
land_cover_matrix <- matrix(c(
  1, 1, 2, 2,
  1, 2, 3, 3,
  2, 2, 3, 3,
  2, 3, 3, 3
), nrow = 4, ncol = 4, byrow = TRUE)

land_cover_raster <- rast(land_cover_matrix)
ext(land_cover_raster) <- c(0, 4, 0, 4)
crs(land_cover_raster) <- "EPSG:4326"
names(land_cover_raster) <- "land_cover"

# Create a WEIGHT raster (e.g., population density)
# Let's assume population is highest in the 'Urban' areas (bottom-right)
population_matrix <- matrix(c(
  5,   5,  10,  20,
  5,  25, 100, 120,
  10,  20, 150, 180,
  10,  50, 200, 250
), nrow = 4, ncol = 4, byrow = TRUE)

population_raster <- rast(population_matrix)
ext(population_raster) <- c(0, 4, 0, 4)
crs(population_raster) <- "EPSG:4326"
names(population_raster) <- "population"

# Create a sample polygon (sf) object
# A single polygon covering a mix of land cover types
analysis_poly <- st_polygon(list(rbind(c(0.5, 0.5), c(3.5, 0.5), c(3.5, 3.5), c(0.5, 3.5), c(0.5, 0.5))))

polygons_sf <- st_as_sf(
  data.frame(
    district_id = "D1",
    geometry = st_sfc(analysis_poly, crs = "EPSG:4326")
  )
)

# Calculate both unweighted and weighted fractions
# The function will return a data frame where columns are named `weighted_fraction_<category_value>`
zonal_fractions <- exact_extract(
  x = land_cover_raster,
  y = polygons_sf,
  fun = c("frac", "weighted_frac"), # Calculate both for comparison
  weights = population_raster,
  append_cols = "district_id"
)

# Print and interpret the results
print("Land Cover Raster Categories: 1=Water, 2=Forest, 3=Urban")
print("Comparison of unweighted vs. weighted fractions:")
print(zonal_fractions)

# To make the output more readable, let's calculate the total population in the polygon
total_pop <- exact_extract(population_raster, polygons_sf, fun = "sum", append_cols = "district_id")
print(total_pop)
