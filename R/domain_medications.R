be_medication_repeat_labels <- function() {
  c("Medications", "Medication Follow")
}

be_clean_repeat_instance <- function(x) {
  value <- trimws(as.character(x))
  value[!nzchar(value)] <- NA_character_
  value
}

be_column_or_na <- function(df, field) {
  if (!field %in% names(df)) {
    return(rep(NA_character_, nrow(df)))
  }

  values <- df[[field]]
  values <- if (is.factor(values)) as.character(values) else values
  values <- as.character(values)
  values <- trimws(values)
  values[!nzchar(values)] <- NA_character_
  values
}

be_bind_rows_fill <- function(rows) {
  if (!length(rows)) {
    return(data.frame(stringsAsFactors = FALSE))
  }

  all_names <- unique(unlist(lapply(rows, names), use.names = FALSE))
  normalized <- lapply(rows, function(df) {
    missing_names <- setdiff(all_names, names(df))
    for (name in missing_names) {
      df[[name]] <- NA
    }
    df[, all_names, drop = FALSE]
  })

  out <- do.call(rbind, normalized)
  rownames(out) <- NULL
  out
}

be_build_medications_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  if (!"redcap_repeat_instrument" %in% names(redcap_df)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  repeat_instrument <- trimws(as.character(redcap_df$redcap_repeat_instrument))
  medication_rows <- redcap_df[
    repeat_instrument %in% be_medication_repeat_labels(),
    ,
    drop = FALSE
  ]
  if (!nrow(medication_rows)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  medication_rows$repeat_instrument <- trimws(as.character(
    medication_rows$redcap_repeat_instrument
  ))
  medication_rows$repeat_instance <- if (
    "redcap_repeat_instance" %in% names(medication_rows)
  ) {
    be_clean_repeat_instance(medication_rows$redcap_repeat_instance)
  } else {
    rep(NA_character_, nrow(medication_rows))
  }

  baseline_rows <- medication_rows$repeat_instrument == "Medications"
  follow_rows <- medication_rows$repeat_instrument == "Medication Follow"

  result <- data.frame(
    participant_id = medication_rows$participant_id,
    event_name = medication_rows$event_name,
    year = medication_rows$year,
    repeat_instrument = medication_rows$repeat_instrument,
    repeat_instance = medication_rows$repeat_instance,
    medication_change = NA_character_,
    medication_change_startstop = NA_character_,
    medication_name = NA_character_,
    medication_dose = NA_character_,
    medication_freq = NA_character_,
    medication_dosenumber = NA_character_,
    medication_reason = NA_character_,
    medication_reason_detail = NA_character_,
    medication_prescribed = NA_character_,
    medication_atc = NA_character_,
    stringsAsFactors = FALSE
  )

  if (any(baseline_rows)) {
    result$medication_name[baseline_rows] <- be_column_or_na(
      medication_rows[baseline_rows, , drop = FALSE],
      "med_name"
    )
    result$medication_dose[baseline_rows] <- be_column_or_na(
      medication_rows[baseline_rows, , drop = FALSE],
      "med_strength"
    )
    result$medication_freq[baseline_rows] <- be_column_or_na(
      medication_rows[baseline_rows, , drop = FALSE],
      "med_freq"
    )
    result$medication_dosenumber[baseline_rows] <- be_column_or_na(
      medication_rows[baseline_rows, , drop = FALSE],
      "med_times"
    )
    result$medication_reason[baseline_rows] <- be_column_or_na(
      medication_rows[baseline_rows, , drop = FALSE],
      "med_reason"
    )
    result$medication_reason_detail[baseline_rows] <- be_column_or_na(
      medication_rows[baseline_rows, , drop = FALSE],
      "med_reas"
    )
    result$medication_prescribed[baseline_rows] <- be_column_or_na(
      medication_rows[baseline_rows, , drop = FALSE],
      "med_pres"
    )
    result$medication_atc[baseline_rows] <- be_column_or_na(
      medication_rows[baseline_rows, , drop = FALSE],
      "med_atc"
    )
  }

  if (any(follow_rows)) {
    result$medication_change[follow_rows] <- be_column_or_na(
      medication_rows[follow_rows, , drop = FALSE],
      "mh_follow_meds_v2"
    )
    result$medication_change_startstop[follow_rows] <- be_column_or_na(
      medication_rows[follow_rows, , drop = FALSE],
      "mh_follow_meds_startstop_v2"
    )
    result$medication_name[follow_rows] <- be_column_or_na(
      medication_rows[follow_rows, , drop = FALSE],
      "mh_follow_meds_n_v2"
    )
    result$medication_dose[follow_rows] <- be_column_or_na(
      medication_rows[follow_rows, , drop = FALSE],
      "mh_follow_meds_str_v2"
    )
    result$medication_freq[follow_rows] <- be_column_or_na(
      medication_rows[follow_rows, , drop = FALSE],
      "mh_follow_meds_freq_v2"
    )
    result$medication_dosenumber[follow_rows] <- be_column_or_na(
      medication_rows[follow_rows, , drop = FALSE],
      "mh_follow_meds_times_v2"
    )
    result$medication_reason[follow_rows] <- be_column_or_na(
      medication_rows[follow_rows, , drop = FALSE],
      "mh_follow_meds_why_v2"
    )
    result$medication_reason_detail[follow_rows] <- be_column_or_na(
      medication_rows[follow_rows, , drop = FALSE],
      "mh_follow_meds_why_y_v2"
    )
    result$medication_prescribed[follow_rows] <- be_column_or_na(
      medication_rows[follow_rows, , drop = FALSE],
      "mh_follow_meds_presc_v2"
    )
    result$medication_atc[follow_rows] <- be_column_or_na(
      medication_rows[follow_rows, , drop = FALSE],
      "mh_follow_meds_atc_v2"
    )
  }

  result <- be_drop_empty_columns(result)
  rownames(result) <- NULL
  result
}

be_build_medications_wide_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  medication_long <- be_build_medications_domain(redcap_df, years = years)
  if (!nrow(medication_long)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  grouped <- split(
    medication_long,
    interaction(
      medication_long$participant_id,
      medication_long$event_name,
      medication_long$year,
      drop = TRUE
    )
  )

  wide_rows <- lapply(grouped, function(df) {
    key <- df[1, c("participant_id", "event_name", "year"), drop = FALSE]
    source_rows <- redcap_df[
      redcap_df$participant_id == key$participant_id[[1]] &
        redcap_df$event_name == key$event_name[[1]] &
        redcap_df$year == key$year[[1]],
      ,
      drop = FALSE
    ]

    row <- list(
      participant_id = key$participant_id[[1]],
      event_name = key$event_name[[1]],
      year = key$year[[1]]
    )

    medication_change <- be_first_nonempty(be_column_or_na(
      source_rows,
      "mh_follow_meds_v2"
    ))
    if (!is.na(medication_change)) {
      row$medication_change <- medication_change
    }

    medication_change_startstop <- be_first_nonempty(be_column_or_na(
      source_rows,
      "mh_follow_meds_startstop_v2"
    ))
    if (!is.na(medication_change_startstop)) {
      row$medication_change_startstop <- medication_change_startstop
    }

    instances <- suppressWarnings(as.integer(df$repeat_instance))
    fallback_instances <- seq_len(nrow(df))
    normalized_instances <- ifelse(
      is.na(instances),
      fallback_instances,
      instances
    )
    order_index <- order(normalized_instances)
    df <- df[order_index, , drop = FALSE]
    normalized_instances <- normalized_instances[order_index]

    value_columns <- setdiff(
      names(df),
      c(
        "participant_id",
        "event_name",
        "year",
        "repeat_instrument",
        "repeat_instance"
      )
    )
    for (i in seq_len(nrow(df))) {
      suffix <- sprintf("med_%02d", normalized_instances[[i]])
      for (column in value_columns) {
        if (column %in% c("medication_change", "medication_change_startstop")) {
          next
        }
        row[[paste(column, suffix, sep = "_")]] <- df[[column]][[i]]
      }
    }

    as.data.frame(row, stringsAsFactors = FALSE)
  })

  wide <- be_bind_rows_fill(wide_rows)
  wide <- be_drop_empty_columns(wide)
  unique(wide)
}
