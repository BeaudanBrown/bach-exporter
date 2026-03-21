be_genomics_string <- function(x) {
  values <- trimws(as.character(x))
  values[!nzchar(values)] <- NA_character_
  toupper(values)
}

be_derive_aqp4_genotype <- function(allele1, allele2, allele3) {
  allele1 <- be_genomics_string(allele1)
  allele2 <- be_genomics_string(allele2)
  allele3 <- be_genomics_string(allele3)

  ifelse(
    is.na(allele1) | is.na(allele2) | is.na(allele3),
    NA_character_,
    ifelse(
      allele1 == "AA" & allele2 == "AA" & allele3 == "TT",
      "homozygous_major",
      ifelse(
        allele1 == "AG" & allele2 == "AC" & allele3 == "TG",
        "heterozygous",
        ifelse(
          allele1 == "GG" & allele2 == "CC" & allele3 == "GG",
          "homozygous_minor",
          "mixed"
        )
      )
    )
  )
}

be_derive_apoe_genotype <- function(allele1, allele2) {
  allele1 <- be_genomics_string(allele1)
  allele2 <- be_genomics_string(allele2)

  ifelse(
    is.na(allele1) | is.na(allele2),
    NA_character_,
    ifelse(
      allele2 == "CC" & allele1 == "TT",
      "e1e1",
      ifelse(
        allele2 == "TC" & allele1 == "TT",
        "e1e2",
        ifelse(
          allele2 == "CC" & allele1 == "TC",
          "e1e4",
          ifelse(
            allele2 == "TT" & allele1 == "TT",
            "e2e2",
            ifelse(
              allele2 == "TT" & allele1 == "CT",
              "e2e3",
              ifelse(
                allele2 == "TC" & allele1 == "CT",
                "e2e4",
                ifelse(
                  allele2 == "TT" & allele1 == "CC",
                  "e3e3",
                  ifelse(
                    allele2 == "TC" & allele1 == "CC",
                    "e3e4",
                    ifelse(
                      allele2 == "CC" & allele1 == "CC",
                      "e4e4",
                      NA_character_
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
}

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
  genomics$aqp4_status <- ifelse(
    is.na(genomics$aqp4_genotype),
    NA_character_,
    ifelse(
      genomics$aqp4_genotype == "heterozygous",
      "carrier",
      "noncarrier"
    )
  )

  genomics$apoe_genotype <- be_derive_apoe_genotype(
    genomics$apoe_allele1 %||% NA,
    genomics$apoe_allele2 %||% NA
  )
  genomics$apoe_e4_status <- ifelse(
    is.na(genomics$apoe_genotype),
    NA_character_,
    ifelse(grepl("e4", genomics$apoe_genotype), "carrier", "noncarrier")
  )

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
