be_normalize_year_name <- function(x) {
  value <- tolower(trimws(as.character(x)))
  tokenized <- gsub("[^a-z0-9]+", " ", value)
  tokenized <- trimws(tokenized)

  ifelse(
    grepl("\\bbaseline\\b", tokenized),
    "baseline",
    ifelse(
      grepl(
        "\\byear\\s*2\\b|\\byear2\\b|\\b2\\s*year\\b|\\b2\\s*yr\\b",
        tokenized
      ),
      "year2",
      ifelse(
        grepl(
          "\\byear\\s*3\\b|\\byear3\\b|\\b3\\s*year\\b|\\b3\\s*yr\\b",
          tokenized
        ),
        "year3",
        ifelse(
          grepl(
            paste0(
              "\\byear\\s*4\\b|\\byear4\\b|\\b4\\s*year\\b|\\b4\\s*yr\\b|",
              "\\bfollow\\s*up\\b|\\bfollowup\\b"
            ),
            tokenized
          ),
          "year4",
          value
        )
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

be_normalize_year_filter <- function(years) {
  if (is.null(years) || !length(years)) {
    return(NULL)
  }

  sort(unique(as.character(years)))
}

be_mark_filtered_redcap_years <- function(df, years) {
  attr(df, "bach_filtered_redcap_years") <- be_normalize_year_filter(years)
  df
}

be_filtered_redcap_years <- function(df) {
  attr(df, "bach_filtered_redcap_years")
}

be_filter_years <- function(df, years) {
  if (is.null(years) || !length(years) || !"year" %in% names(df)) {
    return(df)
  }

  normalized_years <- be_normalize_year_filter(years)
  if (identical(be_filtered_redcap_years(df), normalized_years)) {
    return(df)
  }

  out <- df[df$year %in% years, , drop = FALSE]
  if (be_is_prepared_redcap_snapshot(df)) {
    out <- be_mark_prepared_redcap_snapshot(out)
  }
  event_rows <- be_redcap_event_rows(df)
  baseline_rows <- be_redcap_baseline_rows(df)
  participant_year_rows <- be_redcap_participant_year_rows(df)
  if (
    !is.null(event_rows) ||
      !is.null(baseline_rows) ||
      !is.null(participant_year_rows)
  ) {
    out <- be_mark_redcap_reductions(
      out,
      event_rows = if (is.null(event_rows)) {
        NULL
      } else {
        be_filter_years(event_rows, years)
      },
      baseline_rows = if (is.null(baseline_rows)) {
        NULL
      } else {
        be_filter_years(baseline_rows, years)
      },
      participant_year_rows = if (is.null(participant_year_rows)) {
        NULL
      } else {
        be_filter_years(participant_year_rows, years)
      }
    )
  }
  out <- be_mark_filtered_redcap_years(out, normalized_years)

  out
}
