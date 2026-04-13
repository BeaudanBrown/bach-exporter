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

be_build_core_scaffold_from_event_rows <- function(event_rows) {
  if (is.null(event_rows) || !nrow(event_rows)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  scaffold <- data.frame(
    participant_id = event_rows$participant_id,
    subject_id = event_rows$participant_id,
    event_name = event_rows$event_name,
    session = event_rows$event_name,
    year = event_rows$year,
    session_date = be_coalesce_columns(event_rows, c("pa_date", "pp_date")),
    stringsAsFactors = FALSE
  )

  scaffold <- be_drop_empty_columns(scaffold)
  rownames(scaffold) <- NULL
  scaffold
}

be_build_core_scaffold_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_redcap_domain_input(redcap_df, years)
  event_rows <- be_redcap_event_rows(redcap_df)

  if (!is.null(event_rows)) {
    return(be_build_core_scaffold_from_event_rows(event_rows))
  }

  if (!nrow(redcap_df)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  grouped_rows <- lapply(
    split(
      redcap_df,
      interaction(
        redcap_df$participant_id,
        redcap_df$event_name,
        redcap_df$year,
        drop = TRUE
      )
    ),
    function(df) {
      data.frame(
        participant_id = df$participant_id[[1]],
        subject_id = df$participant_id[[1]],
        event_name = df$event_name[[1]],
        session = df$event_name[[1]],
        year = df$year[[1]],
        session_date = be_first_nonempty(be_coalesce_columns(
          df,
          c("pa_date", "pp_date")
        )),
        stringsAsFactors = FALSE
      )
    }
  )

  scaffold <- do.call(rbind, grouped_rows)

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

be_build_participant_screening_domain <- function(
  redcap_df,
  baseline_demographics = NULL
) {
  redcap_df <- be_redcap_domain_input(redcap_df)

  screening <- baseline_demographics %||% be_baseline_demographics(redcap_df)
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

be_build_participants_domain <- function(
  redcap_df,
  years = NULL,
  baseline_demographics = NULL,
  scaffold = NULL,
  participants_base = NULL
) {
  if (is.null(participants_base)) {
    participants_base <- be_build_participants_base(
      redcap_df = redcap_df,
      years = years,
      baseline_demographics = baseline_demographics,
      scaffold = scaffold
    )
  }
  participants <- participants_base

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
  source_fields <- stats::setNames(names(participants), names(participants))
  source_fields <- source_fields[
    !names(source_fields) %in%
      c("participant_id", "subject_id", "event_name", "session", "year")
  ]
  be_set_redcap_source_fields(participants, source_fields)
}

be_build_participants_base <- function(
  redcap_df,
  years = NULL,
  baseline_demographics = NULL,
  scaffold = NULL
) {
  prepared_redcap_df <- be_redcap_domain_input(redcap_df)
  baseline_demographics <- baseline_demographics %||%
    be_baseline_demographics(prepared_redcap_df)
  participants <- scaffold %||%
    be_build_core_scaffold_domain(prepared_redcap_df, years = years)

  if (nrow(baseline_demographics)) {
    original_order <- seq_len(nrow(participants))
    match_rows <- match(
      participants$participant_id,
      baseline_demographics$participant_id
    )
    for (column in setdiff(names(baseline_demographics), "participant_id")) {
      participants[[column]] <- baseline_demographics[[column]][match_rows]
    }
    participants <- participants[
      order(participants$participant_id, original_order),
      ,
      drop = FALSE
    ]
    rownames(participants) <- NULL
  }

  participants
}
