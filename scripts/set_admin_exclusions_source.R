source("R/paths.R")
source("R/source_snapshots.R")
source("R/source_refresh_admin.R")

set_admin_exclusions_source_main <- function(
  args = commandArgs(trailingOnly = TRUE)
) {
  if (length(args) != 1L || !nzchar(args[[1]])) {
    stop(
      "Usage: set_admin_exclusions_source.R <exclusions.json>",
      call. = FALSE
    )
  }
  config_path <- be_admin_refresh_config()$config_path
  be_set_admin_exclusions_source(args[[1]], config_path)
  message(
    "Exclusions source saved. Refresh commands will install it automatically."
  )
  invisible(config_path)
}

if (sys.nframe() == 0) {
  set_admin_exclusions_source_main()
}
