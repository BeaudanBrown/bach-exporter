be_merge_event_domain <- function(output, domain_df) {
  key_columns <- c("participant_id", "event_name", "year")

  if (is.null(output)) {
    return(domain_df)
  }

  overlapping <- intersect(
    setdiff(names(output), key_columns),
    setdiff(names(domain_df), key_columns)
  )
  overlap_suffixes <- paste0(overlapping, c(".x", ".y"))

  merged <- merge(
    output,
    domain_df,
    by = key_columns,
    all.x = TRUE,
    sort = FALSE
  )

  for (column in overlapping) {
    left_name <- paste0(column, ".x")
    right_name <- paste0(column, ".y")
    left_values <- if (left_name %in% names(merged)) {
      merged[[left_name]]
    } else {
      NULL
    }
    right_values <- if (right_name %in% names(merged)) {
      merged[[right_name]]
    } else {
      NULL
    }
    merged[[column]] <- be_coalesce_vectors(left_values, right_values)
  }

  merged <- merged[, !names(merged) %in% overlap_suffixes, drop = FALSE]
  merged
}

be_assemble_export <- function(spec, shared_root) {
  domains <- unique(spec$domains %||% character())
  supported_domains <- c(
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
    "ses",
    "aria",
    "ipaq",
    "rhhi",
    "minddiet",
    "alcohol",
    "cfi",
    "global_health",
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
      be_merge_event_domain(output, mri_screening)
    }
  }

  if ("mri" %in% domains) {
    mri <- be_build_mri_domain(
      redcap_df = redcap_df,
      shared_root = shared_root,
      years = spec$cohort$years %||% NULL
    )
    mri <- be_filter_participants(
      mri,
      participant_ids = participant_ids
    )

    output <- if (is.null(output)) {
      mri
    } else {
      be_merge_event_domain(output, mri)
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
      be_merge_event_domain(output, lp_screening)
    }
  }

  if ("lp" %in% domains) {
    lp <- be_build_lp_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    lp <- be_filter_participants(lp, participant_ids = participant_ids)

    output <- if (is.null(output)) {
      lp
    } else {
      be_merge_event_domain(output, lp)
    }
  }

  if ("moca" %in% domains) {
    moca <- be_build_moca_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    moca <- be_filter_participants(moca, participant_ids = participant_ids)

    output <- if (is.null(output)) {
      moca
    } else {
      be_merge_event_domain(output, moca)
    }
  }

  if ("ad8" %in% domains) {
    ad8 <- be_build_ad8_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    ad8 <- be_filter_participants(ad8, participant_ids = participant_ids)

    output <- if (is.null(output)) {
      ad8
    } else {
      be_merge_event_domain(output, ad8)
    }
  }

  if ("ucla" %in% domains) {
    ucla <- be_build_ucla_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    ucla <- be_filter_participants(ucla, participant_ids = participant_ids)

    output <- if (is.null(output)) {
      ucla
    } else {
      be_merge_event_domain(output, ucla)
    }
  }

  if ("demographics" %in% domains) {
    demographics <- be_build_demographics_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    demographics <- be_filter_participants(
      demographics,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, demographics)
  }

  if ("cesd" %in% domains) {
    cesd <- be_build_cesd_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    cesd <- be_filter_participants(cesd, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, cesd)
  }

  if ("stai" %in% domains) {
    stai <- be_build_stai_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    stai <- be_filter_participants(stai, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, stai)
  }

  if ("pss" %in% domains) {
    pss <- be_build_pss_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    pss <- be_filter_participants(pss, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, pss)
  }

  if ("cdrisc" %in% domains) {
    cdrisc <- be_build_cdrisc_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    cdrisc <- be_filter_participants(cdrisc, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, cdrisc)
  }

  if ("ses" %in% domains) {
    ses <- be_build_ses_domain(
      redcap_df = redcap_df,
      shared_root = shared_root,
      years = spec$cohort$years %||% NULL
    )
    ses <- be_filter_participants(ses, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, ses)
  }

  if ("aria" %in% domains) {
    aria <- be_build_aria_domain(
      redcap_df = redcap_df,
      shared_root = shared_root,
      years = spec$cohort$years %||% NULL
    )
    aria <- be_filter_participants(aria, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, aria)
  }

  if ("ipaq" %in% domains) {
    ipaq <- be_build_ipaq_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    ipaq <- be_filter_participants(ipaq, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, ipaq)
  }

  if ("rhhi" %in% domains) {
    rhhi <- be_build_rhhi_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    rhhi <- be_filter_participants(rhhi, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, rhhi)
  }

  if ("minddiet" %in% domains) {
    minddiet <- be_build_minddiet_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    minddiet <- be_filter_participants(
      minddiet,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, minddiet)
  }

  if ("alcohol" %in% domains) {
    alcohol <- be_build_alcohol_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    alcohol <- be_filter_participants(
      alcohol,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, alcohol)
  }

  if ("cfi" %in% domains) {
    cfi <- be_build_cfi_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    cfi <- be_filter_participants(cfi, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, cfi)
  }

  if ("global_health" %in% domains) {
    global_health <- be_build_global_health_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    global_health <- be_filter_participants(
      global_health,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, global_health)
  }

  if ("bloods" %in% domains) {
    bloods <- be_build_bloods_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    bloods <- be_filter_participants(bloods, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, bloods)
  }

  if ("vitals" %in% domains) {
    vitals <- be_build_vitals_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    vitals <- be_filter_participants(vitals, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, vitals)
  }

  if ("bp24h" %in% domains) {
    bp24h <- be_build_bp24h_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    bp24h <- be_filter_participants(bp24h, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, bp24h)
  }

  if ("medical_history" %in% domains) {
    medical_history <- be_build_medical_history_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    medical_history <- be_filter_participants(
      medical_history,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, medical_history)
  }

  if ("cdr" %in% domains) {
    cdr <- be_build_cdr_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    cdr <- be_filter_participants(cdr, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, cdr)
  }

  if ("mmse" %in% domains) {
    mmse <- be_build_mmse_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    mmse <- be_filter_participants(mmse, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, mmse)
  }

  if ("sydbat" %in% domains) {
    sydbat <- be_build_sydbat_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    sydbat <- be_filter_participants(sydbat, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, sydbat)
  }

  if ("logical_memory" %in% domains) {
    logical_memory <- be_build_logical_memory_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    logical_memory <- be_filter_participants(
      logical_memory,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, logical_memory)
  }

  if ("visual_reproduction" %in% domains) {
    visual_reproduction <- be_build_visual_reproduction_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    visual_reproduction <- be_filter_participants(
      visual_reproduction,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, visual_reproduction)
  }

  if ("tmt" %in% domains) {
    tmt <- be_build_tmt_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    tmt <- be_filter_participants(tmt, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, tmt)
  }

  if ("fab" %in% domains) {
    fab <- be_build_fab_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    fab <- be_filter_participants(fab, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, fab)
  }

  if ("cowat" %in% domains) {
    cowat <- be_build_cowat_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    cowat <- be_filter_participants(cowat, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, cowat)
  }

  if ("hvot" %in% domains) {
    hvot <- be_build_hvot_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    hvot <- be_filter_participants(hvot, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, hvot)
  }

  if ("tasit" %in% domains) {
    tasit <- be_build_tasit_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    tasit <- be_filter_participants(tasit, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, tasit)
  }

  if ("topf" %in% domains) {
    topf <- be_build_topf_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    topf <- be_filter_participants(topf, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, topf)
  }

  if ("dementia_status" %in% domains) {
    dementia_status <- be_build_dementia_status_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    dementia_status <- be_filter_participants(
      dementia_status,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, dementia_status)
  }

  if ("psqi" %in% domains) {
    psqi <- be_build_psqi_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    psqi <- be_filter_participants(psqi, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, psqi)
  }

  if ("ess" %in% domains) {
    ess <- be_build_ess_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    ess <- be_filter_participants(ess, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, ess)
  }

  if ("isi" %in% domains) {
    isi <- be_build_isi_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    isi <- be_filter_participants(isi, participant_ids = participant_ids)
    output <- be_merge_event_domain(output, isi)
  }

  if ("psg_screening" %in% domains) {
    psg_screening <- be_build_psg_screening_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    psg_screening <- be_filter_participants(
      psg_screening,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, psg_screening)
  }

  if ("psg_sleephealth" %in% domains) {
    psg_sleephealth <- be_build_psg_sleephealth_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    psg_sleephealth <- be_filter_participants(
      psg_sleephealth,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, psg_sleephealth)
  }

  if ("psg_sleepmed" %in% domains) {
    psg_sleepmed <- be_build_psg_sleepmed_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    psg_sleepmed <- be_filter_participants(
      psg_sleepmed,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, psg_sleepmed)
  }

  if ("psg_morningquest" %in% domains) {
    psg_morningquest <- be_build_psg_morningquest_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    psg_morningquest <- be_filter_participants(
      psg_morningquest,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, psg_morningquest)
  }

  if ("psg_summary" %in% domains) {
    psg_summary <- be_build_psg_summary_domain(
      redcap_df = redcap_df,
      shared_root = shared_root,
      years = spec$cohort$years %||% NULL
    )
    psg_summary <- be_filter_participants(
      psg_summary,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, psg_summary)
  }

  if ("psg_full" %in% domains) {
    psg_full <- be_build_psg_full_domain(
      redcap_df = redcap_df,
      shared_root = shared_root,
      years = spec$cohort$years %||% NULL,
      cat_labels = spec$options$cat_labels %||% "named"
    )
    psg_full <- be_filter_participants(
      psg_full,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, psg_full)
  }

  if ("psg_powerspec" %in% domains) {
    psg_powerspec <- be_build_psg_powerspec_domain(
      redcap_df = redcap_df,
      shared_root = shared_root,
      years = spec$cohort$years %||% NULL
    )
    psg_powerspec <- be_filter_participants(
      psg_powerspec,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, psg_powerspec)
  }

  if ("actigraphy_full" %in% domains) {
    actigraphy_full <- be_build_actigraphy_full_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    actigraphy_full <- be_filter_participants(
      actigraphy_full,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, actigraphy_full)
  }

  if ("actigraphy_summary" %in% domains) {
    actigraphy_summary <- be_build_actigraphy_summary_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    actigraphy_summary <- be_filter_participants(
      actigraphy_summary,
      participant_ids = participant_ids
    )
    output <- be_merge_event_domain(output, actigraphy_summary)
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
      be_merge_event_domain(output, similarities)
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
      be_merge_event_domain(output, prose_passages)
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
      be_merge_event_domain(output, cognitive_screening)
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
      be_merge_event_domain(output, medications)
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
