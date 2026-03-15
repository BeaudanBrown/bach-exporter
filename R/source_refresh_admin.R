be_load_admin_dotenv <- function(path = ".env") {
  if (is.null(path) || !nzchar(path) || !file.exists(path)) {
    return(FALSE)
  }

  readRenviron(normalizePath(path, winslash = "/", mustWork = TRUE))
}

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

  env_or_file_flag <- function(env_name, file_name, default = FALSE) {
    env_name_value <- Sys.getenv(env_name, unset = "")
    if (nzchar(env_name_value)) {
      normalized <- tolower(trimws(env_name_value))
      return(normalized %in% c("1", "true", "t", "yes", "y"))
    }

    isTRUE(file_config[[file_name]] %||% default)
  }

  env_or_file_vector <- function(env_name, file_name, default = character()) {
    env_name_value <- Sys.getenv(env_name, unset = "")
    if (nzchar(env_name_value)) {
      values <- trimws(strsplit(env_name_value, ",", fixed = TRUE)[[1]])
      values <- values[nzchar(values)]
      if (length(values)) {
        return(values)
      }
    }

    value <- file_config[[file_name]] %||% default
    value <- as.character(value)
    value[nzchar(value)]
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
    schema_snapshot_only = env_or_file_flag(
      "BACH_SCHEMA_SNAPSHOT_ONLY",
      "schema_snapshot_only",
      FALSE
    ),
    record_probe_only = env_or_file_flag(
      "BACH_RECORD_PROBE_ONLY",
      "record_probe_only",
      FALSE
    ),
    probe_records = env_or_file_vector(
      "BACH_PROBE_RECORDS",
      "probe_records",
      "10000"
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
    field_names = file.path(schema_dir, "field-names.json"),
    codebook = file.path(schema_dir, "codebook.json")
  )
}

be_admin_snapshot_redcap_paths <- function(shared_root) {
  redcap_dir <- file.path(shared_root, "snapshots", "redcap")

  list(
    redcap_dir = redcap_dir,
    raw = file.path(redcap_dir, "raw.csv"),
    labels = file.path(redcap_dir, "labels.csv"),
    metadata = file.path(redcap_dir, "metadata.json")
  )
}

