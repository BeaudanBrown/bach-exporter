be_admin_refresh_config_path <- function() {
  file.path(be_local_config_dir(), "admin-refresh.json")
}

be_admin_refresh_config <- function(config_path = NULL) {
  config_path <- config_path %||%
    Sys.getenv(
      "BACH_EXPORTER_ADMIN_CONFIG",
      unset = be_admin_refresh_config_path()
    )

  file_config <- if (file.exists(config_path)) {
    jsonlite::read_json(config_path, simplifyVector = TRUE)
  } else {
    list()
  }

  env_or_file <- function(env_name, file_name = NULL, default = NULL) {
    env_name_value <- Sys.getenv(env_name, unset = "")
    if (nzchar(env_name_value)) {
      return(env_name_value)
    }

    file_name <- file_name %||% tolower(env_name)
    file_value <- file_config[[file_name]] %||% default
    if (is.null(file_value) || !length(file_value)) {
      return(default)
    }

    file_value
  }

  list(
    config_path = config_path,
    shared_root = env_or_file("BACH_SHARED_ROOT", "shared_root", NULL),
    redcap_url = env_or_file(
      "BACH_REDCAP_URL",
      "redcap_url",
      "https://redcap.example.org/api/"
    ),
    keyring = env_or_file(
      "BACH_REDCAP_KEYRING",
      "keyring",
      "bach-exporter-admin"
    ),
    project_alias = env_or_file(
      "BACH_REDCAP_PROJECT_ALIAS",
      "project_alias",
      "bach-exporter"
    ),
    connection_name = env_or_file(
      "BACH_REDCAP_CONNECTION_NAME",
      "connection_name",
      "rcon_admin"
    ),
    schema_snapshot_only = isTRUE(
      file_config$schema_snapshot_only %||% TRUE
    ),
    package = "redcapAPI"
  )
}

be_admin_snapshot_schema_paths <- function(shared_root) {
  schema_dir <- file.path(shared_root, "snapshots", "redcap", "schema")

  list(
    schema_dir = schema_dir,
    metadata = file.path(schema_dir, "metadata.json"),
    project_info = file.path(schema_dir, "project-info.json"),
    events = file.path(schema_dir, "events.json"),
    instruments = file.path(schema_dir, "instruments.json"),
    field_names = file.path(schema_dir, "field-names.json")
  )
}

be_validate_admin_refresh_config <- function(config) {
  if (is.null(config$shared_root) || !nzchar(config$shared_root)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Admin refresh shared_root is missing. Set BACH_SHARED_ROOT or populate %s.",
        config$config_path
      )
    ))
  }

  if (is.null(config$redcap_url) || !nzchar(config$redcap_url)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Admin refresh redcap_url is missing. Set BACH_REDCAP_URL or populate %s.",
        config$config_path
      )
    ))
  }

  if (is.null(config$keyring) || !nzchar(config$keyring)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Admin refresh keyring is not configured. Set BACH_REDCAP_KEYRING or populate %s.",
        config$config_path
      )
    ))
  }

  if (is.null(config$project_alias) || !nzchar(config$project_alias)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Admin refresh project_alias is not configured. Set BACH_REDCAP_PROJECT_ALIAS or populate %s.",
        config$config_path
      )
    ))
  }

  if (is.null(config$connection_name) || !nzchar(config$connection_name)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Admin refresh connection_name is not configured. Set BACH_REDCAP_CONNECTION_NAME or populate %s.",
        config$config_path
      )
    ))
  }

  list(ok = TRUE, message = "Admin refresh config is valid.")
}

be_admin_refresh_plan <- function(config) {
  list(
    shared_root = config$shared_root,
    config_path = config$config_path,
    package = config$package,
    keyring = config$keyring,
    project_alias = config$project_alias,
    connection_name = config$connection_name,
    schema_snapshot_only = isTRUE(config$schema_snapshot_only),
    snapshot_paths = be_admin_snapshot_schema_paths(config$shared_root)
  )
}

be_admin_unlock_connections <- function(config, envir = parent.frame()) {
  connections <- stats::setNames(config$project_alias, config$connection_name)

  redcapAPI::unlockREDCap(
    connections = connections,
    keyring = config$keyring,
    url = config$redcap_url,
    envir = envir
  )
}
