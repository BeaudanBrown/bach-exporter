be_export_domain_target_name <- function(domain) {
  paste0(
    "export_domain_",
    gsub("[^A-Za-z0-9]+", "_", domain)
  )
}

be_export_context_target_names <- function() {
  c(
    participant_redcap_df = "export_participant_redcap",
    domain_redcap_df = "export_domain_redcap",
    baseline_demographics = "export_baseline_demographics",
    scaffold = "export_scaffold"
  )
}

be_export_intermediate_target_names <- function() {
  c(
    participant_scaffold = "export_participant_scaffold",
    participants_base = "export_participants_base",
    participant_year_rows = "export_participant_year_rows",
    demographics = "export_demographics",
    ses_lookup = "export_ses_lookup",
    ses = "export_ses",
    aria_lookup = "export_aria_lookup",
    mri_lookup = "export_mri_lookup",
    biomarkers_wide = "export_biomarkers_wide",
    genomics_participant = "export_genomics_participant",
    psg_lookup = "export_psg_lookup",
    psg_external_base = "export_psg_external_base",
    psg_powerspec_wide = "export_psg_powerspec_wide"
  )
}

be_export_domain_target_requirements <- function(domain) {
  requirements <- list(
    context = "domain_redcap_df",
    intermediates = character()
  )

  if (domain %in% c("participants", "participant_screening")) {
    requirements$context <- c(
      "participant_redcap_df",
      "baseline_demographics"
    )
  }
  if (
    domain %in%
      c(
        "biomarkers",
        "genomics",
        "psg_summary",
        "psg_full",
        "psg_powerspec",
        "medications"
      )
  ) {
    requirements$context <- unique(c(requirements$context, "scaffold"))
  }
  if (identical(domain, "medications")) {
    requirements$context <- unique(c(
      requirements$context,
      "baseline_demographics"
    ))
  }

  requirements$intermediates <- switch(
    domain,
    participants = "participants_base",
    moca = "participant_year_rows",
    ad8 = "participant_year_rows",
    ucla = "participant_year_rows",
    similarities = "participant_year_rows",
    prose_passages = "participant_year_rows",
    cognitive_screening = "participant_year_rows",
    demographics = "demographics",
    ses = "ses",
    aria = c("ses", "aria_lookup"),
    mri = "mri_lookup",
    biomarkers = "biomarkers_wide",
    genomics = "genomics_participant",
    psg_summary = "psg_external_base",
    psg_full = "psg_external_base",
    psg_powerspec = "psg_powerspec_wide",
    character()
  )

  requirements
}

be_export_dependency_list_expr <- function(required_fields, target_names) {
  required_fields <- unique(required_fields)
  if (!length(required_fields)) {
    return(quote(list()))
  }

  args <- lapply(required_fields, function(field) {
    as.name(target_names[[field]])
  })
  names(args) <- required_fields
  as.call(c(quote(list), args))
}

be_export_domain_target <- function(domain) {
  target_name <- be_export_domain_target_name(domain)
  requirements <- be_export_domain_target_requirements(domain)
  export_context_expr <- be_export_dependency_list_expr(
    required_fields = requirements$context,
    target_names = be_export_context_target_names()
  )
  export_intermediates_expr <- be_export_dependency_list_expr(
    required_fields = requirements$intermediates,
    target_names = be_export_intermediate_target_names()
  )

  targets::tar_target_raw(
    target_name,
    substitute(
      be_build_export_domain_output(
        domain = domain_name,
        spec = export_spec,
        shared_root = export_shared_root,
        export_context = export_context_value,
        export_intermediates = export_intermediates_value
      ),
      list(
        domain_name = domain,
        export_context_value = export_context_expr,
        export_intermediates_value = export_intermediates_expr
      )
    )
  )
}

be_export_domain_output_target <- function(name, domains, level) {
  selected_names <- vapply(
    domains,
    be_export_domain_target_name,
    character(1)
  )

  if (!length(selected_names)) {
    selected_names <- character()
  }

  build_output_expr <- as.call(c(
    quote(list),
    lapply(selected_names, as.name)
  ))

  targets::tar_target_raw(
    name,
    substitute(
      Filter(
        function(domain_output) identical(domain_output$level, domain_level),
        domain_outputs
      ),
      list(
        domain_outputs = build_output_expr,
        domain_level = level
      )
    )
  )
}

