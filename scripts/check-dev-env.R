required_packages <- c(
  "shiny",
  "shinyFiles",
  "bslib",
  "targets",
  "tarchetypes",
  "crew",
  "future",
  "qs2",
  "dotenv",
  "jsonlite",
  "renv",
  "remotes",
  "testthat"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages)) {
  stop(
    sprintf(
      "Missing packages in flake environment: %s",
      paste(missing_packages, collapse = ", ")
    ),
    call. = FALSE
  )
}

cat("Flake R environment OK\n")
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf(
  "Verified packages: %s\n",
  paste(required_packages, collapse = ", ")
))
