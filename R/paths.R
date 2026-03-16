be_resolve_local_dir <- function(path_candidates) {
  for (candidate in path_candidates) {
    if (is.null(candidate) || !nzchar(candidate)) {
      next
    }

    ok <- tryCatch(
      {
        dir.create(candidate, recursive = TRUE, showWarnings = FALSE)
        file.access(candidate, mode = 2) == 0
      },
      error = function(err) FALSE
    )

    if (isTRUE(ok)) {
      return(candidate)
    }
  }

  stop("Could not create a writable local directory.", call. = FALSE)
}

be_local_config_dir <- function() {
  be_resolve_local_dir(c(
    Sys.getenv("BACH_EXPORTER_LOCAL_CONFIG_DIR", unset = ""),
    getOption("bachExporter.local_config_dir", ""),
    tools::R_user_dir("bachExporter", which = "config"),
    file.path(tempdir(), "bachExporter", "config")
  ))
}

be_local_cache_dir <- function() {
  be_resolve_local_dir(c(
    Sys.getenv("BACH_EXPORTER_LOCAL_CACHE_DIR", unset = ""),
    getOption("bachExporter.local_cache_dir", ""),
    tools::R_user_dir("bachExporter", which = "cache"),
    file.path(tempdir(), "bachExporter", "cache")
  ))
}

be_local_data_dir <- function() {
  be_resolve_local_dir(c(
    Sys.getenv("BACH_EXPORTER_LOCAL_DATA_DIR", unset = ""),
    getOption("bachExporter.local_data_dir", ""),
    tools::R_user_dir("bachExporter", which = "data"),
    file.path(tempdir(), "bachExporter", "data")
  ))
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
    side_data_dir = file.path(shared_root, "side-data"),
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
