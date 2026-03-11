source("R/paths.R")
source("R/source_refresh_admin.R")

args <- commandArgs(trailingOnly = TRUE)
execute_refresh <- "--execute" %in% args
init_keyring <- "--init-keyring" %in% args

config <- be_admin_refresh_config()
validation <- be_validate_admin_refresh_config(config)
plan <- be_admin_refresh_plan(config)

message(
  "Admin REDCap refresh entrypoint configured for schema snapshots via redcapAPI."
)
message(sprintf("Config path: %s", config$config_path))
message(
  "Populate admin settings with env vars BACH_SHARED_ROOT, BACH_REDCAP_URL, BACH_REDCAP_KEYRING, BACH_REDCAP_PROJECT_ALIAS, BACH_REDCAP_CONNECTION_NAME"
)
message("or place the same keys in the local admin config JSON path above.")
message(sprintf("Shared root: %s", plan$shared_root %||% "<unset>"))
message(sprintf("REDCap URL: %s", config$redcap_url))
message(sprintf("Keyring: %s", config$keyring))
message(sprintf("Project alias: %s", config$project_alias))
message(sprintf("Connection name: %s", config$connection_name))
message(sprintf("Schema snapshot dir: %s", plan$snapshot_paths$schema_dir))

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
    "Dry run only. Re-run with --init-keyring to populate the keyring, or with --execute once the schema snapshot implementation is ready."
  )
  quit(save = "no", status = 0)
}

stop(
  "Schema snapshot execution is not implemented yet. This stub is the entrypoint where redcapAPI connection and metadata export will be added.",
  call. = FALSE
)
