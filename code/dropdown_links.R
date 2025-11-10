library(htmltools)
library(stringr)

dropdown_links <- function(output_dir, title, link_data, outline_color = NULL, icon_path = NULL) {
  # --- Input Validation ---
  if (ncol(link_data) < 1) {
    stop("The 'link_data' data frame must have at least one column.")
  }

  # --- Link Generation ---
  item_names <- link_data[[1]]
  item_links <- sapply(item_names, function(name) {
    file_name <- str_to_lower(name)
    file_name <- str_replace_all(file_name, "[^a-z0-9]+", "-")
    file_name <- str_replace_all(file_name, "(^-|-$)", "")
    file.path(output_dir, paste0(file_name, ".qmd"))
  })

  # --- Header Content (Icon + Title) ---
  header_content <- if (!is.null(icon_path)) {
    tagList(
      tags$img(src = icon_path, class = "dropdown-icon"),
      tags$span(title)
    )
  } else {
    title
  }

  # --- Dropdown Content Items (Links) ---
  content_items <- mapply(
    function(name, link) {
      tags$a(href = link, name, class = "dropdown-item")
    },
    item_names,
    item_links,
    SIMPLIFY = FALSE
  )

  # --- Dynamic Style for Outline Color ---
  block_style <- if (!is.null(outline_color)) {
    paste("border-color:", outline_color)
  } else {
    NULL
  }

  # --- HTML Assembly ---
  hover_block_html <- div(
    class = "dropdown-block",
    style = block_style, # Apply the dynamic style here
    # The clickable header
    div(
      class = "dropdown-header",
      header_content
    ),
    # The content that appears on hover
    div(
      class = "dropdown-content",
      content_items
    )
  )

  return(hover_block_html)
}
