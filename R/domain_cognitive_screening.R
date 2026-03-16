be_build_cognitive_screening_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  if (!"tele_total" %in% names(redcap_df)) {
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
        cogscreen_total = be_first_nonempty(df$tele_total),
        stringsAsFactors = FALSE
      )
    }
  )

  screening <- do.call(rbind, grouped_rows)
  rownames(screening) <- NULL
  screening <- be_drop_empty_columns(screening)
  unique(screening)
}
