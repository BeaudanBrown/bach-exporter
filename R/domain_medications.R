be_medication_repeat_labels <- function() {
  c(
    "Medications",
    "Medication Follow",
    "medications",
    "medication_follow_2"
  )
}

be_medication_baseline_repeat_labels <- function() {
  c("Medications", "medications")
}

be_medication_follow_repeat_labels <- function() {
  c("Medication Follow", "medication_follow_2")
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

be_medications_event_key_rows <- function(
  redcap_df,
  years = NULL,
  scaffold = NULL
) {
  redcap_df <- be_redcap_domain_input(redcap_df, years)
  scaffold <- scaffold %||%
    be_build_core_scaffold_domain(redcap_df, years = years)
  if (!nrow(scaffold)) {
    return(list(
      redcap_df = redcap_df,
      output = scaffold[,
        c("participant_id", "event_name", "year"),
        drop = FALSE
      ],
      event_rows = data.frame(stringsAsFactors = FALSE),
      event_match = integer()
    ))
  }

  event_rows <- be_redcap_event_rows(redcap_df)
  if (is.null(event_rows)) {
    event_rows <- be_reduce_redcap_rows(
      redcap_df,
      c("participant_id", "event_name", "year")
    )
  }

  output <- scaffold[, c("participant_id", "event_name", "year"), drop = FALSE]
  event_match <- match(
    be_key_id_values(output, c("participant_id", "event_name", "year")),
    be_key_id_values(event_rows, c("participant_id", "event_name", "year"))
  )

  list(
    redcap_df = redcap_df,
    output = output,
    event_rows = event_rows,
    event_match = event_match
  )
}

be_build_medications_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_redcap_domain_input(redcap_df, years)

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

  baseline_rows <- medication_rows$repeat_instrument %in%
    be_medication_baseline_repeat_labels()
  follow_rows <- medication_rows$repeat_instrument %in%
    be_medication_follow_repeat_labels()

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

be_build_medications_wide_domain <- function(
  redcap_df,
  years = NULL,
  scaffold = NULL,
  baseline_demographics = NULL
) {
  event_context <- be_medications_event_key_rows(
    redcap_df = redcap_df,
    years = years,
    scaffold = scaffold
  )
  redcap_df <- event_context$redcap_df
  output <- event_context$output
  event_rows <- event_context$event_rows
  event_match <- event_context$event_match
  medication_long <- be_build_medications_domain(redcap_df, years = years)
  if (!nrow(output)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  baseline_demographics <- baseline_demographics %||%
    be_baseline_demographics(redcap_df)
  baseline_match <- if (nrow(baseline_demographics)) {
    match(output$participant_id, baseline_demographics$participant_id)
  } else {
    integer(nrow(output))
  }

  output$medication_change <- be_column_or_na(
    event_rows[event_match, , drop = FALSE],
    "mh_follow_meds_v2"
  )
  output$medication_change_startstop <- be_column_or_na(
    event_rows[event_match, , drop = FALSE],
    "mh_follow_meds_startstop_v2"
  )

  medication_key_ids <- if (nrow(medication_long)) {
    be_key_id_values(medication_long, c("participant_id", "event_name", "year"))
  } else {
    character()
  }
  medication_groups <- if (length(medication_key_ids)) {
    split(seq_len(nrow(medication_long)), medication_key_ids)
  } else {
    list()
  }
  output_key_ids <- be_key_id_values(
    output,
    c("participant_id", "event_name", "year")
  )

  medication_flag_prefixes <- list(
    depression_meds = c("N06A"),
    hypertensive_meds = c("C02", "C03", "C07", "C08", "C09"),
    lipid_meds = c("C10"),
    statin_meds = c("C10AA"),
    anxiety_meds = c("N05B"),
    diabetes_meds = c("A10"),
    sedative_meds = c("N05C")
  )
  for (name in names(medication_flag_prefixes)) {
    output[[name]] <- "No"
  }
  output$hypertension <- rep(NA_character_, nrow(output))
  output$dyslipidemia <- rep(NA_character_, nrow(output))

  event_rows_matched <- event_rows[event_match, , drop = FALSE]
  lying_sys <- suppressWarnings(as.numeric(
    be_column_or_na(event_rows_matched, "lying_systolic_bp_av")
  ))
  lying_dia <- suppressWarnings(as.numeric(
    be_column_or_na(event_rows_matched, "lying_diastolic_bp_av")
  ))
  sex <- be_column_or_na(event_rows_matched, "sex")
  if (nrow(baseline_demographics)) {
    missing_sex <- is.na(sex)
    sex[missing_sex] <- be_column_or_na(
      baseline_demographics[baseline_match[missing_sex], , drop = FALSE],
      "sex"
    )
  }
  bloods_chol <- suppressWarnings(as.numeric(
    be_column_or_na(event_rows_matched, "bloods_chol")
  ))
  bloods_hdl <- suppressWarnings(as.numeric(
    be_column_or_na(event_rows_matched, "bloods_chol_hdl")
  ))
  bloods_ldl <- suppressWarnings(as.numeric(
    be_column_or_na(event_rows_matched, "bloods_ldl")
  ))
  bloods_trig <- suppressWarnings(as.numeric(
    be_column_or_na(event_rows_matched, "bloods_trigly")
  ))

  value_columns <- setdiff(
    names(medication_long),
    c(
      "participant_id",
      "event_name",
      "year",
      "repeat_instrument",
      "repeat_instance",
      "medication_change",
      "medication_change_startstop"
    )
  )

  for (i in seq_along(output_key_ids)) {
    medication_index <- medication_groups[[output_key_ids[[i]]]]
    if (!is.null(medication_index)) {
      medication_rows <- medication_long[medication_index, , drop = FALSE]
      medication_codes <- be_medication_codes(medication_rows$medication_atc)
      for (name in names(medication_flag_prefixes)) {
        output[[name]][i] <- be_yes_no_flag(be_medication_has_prefix(
          medication_codes,
          medication_flag_prefixes[[name]]
        ))
      }

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

      for (j in seq_len(nrow(medication_rows))) {
        suffix <- sprintf("med_%02d", normalized_instances[[j]])
        for (column in value_columns) {
          column_name <- paste(column, suffix, sep = "_")
          if (!column_name %in% names(output)) {
            output[[column_name]] <- rep(NA_character_, nrow(output))
          }
          output[[column_name]][i] <- medication_rows[[column]][[j]]
        }
      }
    }

    output$hypertension[i] <- if (
      is.na(lying_sys[i]) ||
        is.na(lying_dia[i])
    ) {
      NA_character_
    } else if (
      lying_sys[i] >= 140 ||
        lying_dia[i] >= 90 ||
        identical(output$hypertensive_meds[i], "Yes")
    ) {
      "Yes"
    } else {
      "No"
    }

    output$dyslipidemia[i] <- if (
      is.na(bloods_chol[i]) ||
        is.na(bloods_hdl[i]) ||
        is.na(bloods_ldl[i]) ||
        is.na(bloods_trig[i]) ||
        is.na(sex[i])
    ) {
      NA_character_
    } else if (
      (identical(sex[i], "Male") && bloods_hdl[i] < 1.0) ||
        (identical(sex[i], "Female") && bloods_hdl[i] < 1.3) ||
        bloods_chol[i] >= 5.5 ||
        bloods_ldl[i] >= 3.5 ||
        bloods_trig[i] >= 2.0 ||
        identical(output$lipid_meds[i], "Yes")
    ) {
      "Yes"
    } else {
      "No"
    }
  }

  output <- be_drop_empty_columns(output)
  unique(output)
}
