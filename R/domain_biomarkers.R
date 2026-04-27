be_normalize_biomarker_participant_id <- function(x) {
  be_normalize_participant_merge_id(x, width = 4L)
}

be_normalize_biomarker_sampletype <- function(x) {
  values <- trimws(as.character(x))
  values[!nzchar(values)] <- NA_character_
  normalized <- tolower(values)
  ifelse(
    normalized %in% c("plasma", "csf", "dbs"),
    normalized,
    NA_character_
  )
}

be_biomarker_value_fields <- function() {
  c(
    ab40_mean_conc = "AB40_mean_conc",
    ab40_cv = "AB40_cv",
    ab42_mean_conc = "AB42_mean_conc",
    ab42_cv = "AB42_cv",
    gfap_mean_conc = "GFAP_mean_conc",
    gfap_cv = "GFAP_cv",
    nfl_mean_conc = "NfL_mean_conc",
    nfl_cv = "NfL_cv",
    ptau181_mean_conc = "pTau181_mean_conc",
    ptau181_cv = "pTau181_cv",
    ptau217_mean_conc = "pTau217_mean_conc",
    ptau217_cv = "pTau217_cv"
  )
}

be_biomarker_subject_column <- function(biomarkers) {
  if ("Sample ID" %in% names(biomarkers)) {
    return("Sample ID")
  }
  if ("Sample.ID" %in% names(biomarkers)) {
    return("Sample.ID")
  }
  if ("subject_id" %in% names(biomarkers)) {
    return("subject_id")
  }

  stop(
    "Biomarkers snapshot is missing subject_id, Sample ID, or Sample.ID.",
    call. = FALSE
  )
}

be_biomarker_sampletype_column <- function(biomarkers) {
  if ("sampletype" %in% names(biomarkers)) {
    return("sampletype")
  }
  if ("Sample Type" %in% names(biomarkers)) {
    return("Sample Type")
  }
  if ("Sample.Type" %in% names(biomarkers)) {
    return("Sample.Type")
  }

  stop(
    "Biomarkers snapshot is missing sampletype, Sample Type, or Sample.Type.",
    call. = FALSE
  )
}

be_build_biomarkers_participant_wide <- function(biomarkers) {
  subject_column <- be_biomarker_subject_column(biomarkers)
  sampletype_column <- be_biomarker_sampletype_column(biomarkers)

  biomarkers$participant_id <- be_normalize_biomarker_participant_id(
    biomarkers[[subject_column]]
  )
  biomarkers$sampletype <- be_normalize_biomarker_sampletype(
    biomarkers[[sampletype_column]]
  )
  biomarkers <- biomarkers[
    !is.na(biomarkers$participant_id) & !is.na(biomarkers$sampletype),
    ,
    drop = FALSE
  ]
  if (!nrow(biomarkers)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  field_map <- be_biomarker_value_fields()
  available_fields <- field_map[field_map %in% names(biomarkers)]
  if (!length(available_fields)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  reduced <- be_reduce_redcap_rows(
    biomarkers[,
      c("participant_id", "sampletype", unname(available_fields)),
      drop = FALSE
    ],
    c("participant_id", "sampletype")
  )
  participant_ids <- unique(reduced$participant_id)
  wide <- data.frame(participant_id = participant_ids, stringsAsFactors = FALSE)
  match_rows <- match(reduced$participant_id, participant_ids)

  for (sampletype in sort(unique(reduced$sampletype))) {
    sample_rows <- reduced$sampletype == sampletype
    sample_index <- match_rows[sample_rows]

    for (output_name in names(available_fields)) {
      source_name <- available_fields[[output_name]]
      column_name <- paste(output_name, sampletype, sep = "_")
      wide[[column_name]] <- NA
      wide[[column_name]][sample_index] <- reduced[[source_name]][sample_rows]
    }
  }

  ab40_plasma <- suppressWarnings(as.numeric(
    wide$ab40_mean_conc_plasma %||% NA
  ))
  ab42_plasma <- suppressWarnings(as.numeric(
    wide$ab42_mean_conc_plasma %||% NA
  ))
  ab40_csf <- suppressWarnings(as.numeric(wide$ab40_mean_conc_csf %||% NA))
  ab42_csf <- suppressWarnings(as.numeric(wide$ab42_mean_conc_csf %||% NA))

  wide$ab4240ratio_plasma <- be_compute_ab42_40_ratio(
    ab42_plasma,
    ab40_plasma
  )
  wide$ab4240ratio_csf <- be_compute_ab42_40_ratio(ab42_csf, ab40_csf)

  wide <- be_drop_empty_columns(wide)
  unique(wide)
}

be_read_biomarkers_wide <- function(shared_root) {
  biomarkers <- be_read_biomarkers_snapshot(shared_root)
  be_build_biomarkers_participant_wide(biomarkers)
}

be_build_biomarkers_domain <- function(
  redcap_df,
  shared_root,
  years = NULL,
  scaffold = NULL,
  biomarker_wide = NULL
) {
  scaffold <- scaffold %||%
    be_build_core_scaffold_domain(redcap_df, years = years)
  if (!nrow(scaffold)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  biomarker_wide <- biomarker_wide %||% be_read_biomarkers_wide(shared_root)
  if (!nrow(biomarker_wide)) {
    return(scaffold[, c("participant_id", "event_name", "year"), drop = FALSE])
  }

  output <- scaffold[, c("participant_id", "event_name", "year"), drop = FALSE]
  match_rows <- match(
    be_normalize_biomarker_participant_id(output$participant_id),
    be_normalize_biomarker_participant_id(biomarker_wide$participant_id)
  )
  for (column in setdiff(names(biomarker_wide), "participant_id")) {
    output[[column]] <- biomarker_wide[[column]][match_rows]
  }

  unique(output)
}
