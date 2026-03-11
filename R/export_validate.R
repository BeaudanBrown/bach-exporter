be_validate_export_spec <- function(spec) {
  if (!is.list(spec)) {
    return(list(ok = FALSE, message = "Export spec must be a list."))
  }

  shared_root <- spec$shared$root %||% NULL
  root_check <- be_validate_shared_root(shared_root)
  if (!isTRUE(root_check$ok)) {
    return(root_check)
  }

  output_path <- spec$output$path %||% ""
  if (!nzchar(output_path)) {
    return(list(ok = FALSE, message = "Choose an output file path."))
  }

  if (!length(spec$domains %||% character())) {
    return(list(ok = FALSE, message = "Choose at least one data domain."))
  }

  list(ok = TRUE, message = "Export spec is valid.", paths = root_check$paths)
}
