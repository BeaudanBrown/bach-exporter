source("R/paths.R")
source("R/release_runtime.R")
source("R/source_refresh_admin.R")
source("R/release_management.R")

prepare_release_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- be_parse_script_args(args)
  output_root <- parsed[["output-root"]] %||% NULL
  repo_root <- parsed[["repo-root"]] %||% getwd()
  build_id <- parsed[["build-id"]] %||% NULL
  include_side_data <- !identical(parsed[["no-side-data"]] %||% FALSE, TRUE)
  overwrite <- identical(parsed[["force"]] %||% FALSE, TRUE)

  result <- be_stage_shared_app(
    output_root = output_root,
    repo_root = repo_root,
    build_id = build_id,
    include_side_data = include_side_data,
    overwrite = overwrite
  )

  message(sprintf("Prepared staged shared app: %s", result$app_root))
  message(sprintf("Shared root staging dir: %s", result$shared_root))
  message(sprintf("Build id: %s", result$build_id))
  invisible(result)
}

if (sys.nframe() == 0) {
  prepare_release_main()
}
