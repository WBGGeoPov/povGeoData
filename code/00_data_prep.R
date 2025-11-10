# prepare data and .qmd files from excel

# load functions
source("code/create_data_qmd.R")
source("code/create_methods_qmd.R")

# Excel path
excel_path <- "~/Library/CloudStorage/OneDrive-WBG/WBG Geospatial Poverty Solutions - WB Group - General/02. Work Program/Pillar 2 - Knowledge and Data Center/Repository of data and methodology/GeoPov data and methods.xlsx"

# Execute functions to create .qmd files
  # This will create .qmd files in povGeoData/data/ and povGeoData/methods/
create_data_qmd(excel_path)
create_methods_qmd(excel_path)

## Data catalog .csv
data_list <- read_excel(excel_path, sheet = "data_dev")[,1:3]
write.csv(data_list, "data/data_list.csv", row.names = FALSE)

## Method catalog .csv
methods_list <- read_excel(excel_path, sheet = "methods_dev")[,1:2]
write.csv(methods_list, "methods/methods_list.csv", row.names = FALSE)
