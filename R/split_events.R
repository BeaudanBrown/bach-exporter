be_normalize_year_name <- function(x) {
  value <- tolower(trimws(as.character(x)))

  ifelse(
    grepl("baseline", value, fixed = TRUE),
    "baseline",
    ifelse(
      grepl("year 2|year2|2 year|2yr", value),
      "year2",
      ifelse(
        grepl("year 3|year3|3 year|3yr", value),
        "year3",
        value
      )
    )
  )
}

be_split_redcap_events <- function(df) {
  event_column <- if ("redcap_event_name" %in% names(df)) {
    "redcap_event_name"
  } else if ("event_name" %in% names(df)) {
    "event_name"
  } else {
    NULL
  }

  if (is.null(event_column)) {
    df$event_name <- NA_character_
    df$year <- "baseline"
    return(df)
  }

  df$event_name <- as.character(df[[event_column]])
  df$year <- be_normalize_year_name(df[[event_column]])
  df
}

be_filter_years <- function(df, years) {
  if (is.null(years) || !length(years) || !"year" %in% names(df)) {
    return(df)
  }

  df[df$year %in% years, , drop = FALSE]
}
