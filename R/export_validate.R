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

  if (
    !is.null(spec$cohort$subset_file) &&
      nzchar(spec$cohort$subset_file) &&
      !file.exists(spec$cohort$subset_file)
  ) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Subset file does not exist: %s",
        spec$cohort$subset_file
      )
    ))
  }

  supported_domains <- c("participants")
  unsupported_domains <- setdiff(spec$domains, supported_domains)
  if (length(unsupported_domains)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Selected domains are not implemented yet: %s",
        paste(unsupported_domains, collapse = ", ")
      )
    ))
  }

  list(ok = TRUE, message = "Export spec is valid.", paths = root_check$paths)
}
