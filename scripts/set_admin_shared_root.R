source("R/paths.R")
source("R/source_refresh_admin.R")
source("R/release_management.R")

set_admin_shared_root_main <- function(
  args = commandArgs(trailingOnly = TRUE)
) {
  parsed <- be_parse_script_args(args)
  shared_root <- parsed[["shared-root"]] %||% NULL
  config_path <- parsed[["config-path"]] %||% be_admin_refresh_config_path()

  if (
    (is.null(shared_root) || !nzchar(shared_root)) &&
      length(parsed$positionals %||% character())
  ) {
    shared_root <- parsed$positionals[[1]]
  }

  if (is.null(shared_root) || !nzchar(shared_root)) {
    stop(
      "Usage: set_admin_shared_root.R --shared-root <dir> [--config-path <file>]",
      call. = FALSE
    )
  }

  be_write_admin_refresh_config(
    shared_root = shared_root,
    config_path = config_path
  )
  be_save_shared_root(shared_root)
  message(sprintf("Admin shared root saved to %s", config_path))
  message(sprintf(
    "Launcher/app shared root saved to %s",
    be_shared_root_config_path()
  ))
  message(sprintf(
    "Shared root: %s",
    normalizePath(shared_root, winslash = "/", mustWork = FALSE)
  ))
  invisible(config_path)
}

if (sys.nframe() == 0) {
  set_admin_shared_root_main()
}
