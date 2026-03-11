be_build_participants_domain <- function(redcap_df, years = NULL) {
  participant_id_column <- be_redcap_id_column(redcap_df)
  redcap_df$participant_id <- be_clean_participant_id(redcap_df[[
    participant_id_column
  ]])
  redcap_df <- be_split_redcap_events(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  keep_columns <- c(
    "participant_id",
    "event_name",
    "year",
    "participated",
    "age",
    "sex",
    "education"
  )
  keep_columns <- unique(c(
    keep_columns,
    intersect(c("dob", "date_of_birth", "gender"), names(redcap_df))
  ))
  keep_columns <- keep_columns[keep_columns %in% names(redcap_df)]

  participants <- redcap_df[, keep_columns, drop = FALSE]
  participants <- be_drop_empty_columns(participants)
  participants <- unique(participants)
  rownames(participants) <- NULL
  participants
}
