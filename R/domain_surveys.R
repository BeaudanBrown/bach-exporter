be_build_baseline_field_domain <- function(redcap_df, field_map, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)
  baseline_rows <- redcap_df[redcap_df$year == "baseline", , drop = FALSE]

  available_sources <- unname(field_map[field_map %in% names(baseline_rows)])
  if (!length(available_sources) || !nrow(baseline_rows)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  grouped_rows <- lapply(
    split(baseline_rows, baseline_rows$participant_id),
    function(df) {
      values <- lapply(
        available_sources,
        function(source_name) be_first_nonempty(df[[source_name]])
      )
      names(values) <- names(field_map)[field_map %in% names(df)]
      values$participant_id <- df$participant_id[[1]]
      values$event_name <- df$event_name[[1]]
      values$year <- df$year[[1]]
      as.data.frame(values, stringsAsFactors = FALSE)
    }
  )

  out <- do.call(rbind, grouped_rows)
  rownames(out) <- NULL
  out <- be_drop_empty_columns(out)
  unique(out)
}

be_build_demographics_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      demographics_date = "demographics_date",
      race = "race",
      race_other = "race_other",
      ethnicity = "ethnicity",
      lang_first_english = "english_first",
      lang_english_age = "english_first_n",
      lang_first_other = "first_language",
      employment_status = "employment",
      retire_age = "retire_age",
      occupation = "occupation",
      income_personal = "personal_income",
      income_household = "household_income",
      postcode_current = "current_postcode",
      postcode_longest = "postcode_longest",
      postcode_longest_time = "postcode_longest_length",
      living_arrange = "living_arrangements",
      living_arrange_other = "living_arrangements_other",
      living_household_n = "number_household",
      relationship_status = "relationship_status",
      childhood_ses = "ses_family",
      fathers_occupation_childhood = "father_occ",
      fathers_occupation_recent = "father_recent_occ"
    )
  )
}

be_build_cesd_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      cesd_date = "cesd_date",
      cesd_total = "cesd_total"
    )
  )
}

be_build_stai_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      stai_date = "stai_date",
      stai_total_state = "stai_y1_tot",
      stai_total_trait = "stai_y2_tot"
    )
  )
}

be_build_pss_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      pss_date = "pss_date",
      pss_total = "pss_total"
    )
  )
}

be_build_cdrisc_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      cdrisc_date = "cd_risc_date",
      cdrisc_total = "cd_risc_total"
    )
  )
}

be_build_ipaq_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      ipaq_date = "ipaq_date",
      ipaq_vigorous_met = "ipaq_vig_met",
      ipaq_moderate_met = "ipaq_mod_met",
      ipaq_walking_met = "ipaq_walk_met",
      ipaq_total_met = "ipaq_tot_pa",
      ipaq_category = "ipaq_category"
    )
  )
}

be_build_rhhi_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      rhhi_date = "rhhi_date",
      rhhi_total = "rhhi_total"
    )
  )
}

be_build_minddiet_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      minddiet_date = "mind_date",
      minddiet_total = "mind_total"
    )
  )
}

be_build_alcohol_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      alcoholq_date = "alcohol_date",
      alcoholq_12mo_freq = "alcohol1",
      alcoholq_lifetime_24hmax = "alcohol1a",
      alcoholq_12mo_daily = "alcohol2",
      alcoholq_12mo_binge_freq = "alcohol3"
    )
  )
}

be_build_cfi_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      cfi_date = "cfi_date",
      cfi_total = "cfi_total"
    )
  )
}

be_build_global_health_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      globhealth_date = "global_date",
      globhealth_physical = "global_tot_physical",
      globhealth_mental = "global_tot_mental",
      globhealth_index = "euro_qol"
    )
  )
}

be_build_ses_domain <- function(redcap_df, shared_root, years = NULL) {
  demographics <- be_build_demographics_domain(redcap_df, years = years)
  if (!nrow(demographics) || !"postcode_current" %in% names(demographics)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  ses_lookup <- be_read_side_data_csv(
    shared_root,
    "absdf.csv",
    col_classes = c(
      POA_CODE_2016 = "character",
      MB_CODE_2016 = "character"
    )
  )
  if (!"POA_CODE_2016" %in% names(ses_lookup)) {
    stop("SES side-data is missing POA_CODE_2016.", call. = FALSE)
  }

  demographics$postcode_current <- be_normalize_postcode(
    demographics$postcode_current
  )
  ses_lookup$POA_CODE_2016 <- be_normalize_postcode(ses_lookup$POA_CODE_2016)

  match_postcodes <- match(
    demographics$postcode_current,
    ses_lookup$POA_CODE_2016
  )
  demographics$ses_MB_CODE_2016 <- ses_lookup$MB_CODE_2016[match_postcodes]
  demographics$ses_decile_aus <- ses_lookup$decile_aus[match_postcodes]
  demographics$ses_percentile_aus <- ses_lookup$percentile_aus[match_postcodes]
  demographics$ses_decile_state <- ses_lookup$decile_state[match_postcodes]
  demographics$ses_percentile_state <- ses_lookup$percentile_state[
    match_postcodes
  ]

  out <- demographics[,
    c(
      "participant_id",
      "event_name",
      "year",
      "ses_MB_CODE_2016",
      "ses_decile_aus",
      "ses_percentile_aus",
      "ses_decile_state",
      "ses_percentile_state"
    ),
    drop = FALSE
  ]
  out <- be_drop_empty_columns(out)
  rownames(out) <- NULL
  out
}

be_build_aria_domain <- function(redcap_df, shared_root, years = NULL) {
  ses <- be_build_ses_domain(
    redcap_df,
    shared_root = shared_root,
    years = years
  )
  if (!nrow(ses) || !"ses_MB_CODE_2016" %in% names(ses)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  aria_lookup <- be_read_side_data_csv(
    shared_root,
    "RA_2016_AUST.csv",
    col_classes = c(MB_CODE_2016 = "character")
  )
  if (!"MB_CODE_2016" %in% names(aria_lookup)) {
    stop("ARIA side-data is missing MB_CODE_2016.", call. = FALSE)
  }

  ses$ses_MB_CODE_2016 <- be_normalize_postcode(ses$ses_MB_CODE_2016)
  aria_lookup$MB_CODE_2016 <- be_normalize_postcode(aria_lookup$MB_CODE_2016)
  match_mb <- match(ses$ses_MB_CODE_2016, aria_lookup$MB_CODE_2016)

  ra_name <- aria_lookup$RA_NAME_2016[match_mb]
  ses$RAname <- ra_name
  ses$RAstate <- aria_lookup$STATE_NAME_2016[match_mb]
  ses$RAcategory <- ifelse(
    ra_name == "Major Cities of Australia",
    "Urban",
    ifelse(
      ra_name %in%
        c(
          "Inner Regional Australia",
          "Outer Regional Australia",
          "Remote Australia",
          "Very Remote Australia"
        ),
      "Rural",
      NA_character_
    )
  )

  out <- ses[,
    c(
      "participant_id",
      "event_name",
      "year",
      "RAname",
      "RAstate",
      "RAcategory"
    ),
    drop = FALSE
  ]
  out <- be_drop_empty_columns(out)
  rownames(out) <- NULL
  out
}
