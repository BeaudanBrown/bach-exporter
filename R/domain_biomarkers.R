be_normalize_biomarker_participant_id <- function(x) {
  values <- trimws(as.character(x))
  values[!nzchar(values)] <- NA_character_
  values <- be_clean_participant_id(values)

  numeric_values <- suppressWarnings(as.integer(values))
  has_numeric <- !is.na(numeric_values)
  values[has_numeric] <- sprintf("%03d", numeric_values[has_numeric])
  values
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

be_build_biomarkers_domain <- function(redcap_df, shared_root, years = NULL) {
  scaffold <- be_build_core_scaffold_domain(redcap_df, years = years)
  if (!nrow(scaffold)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  biomarkers <- be_read_biomarkers_snapshot(shared_root)
  subject_column <- if ("subject_id" %in% names(biomarkers)) {
    "subject_id"
  } else if ("Sample.ID" %in% names(biomarkers)) {
    "Sample.ID"
  } else {
    stop(
      "Biomarkers snapshot is missing subject_id or Sample.ID.",
      call. = FALSE
    )
  }
  sampletype_column <- if ("sampletype" %in% names(biomarkers)) {
    "sampletype"
  } else if ("Sample.Type" %in% names(biomarkers)) {
    "Sample.Type"
  } else {
    stop(
      "Biomarkers snapshot is missing sampletype or Sample.Type.",
      call. = FALSE
    )
  }

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

  field_map <- be_biomarker_value_fields()
  available_fields <- field_map[field_map %in% names(biomarkers)]
  if (!length(available_fields)) {
    return(scaffold[, c("participant_id", "event_name", "year"), drop = FALSE])
  }

  grouped_rows <- lapply(
    split(biomarkers, biomarkers$participant_id),
    function(df) {
      row <- list(participant_id = df$participant_id[[1]])
      sample_groups <- split(df, df$sampletype)
      for (sampletype in names(sample_groups)) {
        sample_rows <- sample_groups[[sampletype]]
        for (output_name in names(available_fields)) {
          source_name <- available_fields[[output_name]]
          row[[paste(output_name, sampletype, sep = "_")]] <- be_first_nonempty(
            sample_rows[[source_name]]
          )
        }
      }

      ab40_plasma <- suppressWarnings(as.numeric(
        row$ab40_mean_conc_plasma %||% NA
      ))
      ab42_plasma <- suppressWarnings(as.numeric(
        row$ab42_mean_conc_plasma %||% NA
      ))
      ab40_csf <- suppressWarnings(as.numeric(row$ab40_mean_conc_csf %||% NA))
      ab42_csf <- suppressWarnings(as.numeric(row$ab42_mean_conc_csf %||% NA))

      row$ab4240ratio_plasma <- be_compute_ab42_40_ratio(
        ab42_plasma,
        ab40_plasma
      )
      row$ab4240ratio_csf <- be_compute_ab42_40_ratio(ab42_csf, ab40_csf)

      as.data.frame(row, stringsAsFactors = FALSE)
    }
  )

  biomarker_wide <- be_bind_rows_fill(grouped_rows)
  biomarker_wide <- be_drop_empty_columns(biomarker_wide)
  biomarker_wide <- unique(biomarker_wide)

  merge(
    scaffold[, c("participant_id", "event_name", "year"), drop = FALSE],
    biomarker_wide,
    by = "participant_id",
    all.x = TRUE,
    sort = FALSE
  )
}
