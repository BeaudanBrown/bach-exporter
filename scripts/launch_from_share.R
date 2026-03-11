launch_from_share <- function(shared_root) {
  release_file <- file.path(shared_root, "CURRENT_RELEASE.txt")
  if (file.exists(release_file)) {
    release_id <- trimws(readLines(release_file, warn = FALSE, n = 1))
    release_root <- file.path(shared_root, "releases", release_id)
  } else {
    release_id <- "dev"
    release_root <- shared_root
  }

  message(sprintf("Launching BACH Exporter from release %s", release_id))
  message(sprintf("Shared root: %s", shared_root))
  message(sprintf("Release root: %s", release_root))
  message(
    "Dependency restore and local package installation are deferred to the next implementation slice."
  )

  r_files <- sort(list.files(
    file.path(release_root, "R"),
    pattern = "\\.[Rr]$",
    full.names = TRUE
  ))
  if (!length(r_files)) {
    stop("No R source files were found in the release root.", call. = FALSE)
  }

  runtime_env <- new.env(parent = globalenv())
  for (path in r_files) {
    sys.source(path, envir = runtime_env)
  }

  shiny::runApp(
    runtime_env$run_app(shared_root = shared_root),
    launch.browser = TRUE
  )
}
