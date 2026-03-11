be_shared_root_config_path <- function() {
  file.path(be_local_config_dir(), "shared-root.json")
}

be_load_shared_root <- function() {
  config_path <- be_shared_root_config_path()
  if (!file.exists(config_path)) {
    return(NULL)
  }

  config <- jsonlite::read_json(config_path, simplifyVector = TRUE)
  root <- config$shared_root %||% NULL
  if (is.null(root) || !nzchar(root)) {
    return(NULL)
  }
  root
}

be_save_shared_root <- function(shared_root) {
  jsonlite::write_json(
    list(
      shared_root = normalizePath(shared_root, winslash = "/", mustWork = FALSE)
    ),
    path = be_shared_root_config_path(),
    auto_unbox = TRUE,
    pretty = TRUE
  )
}

be_validate_shared_root <- function(shared_root) {
  if (is.null(shared_root) || !nzchar(shared_root)) {
    return(list(ok = FALSE, message = "Shared root path is empty."))
  }

  if (!dir.exists(shared_root)) {
    return(list(ok = FALSE, message = "Shared root directory does not exist."))
  }

  paths <- be_shared_paths(shared_root)
  if (is.null(paths$release_id)) {
    return(list(
      ok = FALSE,
      message = "Shared root is missing CURRENT_RELEASE.txt and does not look like a direct release root."
    ))
  }

  if (!dir.exists(paths$release_root)) {
    return(list(
      ok = FALSE,
      message = "Active release folder does not exist under releases/."
    ))
  }

  if (!file.exists(paths$release_launcher)) {
    return(list(ok = FALSE, message = "Shared release launcher is missing."))
  }

  list(ok = TRUE, message = "Shared root is valid.", paths = paths)
}
