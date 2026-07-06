be_build_genomics_participant_domain <- function(redcap_df, years = NULL) {
  genomics <- be_build_baseline_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      aqp4_allele1 = "aqp4_allele1",
      aqp4_dosage1 = "aqp4_dosage1",
      aqp4_allele2 = "aqp4_allele2",
      aqp4_dosage2 = "aqp4_dosage2",
      aqp4_allele3 = "aqp4_allele3",
      aqp4_dosage3 = "aqp4_dosage3",
      apoe_allele1 = "apoe_allele1",
      apoe_dosage1 = "apoe_dosage1",
      apoe_allele2 = "apoe_allele2",
      apoe_dosage2 = "apoe_dosage2"
    )
  )

  if (!nrow(genomics)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  genomics$aqp4_genotype <- be_derive_aqp4_genotype(
    genomics$aqp4_allele1 %||% NA,
    genomics$aqp4_allele2 %||% NA,
    genomics$aqp4_allele3 %||% NA
  )
  genomics$aqp4_status <- be_derive_aqp4_status(genomics$aqp4_genotype)

  genomics$apoe_allele1 <- be_normalize_apoe_allele1(
    genomics$apoe_allele1 %||% NA
  )
  genomics$apoe_allele2 <- be_normalize_apoe_allele2(
    genomics$apoe_allele2 %||% NA
  )
  genomics$apoe_genotype <- be_derive_apoe_genotype(
    genomics$apoe_allele1 %||% NA,
    genomics$apoe_allele2 %||% NA
  )
  genomics$apoe_e4_status <- be_derive_apoe_e4_status(genomics$apoe_genotype)

  genomics <- be_drop_empty_columns(genomics)
  genomics <- genomics[,
    setdiff(names(genomics), c("event_name", "year")),
    drop = FALSE
  ]
  genomics <- unique(genomics)
  rownames(genomics) <- NULL
  be_set_redcap_source_fields(
    genomics,
    stats::setNames(
      c(
        "aqp4_allele1",
        "aqp4_dosage1",
        "aqp4_allele2",
        "aqp4_dosage2",
        "aqp4_allele3",
        "aqp4_dosage3",
        "apoe_allele1",
        "apoe_dosage1",
        "apoe_allele2",
        "apoe_dosage2"
      ),
      c(
        "aqp4_allele1",
        "aqp4_dosage1",
        "aqp4_allele2",
        "aqp4_dosage2",
        "aqp4_allele3",
        "aqp4_dosage3",
        "apoe_allele1",
        "apoe_dosage1",
        "apoe_allele2",
        "apoe_dosage2"
      )
    ),
    source_level = "participant_baseline"
  )
}

be_build_genomics_domain <- function(
  redcap_df,
  years = NULL,
  scaffold = NULL,
  genomics_participant = NULL
) {
  scaffold <- scaffold %||%
    be_build_core_scaffold_domain(redcap_df, years = years)
  if (!nrow(scaffold)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  genomics_participant <- genomics_participant %||%
    be_build_genomics_participant_domain(redcap_df, years = years)
  if (!nrow(genomics_participant)) {
    return(scaffold[, c("participant_id", "event_name", "year"), drop = FALSE])
  }

  output <- scaffold[, c("participant_id", "event_name", "year"), drop = FALSE]
  match_rows <- match(
    output$participant_id,
    genomics_participant$participant_id
  )
  for (column in setdiff(names(genomics_participant), "participant_id")) {
    output[[column]] <- genomics_participant[[column]][match_rows]
  }

  unique(output)
}