be_target_graph <- function(
  spec = NULL,
  shared_root = NULL,
  refresh_mode = "auto"
) {
  if (is.null(spec) || is.null(shared_root)) {
    return(list(
      targets::tar_target(
        config_release_id,
        "dev"
      ),
      targets::tar_target(
        source_mode,
        "snapshot"
      )
    ))
  }

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

  domain_targets <- lapply(domains, be_export_domain_target)
  needs_demographics <- any(c("demographics", "ses", "aria") %in% domains)
  needs_ses_lookup <- any(c("ses", "aria") %in% domains)
  needs_ses <- any(c("ses", "aria") %in% domains)
  needs_aria_lookup <- "aria" %in% domains
  needs_mri_lookup <- "mri" %in% domains
  needs_biomarkers_wide <- "biomarkers" %in% domains
  needs_genomics_participant <- "genomics" %in% domains
  needs_psg_lookup <- any(c("psg_summary", "psg_full") %in% domains)
  needs_psg_powerspec <- "psg_powerspec" %in% domains
  needs_participant_scaffold <- "participants" %in% domains
  needs_participant_year_rows <- any(
    c(
      "moca",
      "ad8",
      "ucla",
      "similarities",
      "prose_passages",
      "cognitive_screening"
    ) %in%
      domains
  )

  shared_targets <- list(
    targets::tar_target(
      export_spec,
      spec,
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      export_shared_root,
      shared_root,
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      export_refresh_mode,
      refresh_mode,
      cue = targets::tar_cue(mode = "always")
    ),
    targets::tar_target(
      export_participant_ids,
      be_resolve_cohort_ids(export_spec)
    ),
    targets::tar_target(
      export_cohort_years,
      export_spec$cohort$years %||% NULL
    ),
    targets::tar_target(
      export_cat_labels,
      export_spec$options$cat_labels %||% "named"
    ),
    targets::tar_target(
      export_raw_redcap,
      be_read_redcap_snapshot(export_shared_root)
    ),
    targets::tar_target(
      export_labels_redcap,
      if (identical(export_cat_labels, "named")) {
        be_read_redcap_labels_snapshot(export_shared_root)
      } else {
        NULL
      }
    ),
    targets::tar_target(
      export_prepared_redcap,
      be_prepare_redcap_snapshot(export_raw_redcap)
    ),
    targets::tar_target(
      export_prepared_labels_redcap,
      if (!is.null(export_labels_redcap)) {
        be_prepare_redcap_snapshot(export_labels_redcap)
      } else {
        NULL
      }
    ),
    targets::tar_target(
      export_snapshot_index,
      be_read_snapshot_index_safe(export_shared_root)
    ),
    targets::tar_target(
      export_snapshot_metadata_redcap,
      be_read_snapshot_metadata_safe(
        export_shared_root,
        "redcap"
      )
    ),
    targets::tar_target(
      export_snapshot_metadata_psg,
      be_read_snapshot_metadata_safe(export_shared_root, "psg")
    ),
    targets::tar_target(
      export_snapshot_metadata_biomarkers,
      be_read_snapshot_metadata_safe(export_shared_root, "biomarkers")
    ),
    targets::tar_target(
      export_participant_redcap,
      be_build_export_participant_redcap(
        prepared_redcap_df = export_prepared_redcap,
        participant_ids = export_participant_ids
      )
    ),
    targets::tar_target(
      export_participant_labels_redcap,
      if (!is.null(export_prepared_labels_redcap)) {
        be_build_export_participant_redcap(
          prepared_redcap_df = export_prepared_labels_redcap,
          participant_ids = export_participant_ids
        )
      } else {
        NULL
      }
    ),
    targets::tar_target(
      export_domain_redcap,
      be_build_export_domain_redcap(
        participant_redcap_df = export_participant_redcap,
        years = export_cohort_years
      )
    ),
    targets::tar_target(
      export_domain_labels_redcap,
      if (!is.null(export_participant_labels_redcap)) {
        be_build_export_domain_redcap(
          participant_redcap_df = export_participant_labels_redcap,
          years = export_cohort_years
        )
      } else {
        NULL
      }
    ),
    targets::tar_target(
      export_baseline_demographics,
      be_baseline_demographics(export_prepared_redcap)
    ),
    targets::tar_target(
      export_baseline_labels_demographics,
      if (!is.null(export_prepared_labels_redcap)) {
        be_baseline_demographics(export_prepared_labels_redcap)
      } else {
        NULL
      }
    ),
    targets::tar_target(
      export_scaffold,
      be_build_export_scaffold(export_domain_redcap)
    )
  )

  if (isTRUE(needs_participant_scaffold)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_participant_scaffold,
          be_build_core_scaffold_domain(
            export_participant_redcap,
            years = export_cohort_years
          )
        )
      )
    )
  }
  if (isTRUE(needs_participant_scaffold)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_participants_base,
          be_build_participants_base(
            redcap_df = export_participant_redcap,
            years = export_cohort_years,
            baseline_demographics = export_baseline_demographics,
            scaffold = export_participant_scaffold
          )
        )
      )
    )
  }
  if (isTRUE(needs_participant_year_rows)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_participant_year_rows,
          be_participant_year_rows_input(
            export_domain_redcap,
            years = export_cohort_years
          )
        )
      )
    )
  }
  if (isTRUE(needs_demographics)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_demographics,
          be_build_demographics_domain(
            redcap_df = export_domain_redcap,
            years = export_cohort_years
          )
        )
      )
    )
  }
  if (isTRUE(needs_ses_lookup)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_ses_lookup,
          be_read_ses_lookup(export_shared_root)
        )
      )
    )
  }
  if (isTRUE(needs_ses)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_ses,
          be_build_ses_domain(
            redcap_df = export_domain_redcap,
            shared_root = export_shared_root,
            years = export_cohort_years,
            demographics = export_demographics,
            ses_lookup = export_ses_lookup
          )
        )
      )
    )
  }
  if (isTRUE(needs_aria_lookup)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_aria_lookup,
          be_read_aria_lookup(export_shared_root)
        )
      )
    )
  }
  if (isTRUE(needs_mri_lookup)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_mri_lookup,
          be_read_mri_lookup(export_shared_root)
        )
      )
    )
  }
  if (isTRUE(needs_biomarkers_wide)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_biomarkers_wide,
          be_read_biomarkers_wide(export_shared_root)
        )
      )
    )
  }
  if (isTRUE(needs_genomics_participant)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_genomics_participant,
          be_build_genomics_participant_domain(
            redcap_df = export_domain_redcap,
            years = export_cohort_years
          )
        )
      )
    )
  }
  if (isTRUE(needs_psg_lookup)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_psg_lookup,
          be_read_psg_lookup(export_shared_root)
        )
      )
    )
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_psg_external_base,
          be_build_psg_external_base(
            redcap_df = export_domain_redcap,
            shared_root = export_shared_root,
            years = export_cohort_years,
            scaffold = export_scaffold,
            psg_lookup = export_psg_lookup
          )
        )
      )
    )
  }
  if (isTRUE(needs_psg_powerspec)) {
    shared_targets <- c(
      shared_targets,
      list(
        targets::tar_target(
          export_psg_powerspec_wide,
          be_read_psg_powerspec_wide(export_shared_root)
        )
      )
    )
  }

  c(
    shared_targets,
    domain_targets,
    list(
      be_export_domain_output_target(
        name = "participant_domain_outputs",
        domains = domains,
        level = "participant"
      ),
      be_export_domain_output_target(
        name = "event_domain_outputs",
        domains = domains,
        level = "event"
      ),
      targets::tar_target(
        export_data,
        be_apply_export_label_mode(
          output = be_finalize_export_output(
            output = be_reduce_export_domain_outputs(
              c(event_domain_outputs, participant_domain_outputs)
            ),
            scaffold = export_scaffold
          ),
          spec = export_spec,
          export_context = list(
            domain_redcap_df = export_domain_redcap,
            domain_labels_redcap_df = export_domain_labels_redcap,
            baseline_demographics = export_baseline_demographics,
            baseline_labels_demographics = export_baseline_labels_demographics
          ),
          source_fields = be_export_output_source_fields(
            c(event_domain_outputs, participant_domain_outputs)
          )
        )
      ),
      targets::tar_target(
        snapshot_metadata,
        be_build_snapshot_metadata(
          snapshot_index = export_snapshot_index,
          redcap_metadata = export_snapshot_metadata_redcap,
          psg_metadata = export_snapshot_metadata_psg,
          biomarkers_metadata = export_snapshot_metadata_biomarkers
        )
      ),
      targets::tar_target(
        export_manifest,
        be_build_export_manifest(
          spec = export_spec,
          shared_root = export_shared_root,
          refresh_mode = export_refresh_mode,
          snapshot_metadata = snapshot_metadata,
          execution_mode = "targets"
        )
      )
    )
  )
}
