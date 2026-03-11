library(targets)

tar_option_set(
  packages = c(
    "jsonlite",
    "shiny"
  ),
  format = "rds",
  seed = 20260311
)

tar_source()

be_target_graph()
