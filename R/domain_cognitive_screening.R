be_build_cognitive_screening_domain <- function(
  redcap_df,
  years = NULL,
  participant_year_rows = NULL
) {
  participant_year_rows <- participant_year_rows %||%
    be_participant_year_rows_input(redcap_df, years)

  if (!"tele_total" %in% names(participant_year_rows)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  screening <- participant_year_rows[,
    c("participant_id", "event_name", "year", "tele_total"),
    drop = FALSE
  ]
  names(screening)[names(screening) == "tele_total"] <- "cogscreen_total"
  screening <- be_drop_empty_columns(screening)
  unique(screening)
}
