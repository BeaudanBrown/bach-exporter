source("R/paths.R")
source("R/release_runtime.R")
source("R/source_refresh_admin.R")
source("R/release_management.R")

publish_release_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- be_parse_script_args(args)
  staged_root <- parsed[["staged-root"]] %||% NULL
  shared_root <- parsed[["shared-root"]] %||% NULL
  overwrite <- identical(parsed[["force"]] %||% FALSE, TRUE)
  sync_side_data <- !identical(parsed[["no-side-data"]] %||% FALSE, TRUE)

  if (is.null(staged_root) || !nzchar(staged_root)) {
    stop(
      "Usage: publish_release.R --staged-root <dir> [--shared-root <dir>] [--force]",
      call. = FALSE
    )
  }

  result <- be_publish_shared_app(
    staged_root = staged_root,
    shared_root = shared_root,
    overwrite = overwrite,
    sync_side_data = sync_side_data
  )

  message(sprintf(
    "Published shared app build %s to %s",
    result$build_id,
    result$app_root
  ))
  if (!is.null(result$previous_build_id) && nzchar(result$previous_build_id)) {
    message(sprintf("Previous build id: %s", result$previous_build_id))
  }
  invisible(result)
}

if (sys.nframe() == 0) {
  publish_release_main()
}
