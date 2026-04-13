library(targets)

tar_option_set(
  packages = c(
    "jsonlite",
    "shiny"
  ),
  format = "qs",
  seed = 20260311
)

tar_source()

be_target_graph()
