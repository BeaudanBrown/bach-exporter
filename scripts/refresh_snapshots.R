source("R/paths.R")
source("R/source_refresh_admin.R")

be_refresh_snapshots_runtime <- function() {
  list(
    load_dotenv = be_load_admin_dotenv,
    read_config = be_admin_refresh_config,
    validate_config = be_validate_admin_refresh_config,
    build_plan = be_admin_refresh_plan,
    package_available = function(package) {
      requireNamespace(package, quietly = TRUE)
    },
    init_keyring = be_admin_init_connections,
    execute_refresh = be_admin_execute_refresh,
    inform = message
  )
}

refresh_snapshots_main <- function(
  args = commandArgs(trailingOnly = TRUE),
  runtime = be_refresh_snapshots_runtime()
) {
  execute_refresh <- "--execute" %in% args
  init_keyring <- "--init-keyring" %in% args
  dotenv_loaded <- runtime$load_dotenv()

  config <- runtime$read_config()
  validation <- runtime$validate_config(config)
  plan <- runtime$build_plan(config)

  runtime$inform(
    "Admin REDCap refresh entrypoint configured for schema snapshots via redcapAPI."
  )
  if (isTRUE(dotenv_loaded)) {
    runtime$inform(sprintf(
      "Loaded environment variables from %s",
      normalizePath(".env")
    ))
  }
  runtime$inform(sprintf("Config path: %s", config$config_path))
  runtime$inform(
    paste(
      "Populate admin settings with env vars",
      "BACH_REDCAP_URL, BACH_REDCAP_KEYRING,",
      "BACH_REDCAP_PROJECT_ALIAS, BACH_REDCAP_CONNECTION_NAME,",
      "BACH_PSG_REDCAP_PROJECT_ALIAS, BACH_PSG_REDCAP_CONNECTION_NAME,",
      "BACH_SCHEMA_SNAPSHOT_ONLY, BACH_RECORD_PROBE_ONLY, BACH_PROBE_RECORDS"
    )
  )
  runtime$inform(
    "or place the same keys in the local admin config JSON path above."
  )
  runtime$inform(sprintf("Shared root: %s", plan$shared_root %||% "<unset>"))
  runtime$inform(sprintf("REDCap URL: %s", config$redcap_url))
  runtime$inform(sprintf("Keyring: %s", config$keyring))
  runtime$inform(sprintf("Project alias: %s", config$project_alias))
  runtime$inform(sprintf("Connection name: %s", config$connection_name))
  runtime$inform(sprintf("PSG project alias: %s", config$psg_project_alias))
  runtime$inform(sprintf("PSG connection name: %s", config$psg_connection_name))
  runtime$inform(sprintf(
    "Schema snapshot dir: %s",
    plan$snapshot_paths$redcap_schema$schema_dir
  ))
  runtime$inform(sprintf(
    "Schema-only mode: %s",
    isTRUE(config$schema_snapshot_only)
  ))
  runtime$inform(sprintf(
    "Record-probe mode: %s",
    isTRUE(config$record_probe_only)
  ))
  if (isTRUE(config$record_probe_only)) {
    runtime$inform(sprintf(
      "Probe records: %s",
      paste(config$probe_records, collapse = ", ")
    ))
  }

  if (!isTRUE(validation$ok)) {
    stop(validation$message, call. = FALSE)
  }

  if (!isTRUE(runtime$package_available(config$package))) {
    stop(
      sprintf(
        "%s is not available in this environment. Re-enter the flake dev shell or run bash ./bin/in-env ...",
        config$package
      ),
      call. = FALSE
    )
  }

  if (init_keyring) {
    runtime$inform("Initializing or unlocking redcapAPI keyring.")
    runtime$inform(
      "You will be prompted for the keyring password and, if needed, the REDCap API tokens for both the main and PSG projects."
    )
    runtime$init_keyring(config)
    runtime$inform("Keyring initialization complete.")
    return(invisible(list(
      mode = "init-keyring",
      config = config,
      plan = plan,
      validation = validation,
      dotenv_loaded = dotenv_loaded
    )))
  }

  if (!execute_refresh) {
    runtime$inform(
      "Dry run only. Re-run with --init-keyring to populate the keyring, or with --execute to write schema and REDCap snapshot files."
    )
    return(invisible(list(
      mode = "dry-run",
      config = config,
      plan = plan,
      validation = validation,
      dotenv_loaded = dotenv_loaded
    )))
  }

  runtime$inform("Executing REDCap snapshot refresh.")
  result <- runtime$execute_refresh(config)
  runtime$inform("REDCap snapshot refresh complete.")
  runtime$inform(sprintf("Wrote %s", result$schema$paths$metadata))
  runtime$inform(sprintf("Wrote %s", result$schema$paths$project_info))
  runtime$inform(sprintf("Wrote %s", result$schema$paths$events))
  runtime$inform(sprintf("Wrote %s", result$schema$paths$instruments))
  runtime$inform(sprintf("Wrote %s", result$schema$paths$field_names))
  runtime$inform(sprintf("Wrote %s", result$schema$paths$codebook))
  if (!is.null(result$records)) {
    runtime$inform(sprintf("Wrote %s", result$records$paths$raw))
    runtime$inform(sprintf("Wrote %s", result$records$paths$labels))
    runtime$inform(sprintf("Wrote %s", result$records$paths$metadata))
  } else {
    runtime$inform(
      "Skipped record export because schema_snapshot_only is true."
    )
  }
  if (!is.null(result$psg)) {
    runtime$inform(sprintf("Wrote %s", result$psg$paths$raw))
    runtime$inform(sprintf("Wrote %s", result$psg$paths$metadata))
  } else {
    runtime$inform(
      "Skipped PSG record export because schema_snapshot_only is true."
    )
  }
  runtime$inform(sprintf("Wrote %s", result$snapshot_index$path))

  invisible(list(
    mode = "execute",
    config = config,
    plan = plan,
    validation = validation,
    dotenv_loaded = dotenv_loaded,
    result = result
  ))
}

if (sys.nframe() == 0) {
  refresh_snapshots_main()
}
