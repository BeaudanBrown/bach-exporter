be_event_key_columns <- function() {
  c("participant_id", "event_name", "year")
}

be_participant_key_columns <- function() {
  "participant_id"
}

be_redcap_event_rows <- function(df) {
  attr(df, "bach_redcap_event_rows")
}

be_redcap_baseline_rows <- function(df) {
  attr(df, "bach_redcap_baseline_rows")
}

be_redcap_participant_year_rows <- function(df) {
  attr(df, "bach_redcap_participant_year_rows")
}

be_mark_redcap_reductions <- function(
  df,
  event_rows = NULL,
  baseline_rows = NULL,
  participant_year_rows = NULL
) {
  attr(df, "bach_redcap_event_rows") <- event_rows
  attr(df, "bach_redcap_baseline_rows") <- baseline_rows
  attr(df, "bach_redcap_participant_year_rows") <- participant_year_rows
  df
}

be_set_redcap_source_fields <- function(
  df,
  source_fields,
  source_level = "event",
  source_levels = NULL
) {
  attr(df, "bach_redcap_source_fields") <- source_fields
  if (is.null(source_levels)) {
    source_levels <- rep(source_level, length(source_fields))
    names(source_levels) <- names(source_fields)
  } else {
    source_levels <- source_levels[
      names(source_levels) %in% names(source_fields)
    ]
    missing_levels <- setdiff(names(source_fields), names(source_levels))
    if (length(missing_levels)) {
      source_levels <- c(
        source_levels,
        stats::setNames(
          rep(source_level, length(missing_levels)),
          missing_levels
        )
      )
    }
    source_levels <- source_levels[names(source_fields)]
  }
  attr(df, "bach_redcap_source_levels") <- source_levels
  df
}

be_redcap_source_fields <- function(df) {
  attr(df, "bach_redcap_source_fields") %||% character()
}

be_redcap_source_levels <- function(df) {
  attr(df, "bach_redcap_source_levels") %||% character()
}

be_reduce_redcap_rows <- function(df, key_columns) {
  if (!nrow(df)) {
    out <- data.frame(stringsAsFactors = FALSE)
    for (column in key_columns) {
      out[[column]] <- character()
    }
    return(out[, key_columns, drop = FALSE])
  }

  value_columns <- setdiff(names(df), key_columns)
  output_columns <- c(key_columns, value_columns)
  group_ids <- interaction(df[, key_columns, drop = FALSE], drop = TRUE)

  if (!anyDuplicated(group_ids)) {
    out <- df[order(as.integer(group_ids)), output_columns, drop = FALSE]
    rownames(out) <- NULL
    return(out)
  }

  groups <- split(seq_len(nrow(df)), group_ids)
  first_rows <- vapply(groups, `[[`, integer(1), 1L)
  out <- df[first_rows, key_columns, drop = FALSE]

  for (column in value_columns) {
    values <- df[[column]]
    out[[column]] <- unlist(
      lapply(groups, function(index) be_first_nonempty(values[index])),
      recursive = FALSE,
      use.names = FALSE
    )
  }

  out <- out[, output_columns, drop = FALSE]
  rownames(out) <- NULL
  out
}

be_attach_redcap_reductions <- function(df) {
  if (
    !is.null(be_redcap_event_rows(df)) &&
      !is.null(be_redcap_baseline_rows(df)) &&
      !is.null(be_redcap_participant_year_rows(df))
  ) {
    return(df)
  }

  baseline_source <- df[df$year == "baseline", , drop = FALSE]
  be_mark_redcap_reductions(
    df,
    event_rows = be_reduce_redcap_rows(df, be_event_key_columns()),
    baseline_rows = be_reduce_redcap_rows(baseline_source, "participant_id"),
    participant_year_rows = be_reduce_redcap_rows(
      df,
      c("participant_id", "year")
    )
  )
}

