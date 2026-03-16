be_build_mri_screening_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  if (!"handedness" %in% names(redcap_df)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

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
        handedness = be_first_nonempty(df$handedness),
        stringsAsFactors = FALSE
      )
    }
  )

  screening <- do.call(rbind, grouped_rows)
  rownames(screening) <- NULL
  screening <- be_drop_empty_columns(screening)
  unique(screening)
}

be_build_lp_screening_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  if (!"lp_interest" %in% names(redcap_df)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

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
        lp_interest = be_first_nonempty(df$lp_interest),
        stringsAsFactors = FALSE
      )
    }
  )

  screening <- do.call(rbind, grouped_rows)
  rownames(screening) <- NULL
  screening <- be_drop_empty_columns(screening)
  unique(screening)
}
