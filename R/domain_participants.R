be_first_nonempty <- function(x) {
  values <- x
  if (is.factor(values)) {
    values <- as.character(values)
  }

  values <- values[!is.na(values)]
  if (is.character(values)) {
    values <- trimws(values)
    values <- values[nzchar(values)]
  }

  if (!length(values)) {
    return(NA)
  }

  values[[1]]
}

be_build_core_scaffold_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  if (!nrow(redcap_df)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  scaffold <- unique(data.frame(
    participant_id = redcap_df$participant_id,
    subject_id = redcap_df$participant_id,
    event_name = redcap_df$event_name,
    session = redcap_df$event_name,
    year = redcap_df$year,
    session_date = be_coalesce_columns(redcap_df, c("pa_date", "pp_date")),
    stringsAsFactors = FALSE
  ))

  scaffold <- be_drop_empty_columns(scaffold)
  rownames(scaffold) <- NULL
  scaffold
}

be_baseline_demographics <- function(redcap_df) {
  baseline_rows <- redcap_df[redcap_df$year == "baseline", , drop = FALSE]
  if (!nrow(baseline_rows)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  demographic_fields <- intersect(
    c(
      "dob",
      "date_of_birth",
      "age",
      "sex",
      "gender",
      "education",
      "highest_education",
      "highest_education_other"
    ),
    names(baseline_rows)
  )

  demographic_rows <- lapply(
    split(baseline_rows, baseline_rows$participant_id),
    function(df) {
      values <- lapply(
        df[, demographic_fields, drop = FALSE],
        be_first_nonempty
      )
      values$participant_id <- df$participant_id[[1]]
      values
    }
  )

  demographics <- do.call(
    rbind,
    lapply(demographic_rows, function(row) {
      as.data.frame(row, stringsAsFactors = FALSE)
    })
  )
  rownames(demographics) <- NULL

  if ("highest_education" %in% names(demographics)) {
    missing_education <- !("education" %in% names(demographics)) |
      is.na(demographics$education) |
      trimws(demographics$education) == ""
    if (!("education" %in% names(demographics))) {
      demographics$education <- NA_character_
      missing_education <- rep(TRUE, nrow(demographics))
    }
    demographics$education[missing_education] <- demographics$highest_education[
      missing_education
    ]
  }

  demographics
}

be_build_participant_screening_domain <- function(redcap_df) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)

  screening <- be_baseline_demographics(redcap_df)
  if (!nrow(screening)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  if ("highest_education" %in% names(screening)) {
    screening$education_highest <- screening$highest_education
  }
  if ("highest_education_other" %in% names(screening)) {
    screening$education_highest_other_detail <- screening$highest_education_other
  }

  keep_columns <- c(
    "participant_id",
    "age",
    "sex",
    "education",
    "education_highest",
    "education_highest_other_detail"
  )
  keep_columns <- keep_columns[keep_columns %in% names(screening)]
  screening <- screening[, keep_columns, drop = FALSE]
  screening <- be_drop_empty_columns(screening)
  screening <- unique(screening)
  rownames(screening) <- NULL
  screening
}

be_build_participants_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  baseline_demographics <- be_baseline_demographics(redcap_df)
  participants <- be_build_core_scaffold_domain(redcap_df, years = years)
  if (nrow(baseline_demographics)) {
    participants <- merge(
      participants,
      baseline_demographics,
      by = "participant_id",
      all.x = TRUE,
      sort = FALSE
    )
  }

  keep_columns <- c(
    "participant_id",
    "subject_id",
    "event_name",
    "session",
    "year",
    "session_date",
    "dob",
    "date_of_birth",
    "age",
    "sex",
    "gender",
    "education",
    "highest_education"
  )
  keep_columns <- keep_columns[keep_columns %in% names(participants)]
  participants <- participants[, keep_columns, drop = FALSE]
  participants <- be_drop_empty_columns(participants)
  participants <- unique(participants)
  rownames(participants) <- NULL
  participants
}
