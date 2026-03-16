be_assemble_export <- function(spec, shared_root) {
  domains <- unique(spec$domains %||% character())
  supported_domains <- c(
    "participants",
    "participant_screening",
    "mri_screening",
    "lp_screening",
    "similarities",
    "prose_passages",
    "cognitive_screening",
    "medications"
  )
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

  redcap_df <- be_read_redcap_snapshot(shared_root)
  participant_ids <- be_resolve_cohort_ids(spec)
  scaffold <- be_build_core_scaffold_domain(
    redcap_df = redcap_df,
    years = spec$cohort$years %||% NULL
  )
  scaffold <- be_filter_participants(
    scaffold,
    participant_ids = participant_ids
  )
  output <- NULL

  if ("participants" %in% domains) {
    output <- be_build_participants_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    output <- be_filter_participants(output, participant_ids = participant_ids)
  }

  if ("participant_screening" %in% domains) {
    screening <- be_build_participant_screening_domain(redcap_df)
    screening <- be_filter_participants(
      screening,
      participant_ids = participant_ids
    )

    output <- if (is.null(output)) {
      screening
    } else {
      merge(
        output,
        screening,
        by = "participant_id",
        all.x = TRUE,
        sort = FALSE
      )
    }
  }

  if ("mri_screening" %in% domains) {
    mri_screening <- be_build_mri_screening_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    mri_screening <- be_filter_participants(
      mri_screening,
      participant_ids = participant_ids
    )

    output <- if (is.null(output)) {
      mri_screening
    } else {
      merge(
        output,
        mri_screening,
        by = c("participant_id", "event_name", "year"),
        all.x = TRUE,
        sort = FALSE
      )
    }
  }

  if ("lp_screening" %in% domains) {
    lp_screening <- be_build_lp_screening_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    lp_screening <- be_filter_participants(
      lp_screening,
      participant_ids = participant_ids
    )

    output <- if (is.null(output)) {
      lp_screening
    } else {
      merge(
        output,
        lp_screening,
        by = c("participant_id", "event_name", "year"),
        all.x = TRUE,
        sort = FALSE
      )
    }
  }

  if ("similarities" %in% domains) {
    similarities <- be_build_similarities_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    similarities <- be_filter_participants(
      similarities,
      participant_ids = participant_ids
    )

    output <- if (is.null(output)) {
      similarities
    } else {
      merge(
        output,
        similarities,
        by = c("participant_id", "event_name", "year"),
        all.x = TRUE,
        sort = FALSE
      )
    }
  }

  if ("prose_passages" %in% domains) {
    prose_passages <- be_build_prose_passages_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    prose_passages <- be_filter_participants(
      prose_passages,
      participant_ids = participant_ids
    )

    output <- if (is.null(output)) {
      prose_passages
    } else {
      merge(
        output,
        prose_passages,
        by = c("participant_id", "event_name", "year"),
        all.x = TRUE,
        sort = FALSE
      )
    }
  }

  if ("cognitive_screening" %in% domains) {
    cognitive_screening <- be_build_cognitive_screening_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    cognitive_screening <- be_filter_participants(
      cognitive_screening,
      participant_ids = participant_ids
    )

    output <- if (is.null(output)) {
      cognitive_screening
    } else {
      merge(
        output,
        cognitive_screening,
        by = c("participant_id", "event_name", "year"),
        all.x = TRUE,
        sort = FALSE
      )
    }
  }

  if ("medications" %in% domains) {
    medication_long_only <- identical(sort(domains), "medications")
    medications <- if (medication_long_only) {
      be_build_medications_domain(
        redcap_df = redcap_df,
        years = spec$cohort$years %||% NULL
      )
    } else {
      be_build_medications_wide_domain(
        redcap_df = redcap_df,
        years = spec$cohort$years %||% NULL
      )
    }
    medications <- be_filter_participants(
      medications,
      participant_ids = participant_ids
    )

    output <- if (is.null(output)) {
      medications
    } else {
      merge(
        output,
        medications,
        by = c("participant_id", "event_name", "year"),
        all.x = TRUE,
        sort = FALSE
      )
    }
  }

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
      output <- merge(
        output,
        scaffold[, c(scaffold_keys, missing_scaffold_columns), drop = FALSE],
        by = scaffold_keys,
        all.x = TRUE,
        sort = FALSE
      )
    }
  }

  output
}
