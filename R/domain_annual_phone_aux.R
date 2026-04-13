be_participant_year_rows_input <- function(redcap_df, years = NULL) {
  redcap_df <- be_redcap_domain_input(redcap_df, years)
  participant_year_rows <- be_redcap_participant_year_rows(redcap_df)

  participant_year_rows %||%
    be_reduce_redcap_rows(
      redcap_df,
      c("participant_id", "year")
    )
}

be_build_moca_domain <- function(
  redcap_df,
  years = NULL,
  participant_year_rows = NULL
) {
  participant_year_rows <- participant_year_rows %||%
    be_participant_year_rows_input(redcap_df, years)

  if (!"moca_total" %in% names(participant_year_rows)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  moca <- participant_year_rows[,
    c("participant_id", "event_name", "year", "pp_date", "moca_total"),
    drop = FALSE
  ]
  names(moca)[names(moca) == "pp_date"] <- "tele_date"
  moca <- moca[!is.na(moca$moca_total), , drop = FALSE]
  moca <- be_drop_empty_columns(moca)
  unique(moca)
}

be_build_ad8_domain <- function(
  redcap_df,
  years = NULL,
  participant_year_rows = NULL
) {
  participant_year_rows <- participant_year_rows %||%
    be_participant_year_rows_input(redcap_df, years)

  required_fields <- intersect(
    c("ad8_who", "ad8_date", "ad8_total"),
    names(participant_year_rows)
  )
  if (!length(required_fields)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  ad8 <- participant_year_rows[,
    c("participant_id", "event_name", "year", "pp_date", required_fields),
    drop = FALSE
  ]
  names(ad8)[names(ad8) == "pp_date"] <- "tele_date"
  names(ad8)[names(ad8) == "ad8_who"] <- "ad8_person"
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

be_build_ucla_domain <- function(
  redcap_df,
  years = NULL,
  participant_year_rows = NULL
) {
  participant_year_rows <- participant_year_rows %||%
    be_participant_year_rows_input(redcap_df, years)

  ucla_fields <- intersect(
    c("ucla1_v2", "ucla2_v2", "ucla3_v2", "ucla_total_v2"),
    names(participant_year_rows)
  )
  if (!length(ucla_fields)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  ucla <- participant_year_rows[,
    c("participant_id", "event_name", "year", ucla_fields),
    drop = FALSE
  ]
  names(ucla)[names(ucla) == "ucla1_v2"] <- "ucla_q1"
  names(ucla)[names(ucla) == "ucla2_v2"] <- "ucla_q2"
  names(ucla)[names(ucla) == "ucla3_v2"] <- "ucla_q3"
  names(ucla)[names(ucla) == "ucla_total_v2"] <- "ucla_total"
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
