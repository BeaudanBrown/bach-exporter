be_normalize_mri_subject_id <- function(x) {
  values <- trimws(as.character(x))
  values[!nzchar(values)] <- NA_character_
  values <- gsub("^sub-?", "", values, ignore.case = TRUE)
  be_clean_participant_id(values)
}

be_build_mri_domain <- function(redcap_df, shared_root, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  baseline_rows <- redcap_df[redcap_df$year == "baseline", , drop = FALSE]
  if (!nrow(baseline_rows)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  grouped_rows <- lapply(
    split(baseline_rows, baseline_rows$participant_id),
    function(df) {
      data.frame(
        participant_id = df$participant_id[[1]],
        event_name = df$event_name[[1]],
        year = df$year[[1]],
        mri_date = be_first_nonempty(df$mri_date),
        mri_time = be_first_nonempty(df$mri_time),
        stringsAsFactors = FALSE
      )
    }
  )

  mri <- do.call(rbind, grouped_rows)
  rownames(mri) <- NULL

  mri_lookup <- be_read_side_data_csv(
    shared_root,
    "global_n241.csv",
    col_classes = c(subject_id = "character")
  )
  if (!"subject_id" %in% names(mri_lookup)) {
    stop("MRI side-data is missing subject_id.", call. = FALSE)
  }

  mri_lookup$participant_id <- be_normalize_mri_subject_id(
    mri_lookup$subject_id
  )
  mri_lookup <- mri_lookup[!is.na(mri_lookup$participant_id), , drop = FALSE]
  mri_lookup <- mri_lookup[
    !duplicated(mri_lookup$participant_id),
    ,
    drop = FALSE
  ]

  lookup_columns <- setdiff(
    names(mri_lookup),
    c("participant_id", "subject_id")
  )
  if (length(lookup_columns)) {
    match_rows <- match(mri$participant_id, mri_lookup$participant_id)
    for (column in lookup_columns) {
      mri[[column]] <- mri_lookup[[column]][match_rows]
    }
  }

  mri <- be_drop_empty_columns(mri)
  unique(mri)
}

be_build_lp_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      lp_complete = "lp_successful",
      lp_date = "lp_date",
      lp_time = "lp_time",
      lp_fail_reason = "lp_successful_n",
      lp_fail_other = "lp_successful_n_other",
      lp_notes = "lp_notes",
      lp_notes_detail = "lp_notes_y"
    )
  )
}
