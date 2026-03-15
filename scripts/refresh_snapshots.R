source("R/paths.R")
source("R/source_refresh_admin.R")

args <- commandArgs(trailingOnly = TRUE)
execute_refresh <- "--execute" %in% args
init_keyring <- "--init-keyring" %in% args
dotenv_loaded <- be_load_admin_dotenv()

config <- be_admin_refresh_config()
validation <- be_validate_admin_refresh_config(config)
plan <- be_admin_refresh_plan(config)

message(
  "Admin REDCap refresh entrypoint configured for schema snapshots via redcapAPI."
)
if (isTRUE(dotenv_loaded)) {
  message(sprintf(
    "Loaded environment variables from %s",
    normalizePath(".env")
  ))
}
message(sprintf("Config path: %s", config$config_path))
message(
  paste(
    "Populate admin settings with env vars",
    "BACH_SHARED_ROOT, BACH_REDCAP_URL, BACH_REDCAP_KEYRING,",
    "BACH_REDCAP_PROJECT_ALIAS, BACH_REDCAP_CONNECTION_NAME,",
    "BACH_SCHEMA_SNAPSHOT_ONLY, BACH_RECORD_PROBE_ONLY, BACH_PROBE_RECORDS"
  )
)
message("or place the same keys in the local admin config JSON path above.")
message(sprintf("Shared root: %s", plan$shared_root %||% "<unset>"))
message(sprintf("REDCap URL: %s", config$redcap_url))
message(sprintf("Keyring: %s", config$keyring))
message(sprintf("Project alias: %s", config$project_alias))
message(sprintf("Connection name: %s", config$connection_name))
message(sprintf("Schema snapshot dir: %s", plan$snapshot_paths$schema_dir))
message(sprintf("Schema-only mode: %s", isTRUE(config$schema_snapshot_only)))
message(sprintf("Record-probe mode: %s", isTRUE(config$record_probe_only)))
if (isTRUE(config$record_probe_only)) {
  message(sprintf(
    "Probe records: %s",
    paste(config$probe_records, collapse = ", ")
  ))
}

if (!isTRUE(validation$ok)) {
  stop(validation$message, call. = FALSE)
}

if (!requireNamespace("redcapAPI", quietly = TRUE)) {
  stop(
    "redcapAPI is not available in this environment. Re-enter the flake dev shell or run bash ./bin/in-env ...",
    call. = FALSE
  )
}

if (init_keyring) {
  message("Initializing or unlocking redcapAPI keyring.")
  message(
    "You will be prompted for the keyring password and, if needed, the REDCap API token."
  )
  be_admin_unlock_connections(config)
  message("Keyring initialization complete.")
  quit(save = "no", status = 0)
}

if (!execute_refresh) {
  message(
    "Dry run only. Re-run with --init-keyring to populate the keyring, or with --execute to write schema and REDCap snapshot files."
  )
  quit(save = "no", status = 0)
}

message("Executing REDCap snapshot refresh.")
result <- be_admin_execute_refresh(config)
message("REDCap snapshot refresh complete.")
message(sprintf("Wrote %s", result$schema$paths$metadata))
message(sprintf("Wrote %s", result$schema$paths$project_info))
message(sprintf("Wrote %s", result$schema$paths$events))
message(sprintf("Wrote %s", result$schema$paths$instruments))
message(sprintf("Wrote %s", result$schema$paths$field_names))
message(sprintf("Wrote %s", result$schema$paths$codebook))
if (!is.null(result$records)) {
  message(sprintf("Wrote %s", result$records$paths$raw))
  message(sprintf("Wrote %s", result$records$paths$labels))
  message(sprintf("Wrote %s", result$records$paths$metadata))
} else {
  message("Skipped record export because schema_snapshot_only is true.")
}
message(sprintf("Wrote %s", result$snapshot_index$path))
