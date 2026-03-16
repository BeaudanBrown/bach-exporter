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

  source_mode <- spec$source$mode %||% "snapshot"
  if (!identical(source_mode, "snapshot")) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Unsupported source mode '%s'. Researcher exports must use snapshot mode.",
        source_mode
      )
    ))
  }

  supported_years <- c("baseline", "year2", "year3")
  years <- spec$cohort$years %||% character()
  unsupported_years <- setdiff(years, supported_years)
  if (length(unsupported_years)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Selected years are not supported: %s",
        paste(unsupported_years, collapse = ", ")
      )
    ))
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

  supported_domains <- c(
    "participants",
    "participant_screening",
    "mri_screening",
    "lp_screening",
    "moca",
    "ad8",
    "ucla",
    "demographics",
    "cesd",
    "stai",
    "pss",
    "cdrisc",
    "ses",
    "aria",
    "ipaq",
    "rhhi",
    "minddiet",
    "alcohol",
    "cfi",
    "global_health",
    "bloods",
    "vitals",
    "bp24h",
    "similarities",
    "prose_passages",
    "cognitive_screening",
    "medications"
  )
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

  selected_domains <- spec$domains %||% character()
  if (any(c("ses", "aria") %in% selected_domains)) {
    side_data_dir <- root_check$paths$side_data_dir %||% NULL
    required_files <- file.path(
      side_data_dir,
      c("absdf.csv", "RA_2016_AUST.csv")
    )
    missing_files <- required_files[!file.exists(required_files)]
    if (length(missing_files)) {
      return(list(
        ok = FALSE,
        message = sprintf(
          "SES/ARIA side-data is missing from shared root side-data/: %s",
          paste(basename(missing_files), collapse = ", ")
        )
      ))
    }
  }

  cat_labels <- spec$options$cat_labels %||% "named"
  if (!cat_labels %in% c("named", "numbered")) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Unsupported categorical label mode '%s'.",
        cat_labels
      )
    ))
  }

  list(ok = TRUE, message = "Export spec is valid.", paths = root_check$paths)
}
