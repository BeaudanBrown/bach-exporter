be_local_config_dir <- function() {
  path <- tools::R_user_dir("bachExporter", which = "config")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

be_local_cache_dir <- function() {
  path <- tools::R_user_dir("bachExporter", which = "cache")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

be_local_data_dir <- function() {
  path <- tools::R_user_dir("bachExporter", which = "data")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

be_local_log_dir <- function() {
  path <- file.path(be_local_data_dir(), "logs")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

be_local_targets_dir <- function(release_id = "dev") {
  path <- file.path(be_local_cache_dir(), "targets", release_id)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

be_local_library_dir <- function(release_id = "dev") {
  platform <- paste(
    R.version$platform,
    paste(R.version$major, R.version$minor, sep = "."),
    sep = "-"
  )
  path <- file.path(be_local_cache_dir(), "renv-library", release_id, platform)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

be_release_id_path <- function(shared_root) {
  file.path(shared_root, "CURRENT_RELEASE.txt")
}

be_read_release_id <- function(shared_root) {
  release_file <- be_release_id_path(shared_root)
  if (!file.exists(release_file)) {
    return(NULL)
  }
  release_id <- trimws(readLines(release_file, warn = FALSE, n = 1))
  if (!nzchar(release_id)) {
    return(NULL)
  }
  release_id
}

be_shiny_roots <- function() {
  if (.Platform$OS.type == "windows") {
    return(shinyFiles::getVolumes()())
  }

  c(
    Home = normalizePath("~", winslash = "/", mustWork = FALSE),
    Root = "/"
  )
}

be_release_root <- function(shared_root, release_id = NULL) {
  release_id <- release_id %||% be_read_release_id(shared_root)
  if (is.null(release_id)) {
    return(NULL)
  }
  file.path(shared_root, "releases", release_id)
}

be_shared_paths <- function(shared_root) {
  release_id <- be_read_release_id(shared_root)
  if (
    is.null(release_id) &&
      file.exists(file.path(shared_root, "DESCRIPTION")) &&
      file.exists(file.path(shared_root, "scripts", "launch_from_share.R"))
  ) {
    release_id <- "dev"
    release_root <- shared_root
  } else {
    release_root <- be_release_root(shared_root, release_id)
  }

  list(
    shared_root = shared_root,
    release_id = release_id,
    release_root = release_root,
    release_launcher = if (!is.null(release_root)) {
      file.path(release_root, "scripts", "launch_from_share.R")
    } else {
      NULL
    },
    release_manifest = if (!is.null(release_root)) {
      file.path(release_root, "manifest.json")
    } else {
      NULL
    },
    presets_dir = if (!is.null(release_root)) {
      file.path(release_root, "inst", "presets")
    } else {
      NULL
    },
    side_data_dir = if (!is.null(release_root)) {
      file.path(release_root, "inst", "side-data")
    } else {
      NULL
    },
    snapshots_dir = file.path(shared_root, "snapshots")
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}
