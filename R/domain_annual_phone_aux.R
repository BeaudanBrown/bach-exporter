be_build_moca_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  if (!"moca_total" %in% names(redcap_df)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  grouped_rows <- lapply(
    split(
      redcap_df,
      interaction(redcap_df$participant_id, redcap_df$year, drop = TRUE)
    ),
    function(df) {
      data.frame(
        participant_id = df$participant_id[[1]],
        event_name = df$event_name[[1]],
        year = df$year[[1]],
        tele_date = be_first_nonempty(be_coalesce_columns(df, "pp_date")),
        moca_total = be_first_nonempty(df$moca_total),
        stringsAsFactors = FALSE
      )
    }
  )

  moca <- do.call(rbind, grouped_rows)
  rownames(moca) <- NULL
  moca <- moca[!is.na(moca$moca_total), , drop = FALSE]
  moca <- be_drop_empty_columns(moca)
  unique(moca)
}

be_build_ad8_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  required_fields <- intersect(
    c("ad8_who", "ad8_date", "ad8_total"),
    names(redcap_df)
  )
  if (!length(required_fields)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  grouped_rows <- lapply(
    split(
      redcap_df,
      interaction(redcap_df$participant_id, redcap_df$year, drop = TRUE)
    ),
    function(df) {
      data.frame(
        participant_id = df$participant_id[[1]],
        event_name = df$event_name[[1]],
        year = df$year[[1]],
        tele_date = be_first_nonempty(be_coalesce_columns(df, "pp_date")),
        ad8_person = be_first_nonempty(df$ad8_who %||% NA),
        ad8_date = be_first_nonempty(df$ad8_date %||% NA),
        ad8_total = be_first_nonempty(df$ad8_total %||% NA),
        stringsAsFactors = FALSE
      )
    }
  )

  ad8 <- do.call(rbind, grouped_rows)
  rownames(ad8) <- NULL
  ad8 <- ad8[
    !(is.na(ad8$ad8_person) &
      is.na(ad8$ad8_date) &
      is.na(ad8$ad8_total)),
    ,
    drop = FALSE
  ]
  ad8 <- be_drop_empty_columns(ad8)
  unique(ad8)
}

be_build_ucla_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  ucla_fields <- intersect(
    c("ucla1_v2", "ucla2_v2", "ucla3_v2", "ucla_total_v2"),
    names(redcap_df)
  )
  if (!length(ucla_fields)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  grouped_rows <- lapply(
    split(
      redcap_df,
      interaction(redcap_df$participant_id, redcap_df$year, drop = TRUE)
    ),
    function(df) {
      data.frame(
        participant_id = df$participant_id[[1]],
        event_name = df$event_name[[1]],
        year = df$year[[1]],
        ucla_q1 = be_first_nonempty(df$ucla1_v2 %||% NA),
        ucla_q2 = be_first_nonempty(df$ucla2_v2 %||% NA),
        ucla_q3 = be_first_nonempty(df$ucla3_v2 %||% NA),
        ucla_total = be_first_nonempty(df$ucla_total_v2 %||% NA),
        stringsAsFactors = FALSE
      )
    }
  )

  ucla <- do.call(rbind, grouped_rows)
  rownames(ucla) <- NULL
  ucla <- ucla[
    !(is.na(ucla$ucla_q1) &
      is.na(ucla$ucla_q2) &
      is.na(ucla$ucla_q3) &
      is.na(ucla$ucla_total)),
    ,
    drop = FALSE
  ]
  ucla <- be_drop_empty_columns(ucla)
  unique(ucla)
}
