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
  validation <- be_validate_release_contract(shared_root = shared_root)
  if (!isTRUE(validation$ok)) {
    return(validation)
  }

  list(
    ok = TRUE,
    message = validation$message,
    paths = validation$paths
  )
}
