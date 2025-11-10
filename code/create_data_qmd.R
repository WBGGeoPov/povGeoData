# install.packages(c("readxl", "glue", "stringr"))

# Load necessary libraries
library(readxl)
library(glue)
library(stringr)
library(here)

#' Create Quarto files from an Excel sheet
#'
#' This function reads an Excel file, iterates through each row, and generates
#' a .qmd file for each entry based on a predefined template.
#'
#' @param excel_path The file path to the input Excel file.
#' @param output_dir The directory where the .qmd files will be saved.
#'
#' @return Invisibly returns a vector of the created file paths.
create_data_qmd <- function(excel_path, output_dir = here("data")) {

  # 1. Read the Excel file
  tryCatch({
    data <- read_excel(excel_path, sheet = "data_dev")
  }, error = function(e) {
    stop("Failed to read the Excel file. Please check the path and file format.")
  })

  # 2. Create the output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # 3. Define a helper function to process each row
  process_row <- function(i) {
    row_data <- data[i, ]

    # Sanitize the name to create a valid filename
    file_name <- str_to_lower(row_data$name)
    file_name <- str_replace_all(file_name, "[^a-z0-9]+", "-")
    file_name <- str_replace_all(file_name, "(^-|-$)", "")
    qmd_file_path <- file.path(output_dir, paste0(file_name, ".qmd"))

    # Convert 0/1 to No/Yes for specific fields
    gmd_text <- ifelse(row_data$gmd == 1, "Yes", "No")
    s2s_text <- ifelse(row_data$s2s == 1, "Yes", "No")

    reprex_path <- paste0("../code/", row_data$reprex)
    map_label <- gsub(".R", "-map",row_data$reprex)

    # 4. Use glue to create the .qmd content from the template
    #    NOTE: We use << and >> as delimiters for glue to avoid conflicts.
    qmd_content <- glue::glue(
      '---
title: "<<row_data$name>>"
format: html
---

::: {.grid}
::: {.g-col-6}

**Name:** <<row_data$name>>

**Source:** [<<row_data$source>>](<<row_data$link>>)

**Version:** <<row_data$version>>

**Keywords:** <<row_data$keywords>>

**Type:** <<row_data$type>>

**Description:** <<row_data$description>>

**Units:** <<row_data$units>>

**Available in geocoded GMD?** <<gmd_text>>

**Available from Space2Stats?** <<s2s_text>>

:::
::: {.g-col-6}

**Map**

```{r}
#| include: false
map_path <- paste0("../code/", "<<map_label>>",".R")
if (file.exists(map_path)){knitr::read_chunk(map_path)}
```

```{r}
#| label: <<map_label>>
#| echo: false
#| message: false
#| warning: false
```
<small>
<small>
**Coordinate reference system:** <<row_data$crs>>

**Spatial coverage:** <<row_data$spatial_cov>>

**Spatial resolution:** <<row_data$spatial_res>>

**Temporal coverage:** <<row_data$temporal_cov>>

**Temporal resolution:** <<row_data$temporal_res>>

**License:** <<row_data$license>>

**Citation:** <<row_data$reference>>
</small>
</small>

:::
:::

:::::::::::: grid
::: {.g-col-lg-2 .g-col-md-1 .g-col-sm-0 .g-col-0}
:::

::::::::: {.g-col-lg-8 .g-col-md-10 .g-col-sm-12 .g-col-12}

<small>
**Usage:** <<row_data$usage>>

**Limitations:** <<row_data$limitations>>

**Examples:** <<row_data$examples>>

**Access:** <<row_data$access>>
</small>

::: panel-tabset

## R
```{r}
#| echo: false
#| output: asis
if (file.exists("<<reprex_path>>")) {
  cat("```r\n")
  try(cat(readLines("<<reprex_path>>"), sep = "\n"))
  cat("```\n")
} else {
  cat("No code\n")
}
```

## Output
```{r}
#| echo: false
#| results: hold
if (file.exists("<<reprex_path>>")) {
  try(source("<<reprex_path>>"))
} else {
  print("None")
}
```

:::

**Last updated:** <<format(as.Date(row_data$last_updated), "%m/%d/%y")>>

:::::::::

::: {.g-col-lg-1 .g-col-md-1 .g-col-sm-0 .g-col-0}
:::
::::::::::::

```{=html}
<div class="secondary-links">
  <div class="secondary-links-container">
      <div class="secondary-links-title">
      </div>
      <div class="grid">
        <div class="g-col-lg-4 g-col-md-4 g-col-sm-12">
          <ul>
            <li><a href="http://GeoPov/">Geospatial Poverty Solutions Home</a></li>
          </ul>
        </div>
        <div class="g-col-lg-4 g-col-md-4 g-col-sm-12 center-left-border">
          <ul>
            <li><a href="https://pipmaps.worldbank.org/">Geospatial poverty portal</a></li>
          </ul>
        </div>
        <div class="g-col-lg-4 g-col-md-4 g-col-sm-12 center-left-border">
          <ul>
            <li><a href="mailto:bbrunckhorst@worldbank.org?subject=GeoPov%20data%20and%20methods%20repository" target="_top">Contact us</a></li>
          </ul>
        </div>
      </div>
    </div>
</div>
```


', .open = "<<", .close = ">>") # Use different delimiters for glue


# 5. Write the content to the .qmd file
writeLines(qmd_content, qmd_file_path)

return(qmd_file_path)

  }

# 6. Apply the function to each row of the dataframe

created_files <- sapply(1:nrow(data), process_row)

message(paste("Successfully created", length(created_files), "files in the '", output_dir, "' directory."))

invisible(created_files) }
