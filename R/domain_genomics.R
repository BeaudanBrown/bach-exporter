be_build_genomics_domain <- function(redcap_df, years = NULL) {
  scaffold <- be_build_core_scaffold_domain(redcap_df, years = years)
  if (!nrow(scaffold)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

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
    return(scaffold[, c("participant_id", "event_name", "year"), drop = FALSE])
  }

  genomics$aqp4_genotype <- be_derive_aqp4_genotype(
    genomics$aqp4_allele1 %||% NA,
    genomics$aqp4_allele2 %||% NA,
    genomics$aqp4_allele3 %||% NA
  )
  genomics$aqp4_status <- be_derive_aqp4_status(genomics$aqp4_genotype)

  genomics$apoe_genotype <- be_derive_apoe_genotype(
    genomics$apoe_allele1 %||% NA,
    genomics$apoe_allele2 %||% NA
  )
  genomics$apoe_e4_status <- be_derive_apoe_e4_status(genomics$apoe_genotype)

  genomics <- be_drop_empty_columns(genomics)
  rownames(genomics) <- NULL
  merge(
    scaffold[, c("participant_id", "event_name", "year"), drop = FALSE],
    genomics[, !names(genomics) %in% c("event_name", "year"), drop = FALSE],
    by = "participant_id",
    all.x = TRUE,
    sort = FALSE
  )
}
