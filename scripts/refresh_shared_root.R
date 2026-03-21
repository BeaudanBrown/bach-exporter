source("R/paths.R")
source("R/release_runtime.R")
source("R/source_refresh_admin.R")
source("R/release_management.R")
source("scripts/refresh_snapshots.R")

refresh_shared_root_main <- function(
  args = commandArgs(trailingOnly = TRUE),
  refresh_runner = refresh_snapshots_main
) {
  parsed <- be_parse_script_args(args)
  shared_root <- parsed[["shared-root"]] %||% NULL
  repo_root <- parsed[["repo-root"]] %||% getwd()
  build_id <- parsed[["build-id"]] %||% NULL
  overwrite <- !identical(parsed[["no-overwrite"]] %||% FALSE, TRUE)
  include_side_data <- !identical(parsed[["no-side-data"]] %||% FALSE, TRUE)
  skip_refresh <- identical(parsed[["skip-refresh"]] %||% FALSE, TRUE)
  init_keyring <- identical(parsed[["init-keyring"]] %||% FALSE, TRUE)

  resolved_shared_root <- be_resolve_admin_shared_root(shared_root)
  be_write_admin_refresh_config(resolved_shared_root)

  staged_root <- tempfile("shared-app-stage-")
  on.exit(unlink(staged_root, recursive = TRUE, force = TRUE), add = TRUE)

  stage_result <- be_stage_shared_app(
    output_root = staged_root,
    repo_root = repo_root,
    build_id = build_id,
    include_side_data = include_side_data,
    overwrite = TRUE
  )
  publish_result <- be_publish_shared_app(
    staged_root = stage_result$shared_root,
    shared_root = resolved_shared_root,
    overwrite = overwrite,
    sync_side_data = include_side_data
  )

  refresh_args <- character()
  if (isTRUE(init_keyring)) {
    refresh_args <- c(refresh_args, "--init-keyring")
  }
  if (!isTRUE(skip_refresh)) {
    refresh_args <- c(refresh_args, "--execute")
  }
  refresh_result <- refresh_runner(args = refresh_args)

  invisible(list(
    stage = stage_result,
    publish = publish_result,
    refresh = refresh_result
  ))
}

if (sys.nframe() == 0) {
  refresh_shared_root_main()
}