be_standardize_event_domain <- function(domain_df) {
  key_columns <- be_event_key_columns()
  missing_keys <- setdiff(key_columns, names(domain_df))

  if (!length(missing_keys)) {
    return(domain_df)
  }

  if (nrow(domain_df)) {
    stop(
      sprintf(
        "Event domain is missing required key columns: %s",
        paste(missing_keys, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  for (column in missing_keys) {
    domain_df[[column]] <- character()
  }

  domain_df[,
    c(key_columns, setdiff(names(domain_df), key_columns)),
    drop = FALSE
  ]
}

be_standardize_participant_domain <- function(domain_df) {
  key_columns <- be_participant_key_columns()
  missing_keys <- setdiff(key_columns, names(domain_df))

  if (!length(missing_keys)) {
    return(domain_df)
  }

  if (nrow(domain_df)) {
    stop(
      sprintf(
        "Participant domain is missing required key columns: %s",
        paste(missing_keys, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  for (column in missing_keys) {
    domain_df[[column]] <- character()
  }

  domain_df[,
    c(key_columns, setdiff(names(domain_df), key_columns)),
    drop = FALSE
  ]
}

be_key_id_values <- function(df, key_columns) {
  if (!nrow(df)) {
    return(character())
  }

  apply(
    df[, key_columns, drop = FALSE],
    1,
    function(row) {
      paste(ifelse(is.na(row), "<NA>", as.character(row)), collapse = "\r")
    }
  )
}

be_unique_key_rows <- function(df, key_columns) {
  key_ids <- be_key_id_values(df, key_columns)
  if (!length(key_ids)) {
    out <- data.frame(stringsAsFactors = FALSE)
    for (column in key_columns) {
      out[[column]] <- character()
    }
    return(out[, key_columns, drop = FALSE])
  }

  df[!duplicated(key_ids), key_columns, drop = FALSE]
}

be_ensure_unique_domain_keys <- function(domain_df, key_columns, domain_label) {
  if (!nrow(domain_df)) {
    return(domain_df)
  }

  key_ids <- be_key_id_values(domain_df, key_columns)
  if (anyDuplicated(key_ids)) {
    stop(
      sprintf(
        "Domain output has duplicate key rows and cannot be attached safely: %s",
        domain_label
      ),
      call. = FALSE
    )
  }

  domain_df
}

be_attach_keyed_columns <- function(
  output,
  domain_df,
  key_columns,
  domain_label
) {
  if (is.null(domain_df)) {
    return(output)
  }

  if (!nrow(output)) {
    return(output)
  }

  domain_df <- be_ensure_unique_domain_keys(
    domain_df,
    key_columns,
    domain_label
  )
  if (!nrow(domain_df)) {
    return(output)
  }

  output_key_ids <- be_key_id_values(output, key_columns)
  domain_key_ids <- be_key_id_values(domain_df, key_columns)
  match_rows <- match(output_key_ids, domain_key_ids)

  for (column in setdiff(names(domain_df), key_columns)) {
    incoming <- domain_df[[column]][match_rows]
    if (!column %in% names(output)) {
      output[[column]] <- incoming
      next
    }

    output[[column]] <- be_coalesce_vectors(output[[column]], incoming)
  }

  output
}

be_expand_keyed_rows <- function(
  output,
  domain_df,
  key_columns
) {
  if (is.null(domain_df) || !nrow(domain_df)) {
    return(output)
  }

  if (is.null(output) || !nrow(output)) {
    return(domain_df)
  }

  domain_columns <- setdiff(names(domain_df), key_columns)
  for (column in domain_columns) {
    if (!column %in% names(output)) {
      output[[column]] <- NA
    }
  }

  output_key_ids <- be_key_id_values(output, key_columns)
  domain_key_ids <- be_key_id_values(domain_df, key_columns)
  expanded_rows <- vector("list", nrow(output))

  for (index in seq_len(nrow(output))) {
    match_rows <- which(domain_key_ids == output_key_ids[[index]])
    if (!length(match_rows)) {
      match_rows <- NA_integer_
    }

    rows <- output[rep(index, length(match_rows)), , drop = FALSE]
    for (column in domain_columns) {
      incoming <- if (all(is.na(match_rows))) {
        rep(NA, length(match_rows))
      } else {
        domain_df[[column]][match_rows]
      }
      rows[[column]] <- be_coalesce_vectors(rows[[column]], incoming)
    }

    expanded_rows[[index]] <- rows
  }

  out <- do.call(rbind, expanded_rows)
  rownames(out) <- NULL
  out
}

be_build_event_output_accumulator <- function(event_outputs, scaffold) {
  event_outputs <- Filter(
    function(output) !is.null(output) && nrow(output$data),
    event_outputs
  )
  if (!length(event_outputs)) {
    return(NULL)
  }

  event_outputs <- lapply(event_outputs, function(output) {
    output$data <- be_standardize_event_domain(output$data)
    output
  })

  key_columns <- be_event_key_columns()
  event_key_rows <- do.call(
    rbind,
    lapply(event_outputs, function(output) {
      output$data[, key_columns, drop = FALSE]
    })
  )
  event_key_rows <- be_unique_key_rows(event_key_rows, key_columns)
  event_key_ids <- be_key_id_values(event_key_rows, key_columns)

  accumulator <- NULL
  if (!is.null(scaffold) && nrow(scaffold)) {
    scaffold <- be_standardize_event_domain(scaffold)
    scaffold_key_ids <- be_key_id_values(scaffold, key_columns)
    scaffold_index <- match(event_key_ids, scaffold_key_ids)
    matched_rows <- !is.na(scaffold_index)
    if (any(matched_rows)) {
      accumulator <- scaffold[scaffold_index[matched_rows], , drop = FALSE]
      rownames(accumulator) <- NULL
    }
  }

  if (is.null(accumulator) || !nrow(accumulator)) {
    accumulator <- event_key_rows
  } else {
    missing_keys <- is.na(match(
      event_key_ids,
      be_key_id_values(accumulator, key_columns)
    ))
    if (any(missing_keys)) {
      accumulator <- rbind(
        accumulator,
        event_key_rows[missing_keys, , drop = FALSE]
      )
      rownames(accumulator) <- NULL
    }
  }

  for (event_output in event_outputs) {
    accumulator <- be_attach_keyed_columns(
      output = accumulator,
      domain_df = be_standardize_event_domain(event_output$data),
      key_columns = key_columns,
      domain_label = event_output$domain %||% "<unknown>"
    )
  }

  accumulator
}

be_build_participant_output_accumulator <- function(participant_outputs) {
  participant_outputs <- Filter(
    function(output) !is.null(output) && nrow(output$data),
    participant_outputs
  )
  if (!length(participant_outputs)) {
    return(NULL)
  }

  key_columns <- be_participant_key_columns()
  accumulator <- be_unique_key_rows(
    do.call(
      rbind,
      lapply(
        participant_outputs,
        function(output) output$data[, key_columns, drop = FALSE]
      )
    ),
    key_columns
  )

  for (participant_output in participant_outputs) {
    accumulator <- be_attach_keyed_columns(
      output = accumulator,
      domain_df = be_standardize_participant_domain(participant_output$data),
      key_columns = key_columns,
      domain_label = participant_output$domain %||% "<unknown>"
    )
  }

  accumulator
}

be_export_baseline_rows <- function(redcap_df) {
  baseline_rows <- be_redcap_baseline_rows(redcap_df)
  if (!is.null(baseline_rows)) {
    return(baseline_rows)
  }
  if (!"year" %in% names(redcap_df)) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  be_reduce_redcap_rows(
    redcap_df[redcap_df$year == "baseline", , drop = FALSE],
    "participant_id"
  )
}

be_build_export_context <- function(spec, shared_root) {
  participant_ids <- be_resolve_cohort_ids(spec)
  years <- spec$cohort$years %||% NULL
  cat_labels <- spec$options$cat_labels %||% "named"
  raw_redcap_df <- be_read_redcap_snapshot(shared_root)
  prepared_redcap_df <- be_prepare_redcap_snapshot(raw_redcap_df)
  labels_redcap_df <- if (identical(cat_labels, "named")) {
    be_read_redcap_labels_snapshot(shared_root)
  } else {
    NULL
  }
  prepared_labels_redcap_df <- if (!is.null(labels_redcap_df)) {
    be_prepare_redcap_snapshot(labels_redcap_df)
  } else {
    NULL
  }
  participant_redcap_df <- be_build_export_participant_redcap(
    prepared_redcap_df = prepared_redcap_df,
    participant_ids = participant_ids
  )
  participant_labels_redcap_df <- if (!is.null(prepared_labels_redcap_df)) {
    be_build_export_participant_redcap(
      prepared_redcap_df = prepared_labels_redcap_df,
      participant_ids = participant_ids
    )
  } else {
    NULL
  }
  domain_redcap_df <- be_build_export_domain_redcap(
    participant_redcap_df = participant_redcap_df,
    years = years
  )
  domain_labels_redcap_df <- if (!is.null(participant_labels_redcap_df)) {
    be_build_export_domain_redcap(
      participant_redcap_df = participant_labels_redcap_df,
      years = years
    )
  } else {
    NULL
  }
  baseline_demographics <- be_baseline_demographics(prepared_redcap_df)
  baseline_labels_demographics <- if (!is.null(prepared_labels_redcap_df)) {
    be_baseline_demographics(prepared_labels_redcap_df)
  } else {
    NULL
  }
  baseline_redcap_rows <- be_export_baseline_rows(domain_redcap_df)
  baseline_labels_redcap_rows <- if (!is.null(domain_labels_redcap_df)) {
    be_export_baseline_rows(domain_labels_redcap_df)
  } else {
    NULL
  }
  scaffold <- be_build_export_scaffold(domain_redcap_df)

  list(
    participant_ids = participant_ids,
    raw_redcap_df = raw_redcap_df,
    labels_redcap_df = labels_redcap_df,
    prepared_redcap_df = prepared_redcap_df,
    prepared_labels_redcap_df = prepared_labels_redcap_df,
    participant_redcap_df = participant_redcap_df,
    participant_labels_redcap_df = participant_labels_redcap_df,
    domain_redcap_df = domain_redcap_df,
    domain_labels_redcap_df = domain_labels_redcap_df,
    baseline_demographics = baseline_demographics,
    baseline_labels_demographics = baseline_labels_demographics,
    baseline_redcap_rows = baseline_redcap_rows,
    baseline_labels_redcap_rows = baseline_labels_redcap_rows,
    scaffold = scaffold
  )
}

be_build_export_participant_redcap <- function(
  prepared_redcap_df,
  participant_ids = NULL
) {
  participant_redcap_df <- prepared_redcap_df

  if (!is.null(participant_ids) && length(participant_ids)) {
    participant_redcap_df <- be_filter_participants(
      participant_redcap_df,
      participant_ids = participant_ids
    )
    participant_redcap_df <- be_mark_prepared_redcap_snapshot(
      participant_redcap_df
    )
  }

  participant_redcap_df
}

be_build_export_domain_redcap <- function(participant_redcap_df, years = NULL) {
  domain_redcap_df <- be_filter_years(participant_redcap_df, years)
  be_attach_redcap_reductions(domain_redcap_df)
}

be_build_export_scaffold <- function(domain_redcap_df) {
  be_build_core_scaffold_domain(domain_redcap_df)
}

be_build_export_intermediates <- function(
  domains,
  spec,
  shared_root,
  export_context
) {
  years <- spec$cohort$years %||% NULL
  intermediates <- list(
    participant_scaffold = be_build_core_scaffold_domain(
      export_context$participant_redcap_df,
      years = years
    ),
    participant_year_rows = be_participant_year_rows_input(
      export_context$domain_redcap_df,
      years = years
    )
  )

  if ("participants" %in% domains) {
    intermediates$participants_base <- be_build_participants_base(
      redcap_df = export_context$participant_redcap_df,
      years = years,
      baseline_demographics = export_context$baseline_demographics,
      scaffold = intermediates$participant_scaffold
    )
  }

  if (any(c("ses", "aria") %in% domains)) {
    intermediates$demographics <- be_build_demographics_domain(
      redcap_df = export_context$domain_redcap_df,
      years = years
    )
    intermediates$ses_lookup <- be_read_ses_lookup(shared_root)
  }

  if ("aria" %in% domains) {
    intermediates$ses <- be_build_ses_domain(
      redcap_df = export_context$domain_redcap_df,
      shared_root = shared_root,
      years = years,
      demographics = intermediates$demographics,
      ses_lookup = intermediates$ses_lookup
    )
    intermediates$aria_lookup <- be_read_aria_lookup(shared_root)
  }

  if ("mri" %in% domains) {
    intermediates$mri_lookup <- be_read_mri_lookup(shared_root)
  }

  if ("biomarkers" %in% domains) {
    intermediates$biomarkers_wide <- be_read_biomarkers_wide(shared_root)
  }

  if ("genomics" %in% domains) {
    intermediates$genomics_participant <- be_build_genomics_participant_domain(
      redcap_df = export_context$domain_redcap_df,
      years = years
    )
  }

  if (any(c("psg_summary", "psg_full") %in% domains)) {
    intermediates$psg_lookup <- be_read_psg_lookup(shared_root)
    intermediates$psg_external_base <- be_build_psg_external_base(
      redcap_df = export_context$domain_redcap_df,
      shared_root = shared_root,
      years = years,
      scaffold = export_context$scaffold,
      psg_lookup = intermediates$psg_lookup
    )
  }

  if ("psg_powerspec" %in% domains) {
    intermediates$psg_powerspec_wide <- be_read_psg_powerspec_wide(shared_root)
  }

  intermediates
}

be_supported_export_domains <- function() {
  c(
    "participants",
    "participant_screening",
    "mri_screening",
    "mri",
    "lp_screening",
    "lp",
    "moca",
    "ad8",
    "ucla",
    "demographics",
    "cesd",
    "stai",
    "pss",
    "cdrisc",
    "das",
    "informant_das",
    "mfi",
    "ses",
    "aria",
    "ipaq",
    "rhhi",
    "minddiet",
    "alcohol",
    "cfi",
    "global_health",
    "biomarkers",
    "genomics",
    "bloods",
    "vitals",
    "bp24h",
    "medical_history",
    "cdr",
    "mmse",
    "sydbat",
    "logical_memory",
    "visual_reproduction",
    "tmt",
    "fab",
    "cowat",
    "hvot",
    "tasit",
    "topf",
    "dementia_status",
    "psqi",
    "ess",
    "isi",
    "psg_screening",
    "psg_sleephealth",
    "psg_sleepmed",
    "psg_morningquest",
    "psg_summary",
    "psg_full",
    "psg_powerspec",
    "actigraphy_full",
    "actigraphy_summary",
    "similarities",
    "prose_passages",
    "cognitive_screening",
    "medications"
  )
}

be_export_domain_registry <- function(
  shared_root,
  years = NULL,
  cat_labels = "named",
  export_context,
  export_intermediates
) {
  redcap_df <- export_context$domain_redcap_df
  scaffold <- export_context$scaffold

  list(
    participants = list(
      level = "event",
      build = function() {
        be_build_participants_domain(
          redcap_df = export_context$participant_redcap_df,
          years = years,
          baseline_demographics = export_context$baseline_demographics,
          scaffold = export_intermediates$participant_scaffold,
          participants_base = export_intermediates$participants_base
        )
      }
    ),
    participant_screening = list(
      level = "participant",
      build = function() {
        be_build_participant_screening_domain(
          export_context$participant_redcap_df,
          baseline_demographics = export_context$baseline_demographics
        )
      }
    ),
    mri_screening = list(level = "event", build = function() {
      be_build_mri_screening_domain(redcap_df = redcap_df)
    }),
    mri = list(level = "event", build = function() {
      be_build_mri_domain(
        redcap_df = redcap_df,
        shared_root = shared_root,
        mri_lookup = export_intermediates$mri_lookup
      )
    }),
    lp_screening = list(level = "event", build = function() {
      be_build_lp_screening_domain(redcap_df = redcap_df)
    }),
    lp = list(level = "event", build = function() {
      be_build_lp_domain(redcap_df = redcap_df)
    }),
    moca = list(level = "event", build = function() {
      be_build_moca_domain(
        redcap_df = redcap_df,
        years = years,
        participant_year_rows = export_intermediates$participant_year_rows
      )
    }),
    ad8 = list(level = "event", build = function() {
      be_build_ad8_domain(
        redcap_df = redcap_df,
        years = years,
        participant_year_rows = export_intermediates$participant_year_rows
      )
    }),
    ucla = list(level = "event", build = function() {
      be_build_ucla_domain(
        redcap_df = redcap_df,
        years = years,
        participant_year_rows = export_intermediates$participant_year_rows
      )
    }),
    demographics = list(level = "event", build = function() {
      export_intermediates$demographics %||%
        be_build_demographics_domain(redcap_df = redcap_df, years = years)
    }),
    cesd = list(level = "event", build = function() {
      be_build_cesd_domain(redcap_df = redcap_df, years = years)
    }),
    stai = list(level = "event", build = function() {
      be_build_stai_domain(redcap_df = redcap_df, years = years)
    }),
    pss = list(level = "event", build = function() {
      be_build_pss_domain(redcap_df = redcap_df, years = years)
    }),
    cdrisc = list(level = "event", build = function() {
      be_build_cdrisc_domain(redcap_df = redcap_df, years = years)
    }),
    das = list(level = "event", build = function() {
      be_build_das_domain(redcap_df = redcap_df, years = years)
    }),
    informant_das = list(level = "event", build = function() {
      be_build_informant_das_domain(redcap_df = redcap_df, years = years)
    }),
    mfi = list(level = "event", build = function() {
      be_build_mfi_domain(redcap_df = redcap_df, years = years)
    }),
    ses = list(level = "event", build = function() {
      export_intermediates$ses %||%
        be_build_ses_domain(
          redcap_df = redcap_df,
          shared_root = shared_root,
          years = years,
          demographics = export_intermediates$demographics,
          ses_lookup = export_intermediates$ses_lookup
        )
    }),
    aria = list(level = "event", build = function() {
      be_build_aria_domain(
        redcap_df = redcap_df,
        shared_root = shared_root,
        years = years,
        ses = export_intermediates$ses,
        demographics = export_intermediates$demographics,
        ses_lookup = export_intermediates$ses_lookup,
        aria_lookup = export_intermediates$aria_lookup
      )
    }),
    ipaq = list(level = "event", build = function() {
      be_build_ipaq_domain(redcap_df = redcap_df, years = years)
    }),
    rhhi = list(level = "event", build = function() {
      be_build_rhhi_domain(redcap_df = redcap_df, years = years)
    }),
    minddiet = list(level = "event", build = function() {
      be_build_minddiet_domain(redcap_df = redcap_df, years = years)
    }),
    alcohol = list(level = "event", build = function() {
      be_build_alcohol_domain(redcap_df = redcap_df, years = years)
    }),
    cfi = list(level = "event", build = function() {
      be_build_cfi_domain(redcap_df = redcap_df, years = years)
    }),
    global_health = list(level = "event", build = function() {
      be_build_global_health_domain(redcap_df = redcap_df, years = years)
    }),
    biomarkers = list(level = "event", build = function() {
      be_build_biomarkers_domain(
        redcap_df = redcap_df,
        shared_root = shared_root,
        years = years,
        scaffold = scaffold,
        biomarker_wide = export_intermediates$biomarkers_wide
      )
    }),
    genomics = list(level = "event", build = function() {
      be_build_genomics_domain(
        redcap_df = redcap_df,
        years = years,
        scaffold = scaffold,
        genomics_participant = export_intermediates$genomics_participant
      )
    }),
    bloods = list(level = "event", build = function() {
      be_build_bloods_domain(redcap_df = redcap_df, years = years)
    }),
    vitals = list(level = "event", build = function() {
      be_build_vitals_domain(redcap_df = redcap_df, years = years)
    }),
    bp24h = list(level = "event", build = function() {
      be_build_bp24h_domain(redcap_df = redcap_df, years = years)
    }),
    medical_history = list(
      level = "event",
      build = function() {
        be_build_medical_history_domain(redcap_df = redcap_df, years = years)
      },
      allow_duplicate_keys = TRUE
    ),
    cdr = list(level = "event", build = function() {
      be_build_cdr_domain(redcap_df = redcap_df, years = years)
    }),
    mmse = list(level = "event", build = function() {
      be_build_mmse_domain(redcap_df = redcap_df, years = years)
    }),
    sydbat = list(level = "event", build = function() {
      be_build_sydbat_domain(redcap_df = redcap_df, years = years)
    }),
    logical_memory = list(level = "event", build = function() {
      be_build_logical_memory_domain(redcap_df = redcap_df, years = years)
    }),
    visual_reproduction = list(level = "event", build = function() {
      be_build_visual_reproduction_domain(redcap_df = redcap_df, years = years)
    }),
    tmt = list(level = "event", build = function() {
      be_build_tmt_domain(redcap_df = redcap_df, years = years)
    }),
    fab = list(level = "event", build = function() {
      be_build_fab_domain(redcap_df = redcap_df, years = years)
    }),
    cowat = list(level = "event", build = function() {
      be_build_cowat_domain(redcap_df = redcap_df, years = years)
    }),
    hvot = list(level = "event", build = function() {
      be_build_hvot_domain(redcap_df = redcap_df, years = years)
    }),
    tasit = list(level = "event", build = function() {
      be_build_tasit_domain(redcap_df = redcap_df, years = years)
    }),
    topf = list(level = "event", build = function() {
      be_build_topf_domain(redcap_df = redcap_df, years = years)
    }),
    dementia_status = list(level = "event", build = function() {
      be_build_dementia_status_domain(redcap_df = redcap_df, years = years)
    }),
    psqi = list(level = "event", build = function() {
      be_build_psqi_domain(redcap_df = redcap_df, years = years)
    }),
    ess = list(level = "event", build = function() {
      be_build_ess_domain(redcap_df = redcap_df, years = years)
    }),
    isi = list(level = "event", build = function() {
      be_build_isi_domain(redcap_df = redcap_df, years = years)
    }),
    psg_screening = list(level = "event", build = function() {
      be_build_psg_screening_domain(redcap_df = redcap_df, years = years)
    }),
    psg_sleephealth = list(level = "event", build = function() {
      be_build_psg_sleephealth_domain(redcap_df = redcap_df, years = years)
    }),
    psg_sleepmed = list(level = "event", build = function() {
      be_build_psg_sleepmed_domain(redcap_df = redcap_df, years = years)
    }),
    psg_morningquest = list(level = "event", build = function() {
      be_build_psg_morningquest_domain(redcap_df = redcap_df, years = years)
    }),
    psg_summary = list(level = "event", build = function() {
      be_build_psg_summary_domain(
        redcap_df = redcap_df,
        shared_root = shared_root,
        years = years,
        scaffold = scaffold,
        psg_lookup = export_intermediates$psg_lookup,
        psg_base = export_intermediates$psg_external_base
      )
    }),
    psg_full = list(level = "event", build = function() {
      be_build_psg_full_domain(
        redcap_df = redcap_df,
        shared_root = shared_root,
        years = years,
        cat_labels = cat_labels,
        scaffold = scaffold,
        psg_lookup = export_intermediates$psg_lookup,
        psg_base = export_intermediates$psg_external_base
      )
    }),
    psg_powerspec = list(level = "event", build = function() {
      be_build_psg_powerspec_domain(
        redcap_df = redcap_df,
        shared_root = shared_root,
        years = years,
        scaffold = scaffold,
        powerspec_wide = export_intermediates$psg_powerspec_wide
      )
    }),
    actigraphy_full = list(level = "event", build = function() {
      be_build_actigraphy_full_domain(redcap_df = redcap_df, years = years)
    }),
    actigraphy_summary = list(level = "event", build = function() {
      be_build_actigraphy_summary_domain(redcap_df = redcap_df, years = years)
    }),
    similarities = list(level = "event", build = function() {
      be_build_similarities_domain(
        redcap_df = redcap_df,
        years = years,
        participant_year_rows = export_intermediates$participant_year_rows
      )
    }),
    prose_passages = list(level = "event", build = function() {
      be_build_prose_passages_domain(
        redcap_df = redcap_df,
        years = years,
        participant_year_rows = export_intermediates$participant_year_rows
      )
    }),
    cognitive_screening = list(level = "event", build = function() {
      be_build_cognitive_screening_domain(
        redcap_df = redcap_df,
        years = years,
        participant_year_rows = export_intermediates$participant_year_rows
      )
    }),
    medications = list(level = "event", build = function() {
      be_build_medications_wide_domain(
        redcap_df = redcap_df,
        years = years,
        scaffold = scaffold,
        baseline_demographics = export_context$baseline_demographics
      )
    })
  )
}

be_build_export_domain_output <- function(
  domain,
  shared_root,
  years = NULL,
  cat_labels = "named",
  export_context,
  export_intermediates
) {
  domain_registry <- be_export_domain_registry(
    shared_root = shared_root,
    years = years,
    cat_labels = cat_labels,
    export_context = export_context,
    export_intermediates = export_intermediates
  )
  entry <- domain_registry[[domain]]

  if (is.null(entry)) {
    stop(sprintf("Unsupported export domain target: %s", domain), call. = FALSE)
  }

  data <- entry$build()
  list(
    domain = domain,
    level = entry$level,
    allow_duplicate_keys = entry$allow_duplicate_keys %||% FALSE,
    data = data,
    source_fields = be_redcap_source_fields(data),
    source_levels = be_redcap_source_levels(data)
  )
}

be_export_output_source_fields <- function(domain_outputs) {
  source_fields <- character()
  for (output in domain_outputs) {
    source_fields <- c(
      source_fields,
      output$source_fields %||% be_redcap_source_fields(output$data)
    )
  }
  source_fields <- source_fields[!is.na(source_fields) & nzchar(source_fields)]
  source_fields[!duplicated(names(source_fields))]
}

be_export_output_source_levels <- function(domain_outputs) {
  source_levels <- character()
  for (output in domain_outputs) {
    fields <- output$source_fields %||% be_redcap_source_fields(output$data)
    levels <- output$source_levels %||% be_redcap_source_levels(output$data)
    if (!length(fields)) {
      next
    }
    if (!length(levels)) {
      levels <- stats::setNames(rep("event", length(fields)), names(fields))
    }
    missing_levels <- setdiff(names(fields), names(levels))
    if (length(missing_levels)) {
      levels <- c(
        levels,
        stats::setNames(rep("event", length(missing_levels)), missing_levels)
      )
    }
    source_levels <- c(source_levels, levels[names(fields)])
  }
  source_levels <- source_levels[!is.na(source_levels) & nzchar(source_levels)]
  source_levels[!duplicated(names(source_levels))]
}

be_reduce_export_domain_outputs <- function(domain_outputs, scaffold = NULL) {
  event_outputs <- Filter(
    function(output) identical(output$level %||% NULL, "event"),
    domain_outputs
  )
  unique_event_outputs <- Filter(
    function(output) !isTRUE(output$allow_duplicate_keys %||% FALSE),
    event_outputs
  )
  multirow_event_outputs <- Filter(
    function(output) isTRUE(output$allow_duplicate_keys %||% FALSE),
    event_outputs
  )
  participant_outputs <- Filter(
    function(output) identical(output$level %||% NULL, "participant"),
    domain_outputs
  )

  event_seed_outputs <- c(
    unique_event_outputs,
    lapply(multirow_event_outputs, function(output) {
      output$data <- be_unique_key_rows(
        be_standardize_event_domain(output$data),
        be_event_key_columns()
      )
      output$allow_duplicate_keys <- FALSE
      output
    })
  )
  event_output <- be_build_event_output_accumulator(
    event_seed_outputs,
    scaffold
  )
  participant_output <- be_build_participant_output_accumulator(
    participant_outputs
  )

  if (is.null(event_output)) {
    return(participant_output)
  }

  if (!is.null(participant_output) && nrow(participant_output)) {
    event_output <- be_attach_keyed_columns(
      output = event_output,
      domain_df = be_standardize_participant_domain(participant_output),
      key_columns = be_participant_key_columns(),
      domain_label = "participant_outputs"
    )
  }

  for (event_output_entry in multirow_event_outputs) {
    event_output <- be_expand_keyed_rows(
      output = event_output,
      domain_df = be_standardize_event_domain(event_output_entry$data),
      key_columns = be_event_key_columns()
    )
  }

  event_output
}

be_finalize_export_output <- function(output, scaffold) {
  if (is.null(output)) {
    stop("No supported domains were selected for export.", call. = FALSE)
  }

  scaffold_keys <- c("participant_id", "event_name", "year")
  scaffold_columns <- c("subject_id", "session", "session_date")
  if (
    nrow(scaffold) &&
      all(scaffold_keys %in% names(output))
  ) {
    missing_scaffold_columns <- setdiff(scaffold_columns, names(output))
    if (length(missing_scaffold_columns)) {
      output <- be_attach_keyed_columns(
        output = be_standardize_event_domain(output),
        domain_df = scaffold[,
          c(scaffold_keys, missing_scaffold_columns),
          drop = FALSE
        ],
        key_columns = scaffold_keys,
        domain_label = "scaffold"
      )
    }
  }

  output
}

be_export_label_key <- function(df, key_columns) {
  if (is.null(df) || !nrow(df) || !all(key_columns %in% names(df))) {
    return(character())
  }

  do.call(
    paste,
    c(
      lapply(df[key_columns], function(column) {
        values <- as.character(column)
        values[is.na(values)] <- "<NA>"
        values
      }),
      sep = "\r"
    )
  )
}

be_has_export_label_value <- function(values) {
  !is.na(values) & nzchar(trimws(as.character(values)))
}

be_apply_labels_for_key <- function(
  output,
  raw_df,
  labels_df,
  key_columns,
  source_fields = NULL
) {
  if (
    is.null(output) ||
      is.null(raw_df) ||
      is.null(labels_df) ||
      !nrow(output) ||
      !nrow(raw_df) ||
      !nrow(labels_df) ||
      !all(key_columns %in% names(output)) ||
      !all(key_columns %in% names(raw_df)) ||
      !all(key_columns %in% names(labels_df))
  ) {
    return(output)
  }

  if (is.null(source_fields)) {
    candidate_columns <- intersect(names(output), names(raw_df))
    candidate_columns <- intersect(candidate_columns, names(labels_df))
    candidate_columns <- setdiff(candidate_columns, key_columns)
    source_fields <- stats::setNames(candidate_columns, candidate_columns)
  } else {
    source_fields <- source_fields[names(source_fields) %in% names(output)]
    source_fields <- source_fields[source_fields %in% names(raw_df)]
    source_fields <- source_fields[source_fields %in% names(labels_df)]
    source_fields <- source_fields[!names(source_fields) %in% key_columns]
  }
  if (!length(source_fields)) {
    return(output)
  }

  output_key <- be_export_label_key(output, key_columns)
  raw_key <- be_export_label_key(raw_df, key_columns)
  match_rows <- match(output_key, raw_key)
  matched <- !is.na(match_rows)
  if (!any(matched)) {
    return(output)
  }

  for (column in names(source_fields)) {
    source_column <- unname(source_fields[[column]])
    raw_values <- raw_df[[source_column]][match_rows]
    label_values <- labels_df[[source_column]][match_rows]
    output_values <- output[[column]]

    replace <- matched &
      be_has_export_label_value(label_values) &
      as.character(label_values) != as.character(raw_values) &
      as.character(output_values) == as.character(raw_values)
    replace[is.na(replace)] <- FALSE

    if (!any(replace, na.rm = TRUE)) {
      next
    }

    output[[column]] <- as.character(output[[column]])
    output[[column]][replace] <- as.character(label_values[replace])
  }

  output
}

be_apply_participant_labels <- function(
  output,
  raw_demographics,
  labels_demographics,
  source_fields = NULL
) {
  be_apply_labels_for_key(
    output = output,
    raw_df = raw_demographics,
    labels_df = labels_demographics,
    key_columns = "participant_id",
    source_fields = source_fields
  )
}

be_apply_event_labels <- function(
  output,
  raw_redcap_df,
  labels_redcap_df,
  source_fields = NULL
) {
  be_apply_labels_for_key(
    output = output,
    raw_df = raw_redcap_df,
    labels_df = labels_redcap_df,
    key_columns = c("participant_id", "event_name", "year"),
    source_fields = source_fields
  )
}

be_apply_participant_year_labels <- function(
  output,
  raw_redcap_df,
  labels_redcap_df,
  source_fields = NULL
) {
  be_apply_labels_for_key(
    output = output,
    raw_df = raw_redcap_df,
    labels_df = labels_redcap_df,
    key_columns = c("participant_id", "year"),
    source_fields = source_fields
  )
}

be_apply_export_label_mode <- function(
  output,
  cat_labels = "named",
  export_context,
  source_fields = NULL,
  source_levels = NULL
) {
  if (!identical(cat_labels, "named")) {
    return(output)
  }

  source_fields <- source_fields %||% character()
  source_levels <- source_levels %||% character()
  identity_source_fields <- stats::setNames(names(output), names(output))
  all_source_fields <- c(source_fields, identity_source_fields)
  all_source_fields <- all_source_fields[!duplicated(names(all_source_fields))]

  missing_levels <- setdiff(names(all_source_fields), names(source_levels))
  if (length(missing_levels)) {
    source_levels <- c(
      source_levels,
      stats::setNames(rep("event", length(missing_levels)), missing_levels)
    )
  }
  source_levels <- source_levels[names(all_source_fields)]

  fields_by_level <- split(all_source_fields, source_levels)

  event_fields <- fields_by_level[["event"]] %||% character()
  if (length(event_fields)) {
    output <- be_apply_event_labels(
      output = output,
      raw_redcap_df = export_context$domain_redcap_df,
      labels_redcap_df = export_context$domain_labels_redcap_df,
      source_fields = event_fields
    )
  }

  participant_year_fields <- fields_by_level[["participant_year"]] %||%
    character()
  if (length(participant_year_fields)) {
    output <- be_apply_participant_year_labels(
      output = output,
      raw_redcap_df = export_context$domain_redcap_df,
      labels_redcap_df = export_context$domain_labels_redcap_df,
      source_fields = participant_year_fields
    )
  }

  participant_fields <- fields_by_level[["participant_baseline"]] %||%
    character()
  if (length(participant_fields)) {
    output <- be_apply_participant_labels(
      output = output,
      raw_demographics = export_context$baseline_redcap_rows %||%
        export_context$baseline_demographics,
      labels_demographics = export_context$baseline_labels_redcap_rows %||%
        export_context$baseline_labels_demographics,
      source_fields = participant_fields
    )
  }

  output
}

be_assemble_export <- function(spec, shared_root) {
  domains <- unique(spec$domains %||% character())
  supported_domains <- be_supported_export_domains()
  unsupported_domains <- setdiff(domains, supported_domains)
  if (length(unsupported_domains)) {
    stop(
      sprintf(
        "The following domains are not implemented yet: %s",
        paste(unsupported_domains, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  export_context <- be_build_export_context(spec, shared_root)
  export_intermediates <- be_build_export_intermediates(
    domains = domains,
    spec = spec,
    shared_root = shared_root,
    export_context = export_context
  )
  scaffold <- export_context$scaffold
  domain_outputs <- lapply(
    domains,
    be_build_export_domain_output,
    shared_root = shared_root,
    years = spec$cohort$years %||% NULL,
    cat_labels = spec$options$cat_labels %||% "named",
    export_context = export_context,
    export_intermediates = export_intermediates
  )

  output <- be_finalize_export_output(
    output = be_reduce_export_domain_outputs(
      domain_outputs,
      scaffold = scaffold
    ),
    scaffold = scaffold
  )
  be_apply_export_label_mode(
    output = output,
    cat_labels = spec$options$cat_labels %||% "named",
    export_context = export_context,
    source_fields = be_export_output_source_fields(domain_outputs),
    source_levels = be_export_output_source_levels(domain_outputs)
  )
}