be_admin_snapshot_index_path <- function(shared_root) {
  file.path(shared_root, "snapshots", "sidecars", "snapshot-index.json")
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
    record_probe_only = isTRUE(config$record_probe_only),
    probe_records = config$probe_records,
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

be_admin_redcap_api_functions <- function() {
  list(
    export_project_info = redcapAPI::exportProjectInformation,
    export_events = redcapAPI::exportEvents,
    export_instruments = redcapAPI::exportInstruments,
    export_field_names = redcapAPI::exportFieldNames,
    export_metadata = redcapAPI::exportMetaData,
    export_records_typed = redcapAPI::exportRecordsTyped,
    raw_cast = redcapAPI::raw_cast,
    default_cast_character = redcapAPI::default_cast_character,
    skip_validation = redcapAPI::skip_validation
  )
}

be_admin_redact_project_info <- function(project_info) {
  redacted_fields <- c(
    "project_pi_firstname",
    "project_pi_lastname",
    "project_pi_email"
  )

  if (is.data.frame(project_info)) {
    keep <- setdiff(names(project_info), redacted_fields)
    return(project_info[, keep, drop = FALSE])
  }

  if (is.list(project_info)) {
    project_info[redacted_fields] <- NULL
    return(project_info)
  }

  project_info
}

be_admin_collect_schema_snapshot <- function(
  config,
  envir = parent.frame(),
  api = be_admin_redcap_api_functions()
) {
  if (!exists(config$connection_name, envir = envir, inherits = TRUE)) {
    stop(
      sprintf(
        "REDCap connection '%s' was not created in the target environment.",
        config$connection_name
      ),
      call. = FALSE
    )
  }

  rcon <- get(config$connection_name, envir = envir, inherits = TRUE)
  project_info <- api$export_project_info(rcon)
  events <- api$export_events(rcon)
  instruments <- api$export_instruments(rcon)
  field_names <- api$export_field_names(rcon)
  codebook <- api$export_metadata(rcon)

  list(
    project_info = project_info,
    events = events,
    instruments = instruments,
    field_names = field_names,
    codebook = codebook
  )
}

be_admin_write_schema_snapshot <- function(
  config,
  schema_snapshot,
  snapshot_time = Sys.time()
) {
  paths <- be_admin_snapshot_schema_paths(config$shared_root)
  dir.create(paths$schema_dir, recursive = TRUE, showWarnings = FALSE)

  jsonlite::write_json(
    be_admin_redact_project_info(schema_snapshot$project_info),
    paths$project_info,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
  jsonlite::write_json(
    schema_snapshot$events,
    paths$events,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
  jsonlite::write_json(
    schema_snapshot$instruments,
    paths$instruments,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
  jsonlite::write_json(
    schema_snapshot$field_names,
    paths$field_names,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
  jsonlite::write_json(
    schema_snapshot$codebook,
    paths$codebook,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  count_rows <- function(x) {
    if (is.data.frame(x)) {
      return(nrow(x))
    }
    if (is.list(x)) {
      return(length(x))
    }
    length(x)
  }

  metadata <- list(
    source = "redcapAPI",
    snapshot_type = "schema",
    refreshed_at = format(
      as.POSIXct(snapshot_time, tz = "UTC"),
      "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC"
    ),
    redcap_url = config$redcap_url,
    keyring = config$keyring,
    project_alias = config$project_alias,
    connection_name = config$connection_name,
    files = list(
      project_info = basename(paths$project_info),
      events = basename(paths$events),
      instruments = basename(paths$instruments),
      field_names = basename(paths$field_names),
      codebook = basename(paths$codebook)
    ),
    counts = list(
      project_info = count_rows(schema_snapshot$project_info),
      events = count_rows(schema_snapshot$events),
      instruments = count_rows(schema_snapshot$instruments),
      field_names = count_rows(schema_snapshot$field_names),
      codebook = count_rows(schema_snapshot$codebook)
    )
  )

  jsonlite::write_json(
    metadata,
    paths$metadata,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  invisible(list(paths = paths, metadata = metadata))
}

be_admin_collect_records_snapshot <- function(
  config,
  envir = parent.frame(),
  api = be_admin_redcap_api_functions()
) {
  if (!exists(config$connection_name, envir = envir, inherits = TRUE)) {
    stop(
      sprintf(
        "REDCap connection '%s' was not created in the target environment.",
        config$connection_name
      ),
      call. = FALSE
    )
  }

  rcon <- get(config$connection_name, envir = envir, inherits = TRUE)

  list(
    raw = api$export_records_typed(
      rcon,
      records = if (isTRUE(config$record_probe_only)) {
        config$probe_records
      } else {
        NULL
      },
      cast = api$raw_cast,
      validation = api$skip_validation,
      warn_zero_coded = FALSE
    ),
    labels = api$export_records_typed(
      rcon,
      records = if (isTRUE(config$record_probe_only)) {
        config$probe_records
      } else {
        NULL
      },
      cast = api$default_cast_character,
      validation = api$skip_validation,
      warn_zero_coded = FALSE
    )
  )
}

be_admin_write_records_snapshot <- function(
  config,
  records_snapshot,
  schema_result = NULL,
  snapshot_time = Sys.time()
) {
  paths <- be_admin_snapshot_redcap_paths(config$shared_root)
  dir.create(paths$redcap_dir, recursive = TRUE, showWarnings = FALSE)

  utils::write.csv(records_snapshot$raw, paths$raw, row.names = FALSE)
  utils::write.csv(records_snapshot$labels, paths$labels, row.names = FALSE)

  metadata <- list(
    source = "redcapAPI",
    snapshot_type = "records",
    refreshed_at = format(
      as.POSIXct(snapshot_time, tz = "UTC"),
      "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC"
    ),
    redcap_url = config$redcap_url,
    keyring = config$keyring,
    project_alias = config$project_alias,
    connection_name = config$connection_name,
    files = list(
      raw = basename(paths$raw),
      labels = basename(paths$labels)
    ),
    counts = list(
      raw_rows = nrow(records_snapshot$raw),
      raw_cols = ncol(records_snapshot$raw),
      labels_rows = nrow(records_snapshot$labels),
      labels_cols = ncol(records_snapshot$labels)
    ),
    probe = list(
      record_probe_only = isTRUE(config$record_probe_only),
      probe_records = if (isTRUE(config$record_probe_only)) {
        config$probe_records
      } else {
        NULL
      }
    ),
    schema = if (!is.null(schema_result)) {
      list(
        metadata = basename(schema_result$paths$metadata),
        counts = schema_result$metadata$counts
      )
    } else {
      NULL
    }
  )

  jsonlite::write_json(
    metadata,
    paths$metadata,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  invisible(list(paths = paths, metadata = metadata))
}

be_admin_write_snapshot_index <- function(
  config,
  schema_result = NULL,
  records_result = NULL,
  snapshot_time = Sys.time()
) {
  index_path <- be_admin_snapshot_index_path(config$shared_root)
  dir.create(dirname(index_path), recursive = TRUE, showWarnings = FALSE)

  index <- list(
    refreshed_at = format(
      as.POSIXct(snapshot_time, tz = "UTC"),
      "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC"
    ),
    families = "redcap",
    snapshots = list(
      redcap = list(
        metadata = if (!is.null(records_result)) {
          basename(records_result$paths$metadata)
        } else {
          NULL
        },
        schema_metadata = if (!is.null(schema_result)) {
          file.path("schema", basename(schema_result$paths$metadata))
        } else {
          NULL
        }
      )
    )
  )

  jsonlite::write_json(
    index,
    index_path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  invisible(list(path = index_path, index = index))
}

be_admin_execute_schema_snapshot <- function(
  config,
  envir = parent.frame(),
  api = be_admin_redcap_api_functions(),
  snapshot_time = Sys.time(),
  unlocker = be_admin_unlock_connections
) {
  unlocker(config, envir = envir)
  schema_snapshot <- be_admin_collect_schema_snapshot(
    config = config,
    envir = envir,
    api = api
  )
  be_admin_write_schema_snapshot(
    config = config,
    schema_snapshot = schema_snapshot,
    snapshot_time = snapshot_time
  )
}

be_admin_execute_refresh <- function(
  config,
  envir = parent.frame(),
  api = be_admin_redcap_api_functions(),
  snapshot_time = Sys.time(),
  unlocker = be_admin_unlock_connections
) {
  unlocker(config, envir = envir)

  schema_snapshot <- be_admin_collect_schema_snapshot(
    config = config,
    envir = envir,
    api = api
  )
  schema_result <- be_admin_write_schema_snapshot(
    config = config,
    schema_snapshot = schema_snapshot,
    snapshot_time = snapshot_time
  )

  records_result <- NULL
  if (!isTRUE(config$schema_snapshot_only)) {
    records_snapshot <- be_admin_collect_records_snapshot(
      config = config,
      envir = envir,
      api = api
    )
    records_result <- be_admin_write_records_snapshot(
      config = config,
      records_snapshot = records_snapshot,
      schema_result = schema_result,
      snapshot_time = snapshot_time
    )
  }

  index_result <- be_admin_write_snapshot_index(
    config = config,
    schema_result = schema_result,
    records_result = records_result,
    snapshot_time = snapshot_time
  )

  invisible(list(
    schema = schema_result,
    records = records_result,
    snapshot_index = index_result
  ))
}
