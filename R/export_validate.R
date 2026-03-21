be_researcher_source_spec <- function(source) {
  source <- source %||% list()
  if (!is.list(source)) {
    return(list(
      ok = FALSE,
      message = "Export source settings must be a list."
    ))
  }

  source_mode <- source$mode %||% "snapshot"
  if (!identical(source_mode, "snapshot")) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Unsupported source mode '%s'. Researcher exports must use snapshot mode.",
        source_mode
      )
    ))
  }

  extra_fields <- setdiff(names(source), "mode")
  if (length(extra_fields)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Researcher export source settings must stay snapshot-only. Remove unsupported fields: %s",
        paste(sort(extra_fields), collapse = ", ")
      )
    ))
  }

  list(
    ok = TRUE,
    source = list(mode = "snapshot")
  )
}

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

  source_check <- be_researcher_source_spec(spec$source)
  if (!isTRUE(source_check$ok)) {
    return(source_check)
  }

  if (!identical(spec$output$format %||% "csv", "csv")) {
    return(list(
      ok = FALSE,
      message = "Researcher exports currently support CSV output only."
    ))
  }

  supported_years <- c("baseline", "year2", "year3")
  years <- spec$cohort$years %||% character()
  if (!length(years)) {
    return(list(
      ok = FALSE,
      message = "Choose at least one cohort year."
    ))
  }
  if (anyDuplicated(years)) {
    return(list(
      ok = FALSE,
      message = "Selected years must be unique."
    ))
  }
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

  domains <- spec$domains %||% character()
  if (!is.character(domains)) {
    return(list(
      ok = FALSE,
      message = "Selected domains must be character values."
    ))
  }
  if (anyDuplicated(domains)) {
    return(list(
      ok = FALSE,
      message = "Selected domains must be unique."
    ))
  }

  supported_domains <- c(
    "participants",
    "participant_screening",
    "mri_screening",
    "mri",
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
    "medical_history",
    "cdr",
    "mmse",
    "sydbat",
    "logical_memory",
    "visual_reproduction",
    "tmt",
    "fab",
    "cowat",
    "hvot",
    "tasit",
    "topf",
    "dementia_status",
    "psqi",
    "ess",
    "isi",
    "actigraphy_full",
    "actigraphy_summary",
    "similarities",
    "prose_passages",
    "cognitive_screening",
    "medications"
  )
  unsupported_domains <- setdiff(domains, supported_domains)
  if (length(unsupported_domains)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Selected domains are not implemented yet: %s",
        paste(unsupported_domains, collapse = ", ")
      )
    ))
  }

  selected_domains <- domains
  if ("mri" %in% selected_domains) {
    side_data_dir <- root_check$paths$side_data_dir %||% NULL
    required_files <- file.path(side_data_dir, "global_n241.csv")
    missing_files <- required_files[!file.exists(required_files)]
    if (length(missing_files)) {
      return(list(
        ok = FALSE,
        message = sprintf(
          "MRI side-data is missing from shared root side-data/: %s",
          paste(basename(missing_files), collapse = ", ")
        )
      ))
    }
  }

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

  participant_ids <- spec$cohort$participant_ids %||% NULL
  if (!is.null(participant_ids) && !is.character(participant_ids)) {
    return(list(
      ok = FALSE,
      message = "Participant IDs must be provided as text values."
    ))
  }

  subset_file <- spec$cohort$subset_file %||% NULL
  if (!is.null(subset_file) && !is.character(subset_file)) {
    return(list(
      ok = FALSE,
      message = "Subset file path must be a text value."
    ))
  }
  if (!is.null(subset_file) && length(subset_file) != 1) {
    return(list(
      ok = FALSE,
      message = "Subset file path must be a single path."
    ))
  }
  if (
    !is.null(subset_file) && nzchar(subset_file) && !file.exists(subset_file)
  ) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Subset file does not exist: %s",
        subset_file
      )
    ))
  }

  list(ok = TRUE, message = "Export spec is valid.", paths = root_check$paths)
}
