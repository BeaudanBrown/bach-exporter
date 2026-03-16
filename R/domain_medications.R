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

be_medication_codes <- function(x) {
  values <- trimws(as.character(x))
  values[!nzchar(values)] <- NA_character_
  unique(values[!is.na(values)])
}

be_medication_has_prefix <- function(codes, prefixes) {
  if (!length(codes)) {
    return(FALSE)
  }

  any(vapply(
    codes,
    function(code) any(startsWith(code, prefixes)),
    logical(1)
  ))
}

be_yes_no_flag <- function(value) {
  if (isTRUE(value)) "Yes" else "No"
}

be_first_numeric <- function(df, field) {
  value <- be_first_nonempty(be_column_or_na(df, field))
  suppressWarnings(as.numeric(value))
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
  if (!nrow(redcap_df)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  baseline_demographics <- be_baseline_demographics(redcap_df)
  grouped <- split(
    redcap_df,
    interaction(
      redcap_df$participant_id,
      redcap_df$event_name,
      redcap_df$year,
      drop = TRUE
    )
  )

  wide_rows <- lapply(grouped, function(source_rows) {
    key <- source_rows[
      1,
      c("participant_id", "event_name", "year"),
      drop = FALSE
    ]
    medication_rows <- medication_long[
      medication_long$participant_id == key$participant_id[[1]] &
        medication_long$event_name == key$event_name[[1]] &
        medication_long$year == key$year[[1]],
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

    medication_codes <- be_medication_codes(medication_rows$medication_atc)
    row$depression_meds <- be_yes_no_flag(be_medication_has_prefix(
      medication_codes,
      c("N06A")
    ))
    row$hypertensive_meds <- be_yes_no_flag(be_medication_has_prefix(
      medication_codes,
      c("C02", "C03", "C07", "C08", "C09")
    ))
    row$lipid_meds <- be_yes_no_flag(be_medication_has_prefix(
      medication_codes,
      c("C10")
    ))
    row$statin_meds <- be_yes_no_flag(be_medication_has_prefix(
      medication_codes,
      c("C10AA")
    ))
    row$anxiety_meds <- be_yes_no_flag(be_medication_has_prefix(
      medication_codes,
      c("N05B")
    ))
    row$diabetes_meds <- be_yes_no_flag(be_medication_has_prefix(
      medication_codes,
      c("A10")
    ))
    row$sedative_meds <- be_yes_no_flag(be_medication_has_prefix(
      medication_codes,
      c("N05C")
    ))

    lying_sys <- be_first_numeric(source_rows, "lying_systolic_bp_av")
    lying_dia <- be_first_numeric(source_rows, "lying_diastolic_bp_av")
    row$hypertension <- if (is.na(lying_sys) || is.na(lying_dia)) {
      NA_character_
    } else if (
      lying_sys >= 140 ||
        lying_dia >= 90 ||
        identical(row$hypertensive_meds, "Yes")
    ) {
      "Yes"
    } else {
      "No"
    }

    sex <- be_first_nonempty(be_column_or_na(source_rows, "sex"))
    if (is.na(sex) && nrow(baseline_demographics)) {
      demo_match <- baseline_demographics[
        baseline_demographics$participant_id == key$participant_id[[1]],
        ,
        drop = FALSE
      ]
      if (nrow(demo_match)) {
        sex <- be_first_nonempty(be_column_or_na(demo_match, "sex"))
      }
    }
    bloods_chol <- be_first_numeric(source_rows, "bloods_chol")
    bloods_hdl <- be_first_numeric(source_rows, "bloods_chol_hdl")
    bloods_ldl <- be_first_numeric(source_rows, "bloods_ldl")
    bloods_trig <- be_first_numeric(source_rows, "bloods_trigly")
    row$dyslipidemia <- if (
      is.na(bloods_chol) ||
        is.na(bloods_hdl) ||
        is.na(bloods_ldl) ||
        is.na(bloods_trig) ||
        is.na(sex)
    ) {
      NA_character_
    } else if (
      (identical(sex, "Male") && bloods_hdl < 1.0) ||
        (identical(sex, "Female") && bloods_hdl < 1.3) ||
        bloods_chol >= 5.5 ||
        bloods_ldl >= 3.5 ||
        bloods_trig >= 2.0 ||
        identical(row$lipid_meds, "Yes")
    ) {
      "Yes"
    } else {
      "No"
    }

    if (nrow(medication_rows)) {
      instances <- suppressWarnings(as.integer(medication_rows$repeat_instance))
      fallback_instances <- seq_len(nrow(medication_rows))
      normalized_instances <- ifelse(
        is.na(instances),
        fallback_instances,
        instances
      )
      order_index <- order(normalized_instances)
      medication_rows <- medication_rows[order_index, , drop = FALSE]
      normalized_instances <- normalized_instances[order_index]

      value_columns <- setdiff(
        names(medication_rows),
        c(
          "participant_id",
          "event_name",
          "year",
          "repeat_instrument",
          "repeat_instance"
        )
      )
      for (i in seq_len(nrow(medication_rows))) {
        suffix <- sprintf("med_%02d", normalized_instances[[i]])
        for (column in value_columns) {
          if (
            column %in% c("medication_change", "medication_change_startstop")
          ) {
            next
          }
          row[[paste(column, suffix, sep = "_")]] <- medication_rows[[column]][[
            i
          ]]
        }
      }
    }

    as.data.frame(row, stringsAsFactors = FALSE)
  })

  wide <- be_bind_rows_fill(wide_rows)
  wide <- be_drop_empty_columns(wide)
  unique(wide)
}
