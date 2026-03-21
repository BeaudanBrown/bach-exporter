local_launcher_script_path <- function() {
  file_arg <- commandArgs(trailingOnly = FALSE)
  file_arg <- file_arg[grepl("^--file=", file_arg)]
  if (!length(file_arg)) {
    stop("Could not resolve local launcher path.", call. = FALSE)
  }

  normalizePath(
    sub("^--file=", "", file_arg[[1]]),
    winslash = "/",
    mustWork = TRUE
  )
}

source(
  file.path(
    dirname(local_launcher_script_path()),
    "..",
    "launch_bach_exporter.R"
  ),
  local = FALSE
)

if (sys.nframe() == 0) {
  launch_bach_exporter()
}
