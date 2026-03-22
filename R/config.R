be_shared_root_config_path <- function() {
  file.path(be_local_config_dir(), "shared-root.json")
}

be_read_shared_root_config <- function(config_path) {
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

be_load_shared_root <- function() {
  config_path <- be_shared_root_config_path()
  root <- be_read_shared_root_config(config_path)
  if (!is.null(root)) {
    return(root)
  }

  admin_config_path <- file.path(be_local_config_dir(), "admin-refresh.json")
  admin_root <- be_read_shared_root_config(admin_config_path)
  if (is.null(admin_root) || !nzchar(admin_root)) {
    return(NULL)
  }

  admin_root
}

be_save_shared_root <- function(shared_root) {
  normalized_root <- normalizePath(
    shared_root,
    winslash = "/",
    mustWork = FALSE
  )
  dir.create(
    dirname(be_shared_root_config_path()),
    recursive = TRUE,
    showWarnings = FALSE
  )
  jsonlite::write_json(
    list(
      shared_root = normalized_root
    ),
    path = be_shared_root_config_path(),
    auto_unbox = TRUE,
    pretty = TRUE
  )

  admin_config_path <- file.path(be_local_config_dir(), "admin-refresh.json")
  admin_config <- if (file.exists(admin_config_path)) {
    jsonlite::read_json(admin_config_path, simplifyVector = TRUE)
  } else {
    list()
  }
  admin_config$shared_root <- normalized_root
  jsonlite::write_json(
    admin_config,
    path = admin_config_path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
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
