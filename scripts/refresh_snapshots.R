source("R/paths.R")
source("R/source_refresh_admin.R")

args <- commandArgs(trailingOnly = TRUE)
execute_refresh <- "--execute" %in% args

config <- be_admin_refresh_config()
validation <- be_validate_admin_refresh_config(config)
plan <- be_admin_refresh_plan(config)

message(
  "Admin REDCap refresh entrypoint configured for schema snapshots via redcapAPI."
)
message(sprintf("Config path: %s", config$config_path))
message(
  "Populate credentials with env vars BACH_SHARED_ROOT, BACH_REDCAP_URL, BACH_REDCAP_API_KEY"
)
message("or place the same keys in the local admin config JSON path above.")
message(sprintf("Shared root: %s", plan$shared_root %||% "<unset>"))
message(sprintf("REDCap URL: %s", config$redcap_url))
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

if (!execute_refresh) {
  message(
    "Dry run only. Re-run with --execute once the schema snapshot implementation is ready."
  )
  quit(save = "no", status = 0)
}

stop(
  "Schema snapshot execution is not implemented yet. This stub is the entrypoint where redcapAPI connection and metadata export will be added.",
  call. = FALSE
)
