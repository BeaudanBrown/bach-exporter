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

be_derive_aqp4_status <- function(genotype) {
  ifelse(
    is.na(genotype),
    NA_character_,
    ifelse(genotype == "heterozygous", "carrier", "noncarrier")
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

be_derive_apoe_e4_status <- function(genotype) {
  ifelse(
    is.na(genotype),
    NA_character_,
    ifelse(grepl("e4", genotype), "carrier", "noncarrier")
  )
}
