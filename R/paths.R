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

be_targets_cache_key <- function(shared_root = NULL) {
  normalized <- normalizePath(
    shared_root %||% "default",
    winslash = "/",
    mustWork = FALSE
  )
  bytes <- utf8ToInt(normalized)
  if (!length(bytes)) {
    return("default")
  }

  checksum <- sum(bytes * seq_along(bytes)) %% 2147483647
  sprintf("root-%08x", checksum)
}

be_local_targets_dir <- function(build_id = "dev", shared_root = NULL) {
  build_id <- build_id %||% "dev"
  path <- file.path(
    be_local_cache_dir(),
    "targets",
    build_id,
    be_targets_cache_key(shared_root)
  )
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

be_local_library_dir <- function(build_id = "dev") {
  build_id <- build_id %||% "dev"
  platform <- paste(
    R.version$platform,
    paste(R.version$major, R.version$minor, sep = "."),
    sep = "-"
  )
  path <- file.path(be_local_cache_dir(), "renv-library", build_id, platform)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

be_shared_app_root <- function(shared_root) {
  file.path(shared_root, "app")
}

be_shared_manifest_path <- function(shared_root) {
  file.path(be_shared_app_root(shared_root), "manifest.json")
}

be_read_manifest <- function(manifest_path) {
  if (
    is.null(manifest_path) ||
      !nzchar(manifest_path) ||
      !file.exists(manifest_path)
  ) {
    return(NULL)
  }

  tryCatch(
    jsonlite::read_json(manifest_path, simplifyVector = TRUE),
    error = function(err) NULL
  )
}

be_read_manifest_build_id <- function(manifest_path) {
  manifest <- be_read_manifest(manifest_path)
  if (is.null(manifest)) {
    return(NULL)
  }

  build_id <- manifest$build_id %||% manifest$release_id %||% NULL
  if (is.null(build_id) || !nzchar(build_id)) {
    return(NULL)
  }

  as.character(build_id)
}

be_read_shared_manifest <- function(shared_root) {
  be_read_manifest(be_shared_manifest_path(shared_root))
}

be_read_build_id <- function(shared_root) {
  be_read_manifest_build_id(be_shared_manifest_path(shared_root))
}

be_read_release_id <- function(shared_root) {
  be_read_build_id(shared_root)
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

be_shared_runtime_root <- function(shared_root) {
  app_root <- be_shared_app_root(shared_root)
  if (dir.exists(app_root)) {
    return(app_root)
  }

  if (
    file.exists(file.path(shared_root, "DESCRIPTION")) &&
      file.exists(file.path(shared_root, "scripts", "launch_from_share.R"))
  ) {
    return(shared_root)
  }

  NULL
}

be_shared_paths <- function(shared_root) {
  app_root <- be_shared_runtime_root(shared_root)
  build_id <- if (!is.null(app_root) && !identical(app_root, shared_root)) {
    be_read_manifest_build_id(file.path(app_root, "manifest.json"))
  } else {
    NULL
  }
  if (is.null(app_root)) {
    build_id <- NULL
  } else if (identical(app_root, shared_root) && is.null(build_id)) {
    build_id <- "dev"
  }

  list(
    shared_root = shared_root,
    build_id = build_id,
    is_dev = identical(app_root, shared_root),
    release_id = build_id,
    app_root = app_root,
    release_root = app_root,
    release_launcher = if (!is.null(app_root)) {
      file.path(app_root, "scripts", "launch_from_share.R")
    } else {
      NULL
    },
    release_manifest = if (!is.null(app_root)) {
      file.path(app_root, "manifest.json")
    } else {
      NULL
    },
    presets_dir = if (!is.null(app_root)) {
      file.path(app_root, "inst", "presets")
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
