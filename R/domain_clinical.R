be_build_event_field_domain <- function(redcap_df, field_map, years = NULL) {
  redcap_df <- be_redcap_domain_input(redcap_df, years)
  reduced_rows <- be_redcap_event_rows(redcap_df)
  if (is.null(reduced_rows)) {
    reduced_rows <- be_reduce_redcap_rows(redcap_df, be_event_key_columns())
  }

  available_sources <- unname(field_map[field_map %in% names(reduced_rows)])
  if (!length(available_sources) || !nrow(reduced_rows)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  destination_columns <- names(field_map)[field_map %in% names(reduced_rows)]
  out <- reduced_rows[,
    c(be_event_key_columns(), available_sources),
    drop = FALSE
  ]
  names(out) <- c(be_event_key_columns(), destination_columns)
  out <- be_drop_empty_columns(out)
  out <- unique(out)
  be_set_redcap_source_fields(
    out,
    stats::setNames(available_sources, destination_columns)
  )
}

be_build_bloods_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      bloods_success = "bloods_successful",
      bloods_date = "bloods_date",
      bloods_time = "bloods_time",
      bloods_drawnby = "bloods_who",
      bloods_drawnby_detail = "bloods_ra",
      bloods_notes = "bloods_notes",
      bloods_notes_detail = "bloods_notes_y",
      bloods_glucose_fasting = "bloods_glucose",
      bloods_chol = "bloods_chol",
      bloods_chol_hdl = "bloods_chol_hdl",
      bloods_chol_nonhdl = "bloods_non_hdl",
      bloods_chol_ldl = "bloods_ldl",
      bloods_triglyc = "bloods_trigly",
      bloods_hemoglob = "bloods_hb",
      bloods_wbc = "bloods_wbc",
      bloods_platelets = "bloods_platelets",
      bloods_hct = "bloods_hematocrit",
      bloods_mcv = "bloods_mcv",
      bloods_mch = "bloods_mch",
      bloods_mchc = "bloods_mchc",
      bloods_rbc = "bloods_rbc",
      bloods_rdw = "bloods_rdw",
      bloods_neutrophils = "bloods_neutrophils",
      bloods_lymphocytes = "bloods_lymphocytes",
      bloods_monocytes = "bloods_monocytes",
      bloods_eosinophils = "bloods_eosinophils",
      bloods_basophils = "bloods_basophils",
      bloods_inr = "bloods_inr",
      bloods_egfr = "bloods_egfr"
    )
  ) -> bloods

  if (!nrow(bloods)) {
    return(bloods)
  }

  if (all(c("bloods_chol", "bloods_chol_hdl") %in% names(bloods))) {
    bloods$bloods_cholratio <- be_compute_ratio(
      bloods$bloods_chol,
      bloods$bloods_chol_hdl
    )
  }

  if (all(c("bloods_triglyc", "bloods_glucose_fasting") %in% names(bloods))) {
    bloods$bloods_tygindex <- be_compute_tyg_index(
      bloods$bloods_triglyc,
      bloods$bloods_glucose_fasting
    )
  }

  bloods <- be_drop_empty_columns(bloods)
  rownames(bloods) <- NULL
  bloods
}

be_build_vitals_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      vitals_date = "vitals_date",
      vitals_time = "vitals_time",
      vitals_breakfast_before = "vitals_breakfast",
      vitals_breakfast_before_caffiene = "vitals_breakfast_caff",
      vitals_breakfast_before_food = "vitals_breakfast_f",
      vitals_breakfast_before_drink = "vitals_breakfast_d",
      height = "height",
      weight = "weight",
      bmi = "bmi",
      waist_circum = "waist_circ",
      vitals_lying_1_hr = "lying_hr1",
      vitals_lying_1_sys = "lying_systolic_bp1",
      vitals_lying_1_dia = "lying_diastolic_bp1",
      vitals_lying_2_hr = "lying_hr2",
      vitals_lying_2_sys = "lying_systolic_bp2",
      vitals_lying_2_dia = "lying_diastolic_bp2",
      vitals_lying_3_hr = "lying_hr3",
      vitals_lying_3_sys = "lying_systolic_bp3",
      vitals_lying_3_dia = "lying_diastolic_bp3",
      vitals_lying_mean_hr = "lying_hr_av",
      vitals_lying_mean_sys = "lying_systolic_bp_av",
      vitals_lying_mean_dia = "lying_diastolic_bp_av",
      vitals_stand_1min_hr = "standing_hr_1m",
      vitals_stand_1min_sys = "standing_systolic_bp_1m",
      vitals_stand_1min_dia = "standing_diastolic_bp_1m",
      vitals_stand_3min_hr = "standing_hr_3m",
      vitals_stand_3min_sys = "standing_systolic_bp_3m",
      vitals_stand_3min_dia = "standing_diastolic_bp_3m",
      vitals_pwv_1 = "pwv",
      vitals_pwv_2 = "pwv2",
      vitals_pwv_mean = "pwv_mean",
      vitals_pwv_3 = "pwv3",
      vitals_pwv_median = "pwv_median"
    )
  ) -> vitals

  if (!nrow(vitals)) {
    return(vitals)
  }

  vitals$vitals_pwv_mean <- be_compute_pwv_mean(
    vitals$vitals_pwv_1 %||% NA,
    vitals$vitals_pwv_2 %||% NA,
    vitals$vitals_pwv_3 %||% NA,
    vitals$vitals_pwv_mean %||% NA
  )

  vitals$vitals_map <- be_compute_mean_arterial_pressure(
    vitals$vitals_lying_mean_sys %||% NA,
    vitals$vitals_lying_mean_dia %||% NA
  )
  vitals$vitals_pulsepressure <- be_compute_pulse_pressure(
    vitals$vitals_lying_mean_sys %||% NA,
    vitals$vitals_lying_mean_dia %||% NA
  )

  vitals <- be_drop_empty_columns(vitals)
  rownames(vitals) <- NULL
  vitals
}

be_build_bp24h_domain <- function(redcap_df, years = NULL) {
  be_build_baseline_field_domain(
    redcap_df,
    years = years,
    field_map = c(
      BP24h_start = "twenty4bp_start_datetime",
      BP24h_end = "twenty4bp_end_datetime",
      BP24h_records = "twenty4bp_overall_count",
      BP24h_awake_sys_threshcount = "twenty4bp_awake_sys_ab_threshold",
      BP24h_awake_dia_threshcount = "twenty4bp_awake_dia_ab_threshold",
      BP24h_awake_sys_load = "twenty4bp_awake_sys_load",
      BP24h_awake_dia_load = "twenty4bp_awake_dia_load",
      BP24h_asleep_sys_threshcount = "twenty4bp_asleep_sys_ab_threshold",
      BP24h_asleep_dia_threshcount = "twenty4bp_asleep_dia_ab_threshold",
      BP24h_asleep_sys_load = "twenty4bp_asleep_sys_load",
      BP24h_asleep_dia_load = "twenty4bp_asleep_dia_load",
      BP24h_total_sys_load = "twenty4bp_total_sys_load",
      BP24h_total_dia_load = "twenty4bp_total_dia_load",
      BP24h_awake_sys_mean = "twenty4bp_awake_sys_mean",
      BP24h_awake_sys_max = "twenty4bp_awake_sys_max",
      BP24h_awake_sys_min = "twenty4bp_awake_sys_min",
      BP24h_awake_sys_sd = "twenty4bp_awake_sys_sd",
      BP24h_asleep_sys_mean = "twenty4bp_asleep_sys_mean",
      BP24h_asleep_sys_max = "twenty4bp_asleep_sys_max",
      BP24h_asleep_sys_min = "twenty4bp_asleep_sys_min",
      BP24h_asleep_sys_sd = "twenty4bp_asleep_sys_sd",
      BP24h_total_sys_mean = "twenty4bp_total_sys_mean",
      BP24h_total_sys_max = "twenty4bp_total_sys_max",
      BP24h_total_sys_min = "twenty4bp_total_sys_min",
      BP24h_total_sys_sd = "twenty4bp_total_sys_sd",
      BP24h_awake_dia_mean = "twenty4bp_awake_dia_mean",
      BP24h_awake_dia_max = "twenty4bp_awake_dia_max",
      BP24h_awake_dia_min = "twenty4bp_awake_dia_min",
      BP24h_awake_dia_sd = "twenty4bp_awake_dia_sd",
      BP24h_asleep_dia_mean = "twenty4bp_asleep_dia_mean",
      BP24h_asleep_dia_max = "twenty4bp_asleep_dia_max",
      BP24h_asleep_dia_min = "twenty4bp_asleep_dia_min",
      BP24h_asleep_dia_sd = "twenty4bp_asleep_dia_sd",
      BP24h_total_dia_mean = "twenty4bp_total_dia_mean",
      BP24h_total_dia_max = "twenty4bp_total_dia_max",
      BP24h_total_dia_min = "twenty4bp_total_dia_min",
      BP24h_total_dia_sd = "twenty4bp_total_dia_sd",
      BP24h_awake_hr_mean = "twenty4bp_awake_hr_mean",
      BP24h_awake_hr_max = "twenty4bp_awake_hr_max",
      BP24h_awake_hr_min = "twenty4bp_awake_hr_min",
      BP24h_awake_hr_sd = "twenty4bp_awake_hr_sd",
      BP24h_asleep_hr_mean = "twenty4bp_asleep_hr_mean",
      BP24h_asleep_hr_max = "twenty4bp_asleep_hr_max",
      BP24h_asleep_hr_min = "twenty4bp_asleep_hr_min",
      BP24h_asleep_hr_sd = "twenty4bp_asleep_hr_sd",
      BP24h_total_hr_mean = "twenty4bp_total_hr_mean",
      BP24h_total_hr_max = "twenty4bp_total_hr_max",
      BP24h_total_hr_min = "twenty4bp_total_hr_min",
      BP24h_total_hr_sd = "twenty4bp_total_hr_sd",
      BP24h_awake_map_mean = "twenty4bp_awake_map_mean",
      BP24h_awake_map_max = "twenty4bp_awake_map_max",
      BP24h_awake_map_min = "twenty4bp_awake_map_min",
      BP24h_awake_map_sd = "twenty4bp_awake_map_sd",
      BP24h_asleep_map_mean = "twenty4bp_asleep_map_mean",
      BP24h_asleep_map_max = "twenty4bp_asleep_map_max",
      BP24h_asleep_map_min = "twenty4bp_asleep_map_min",
      BP24h_asleep_map_sd = "twenty4bp_asleep_map_sd",
      BP24h_total_map_mean = "twenty4bp_total_map_mean",
      BP24h_total_map_max = "twenty4bp_total_map_max",
      BP24h_total_map_min = "twenty4bp_total_map_min",
      BP24h_total_map_sd = "twenty4bp_total_map_sd",
      BP24h_awake_pp_mean = "twenty4bp_awake_pulse_mean",
      BP24h_awake_pp_max = "twenty4bp_awake_pulse_max",
      BP24h_awake_pp_min = "twenty4bp_awake_pulse_min",
      BP24h_awake_pp_sd = "twenty4bp_awake_pulse_sd",
      BP24h_asleep_pp_mean = "twenty4bp_asleep_pulse_mean",
      BP24h_asleep_pp_max = "twenty4bp_asleep_pulse_max",
      BP24h_asleep_pp_min = "twenty4bp_asleep_pulse_min",
      BP24h_asleep_pp_sd = "twenty4bp_asleep_pulse_sd",
      BP24h_total_pp_mean = "twenty4bp_total_pulse_mean",
      BP24h_total_pp_max = "twenty4bp_total_pulse_max",
      BP24h_total_pp_min = "twenty4bp_total_pulse_min",
      BP24h_total_pp_sd = "twenty4bp_total_pulse_sd",
      BP24h_asleep_sys_dip_percent = "twenty4bp_sys_asleep_dip",
      BP24h_asleep_dia_dip_percent = "twenty4bp_dia_asleep_dip"
    )
  ) -> bp24h

  if (!nrow(bp24h)) {
    return(bp24h)
  }

  dip_percent <- suppressWarnings(as.numeric(
    bp24h$BP24h_asleep_sys_dip_percent %||% NA
  ))
  bp24h$BP24h_dipper <- ifelse(
    is.na(dip_percent),
    NA_character_,
    ifelse(dip_percent >= 10, "Yes", "No")
  )

  bp24h <- be_drop_empty_columns(bp24h)
  rownames(bp24h) <- NULL
  bp24h
}

be_build_medical_history_domain <- function(redcap_df, years = NULL) {
  baseline_map <- c(
    medhx_date = "medical_history_date",
    smoking_current = "smoked_recent",
    smoking_100cigs = "smoked_lifetime",
    smoking_totalyears = "smoked_years",
    smoking_avgpackperday = "smoked_number",
    smoking_agelastsmoke = "smoked_agequit",
    medhx_mi = "cvd_heartattack",
    medhx_mi_multi = "heartattack_more",
    medhx_mi_age = "heartattack_age",
    medhx_af = "cvd_atrialfibrillation",
    medhx_cardiacsurgery = "cvd_heartsurgury",
    medhx_bypass = "cvd_cardiacbypass",
    medhx_pace_defib = "cvd_pacemaker",
    medhx_chf = "cvd_congestiveheartfailure",
    medhx_angina = "cvd_angina",
    medhx_heartvalve = "cvd_heartvalve",
    medhx_pad = "cvd_periopheralarterial",
    medhx_other_heart = "cvd_other",
    medhx_other_heart_detail = "cvd_other_other",
    medhx_stroke = "cva_stroke",
    medhx_stroke1_age = "stroke_first_age",
    medhx_stroke1_type = "stroke_first_type",
    medhx_stroke1_cog = "stroke_first_cognition",
    medhx_stroke2 = "cva_stroke_second",
    medhx_stroke2_age = "stroke_second_age",
    medhx_stroke2_type = "stroke_second_type",
    medhx_stroke2_cog = "stroke_second_cognition",
    medhx_stroke3 = "cva_stroke_third",
    medhx_stroke3_age = "stroke_third_age",
    medhx_stroke3_type = "stroke_third_type",
    medhx_stroke3_cog = "stroke_third_cognition",
    medhx_seizure = "neuro_seizures",
    medhx_tbi = "neuro_tbi",
    medhx_tbi_age = "tbi_age_recent",
    medhx_tbi_consc = "tbi_lossconsc",
    medhx_tbi_consc_5min = "tbi_lossconsc_five",
    medhx_migraine = "migraines",
    medhx_other_neuro = "neuro_other",
    medhx_other_neuro_detail = "neuro_other_y",
    medhx_diabetes = "medical_diabetes",
    medhx_diabetes_type = "diabetes_type",
    medhx_diabetes_age = "diabetes_age",
    medhx_htn = "medical_hypertension",
    medhx_htn_age = "hypertension_age",
    medhx_hyperchol = "medical_hypercholesterolemia",
    medhx_hyperchol_age = "hypercholesterolemia_age",
    medhx_b12 = "medical_btwelve",
    medhx_thyroid = "medical_thyroid",
    medhx_arthritis = "medical_arthritis",
    medhx_arthritis_rheu = "arthritis_type___1",
    medhx_arthritis_osteo = "arthritis_type___2",
    medhx_arthritis_unknowntype = "arthritis_type___3",
    medhx_arthritis_othertype = "arthritis_type___4",
    medhx_arthritis_upper = "arthritis_regions___1",
    medhx_arthritis_lower = "arthritis_regions___2",
    medhx_arthritis_spine = "arthritis_regions___3",
    medhx_arthritis_unknownarea = "arthritis_regions___4",
    medhx_arthritis_otherarea = "arthritis_regions___5",
    medhx_arthritis_otherarea_detail = "arthritis_regions_other",
    medhx_urinaryincont = "medical_urinary_incont",
    medhx_bowelincont = "medical_bowel_incont",
    medhx_osa = "medical_apnoea",
    medhx_osa_age = "apnoea_age",
    medhx_rem_disorder = "medical_remsleepdisorder",
    medhx_rem_disorder_actdreams = "medical_dreams",
    medhx_insom_hyposom = "medical_insomnia",
    medhx_sleepother = "medical_sleep_other",
    medhx_sleepother_detail = "medical_sleep_other_y",
    medhx_cancer = "medical_cancer",
    medhx_cancer_detail = "medical_cancer_y",
    medhx_ptsd = "psych_ptsd",
    medhx_dep = "psych_depression",
    medhx_anx = "psych_anxiety",
    medhx_ocd = "psych_ocd",
    medhx_dev_disorder = "psych_develop",
    medhx_dev_disorder_detail = "psych_develop_disorders",
    medhx_otherpsych = "psych_other",
    medhx_otherpsych_detail = "psych_other_disorders",
    medhx_covid = "covid_infected",
    medhx_covid_labtest = "covid_swabtest",
    medhx_covid_hosp = "covid_hospitalised",
    medhx_covid_anosmia = "covid_neurological___1",
    medhx_covid_headache = "covid_neurological___2",
    medhx_covid_delirium = "covid_neurological___3",
    medhx_covid_intubation = "covid_treatment___1",
    medhx_covid_oxygen = "covid_treatment___2",
    medhx_covid_sedation = "covid_treatment___3",
    medhx_covid_othertx = "covid_treatment___4",
    medhx_covid_othertx_detail = "covid_treatment_other",
    medhx_covid_recovered = "covid_recovered",
    medhx_covid_fatigue = "covid_fatigue",
    famhx_stroke = "family_tia",
    famhx_stroke_age55 = "family_tia_agefiftyfive",
    famhx_stroke_genetic = "family_tia_geneticdom",
    famhx_cogimpair = "family_cogimpairment",
    famhx_dementia = "family_dementia",
    famhx_dementia_mother = "family_dementia_who___1",
    famhx_dementia_father = "family_dementia_who___2",
    famhx_dementia_sibling = "family_dementia_who___3",
    famhx_dementia_maternal = "family_dementia_who___4",
    famhx_dementia_paternal = "family_dementia_who___5",
    famhx_cvd = "family_cvd",
    green_menopause = "menopause_period_stop",
    green_psych = "greeneclim_psych",
    green_somatic = "greeneclim_somatic",
    green_vasomotor = "greeneclim_vaso",
    green_total = "greeneclim_total",
    medhx_notes = "mh_notes",
    medhx_notes_detail = "mh_notes_y"
  )
  followup_map <- c(
    medhx_cogimpair = "mh_follow_cogimpair_v2",
    medhx_cogimpair_detail = "mh_follow_cogimpair_y_v2",
    medhx_cvd = "mh_follow_cd_v2",
    medhx_mi = "mh_follow_mycardial_v2",
    medhx_stroke = "mh_follow_stroke_v2",
    medhx_stroke_type = "mh_follow_stroke_t_v2",
    medhx_tia = "mh_follow_tia_v2",
    medhx_chf = "mh_follow_hf_v2",
    medhx_af = "mh_follow_af_v2",
    medhx_cvd_other = "mh_follow_cvd_other_v2",
    medhx_cancer = "mh_follow_cancer_v2",
    medhx_cancer_detail = "mh_follow_cancer_y_v2",
    medhx_sleep_follow = "mh_follow_sleep_v2",
    medhx_sleep_follow_detail = "mh_follow_sleep_y_v2",
    medhx_psych_follow = "mh_follow_psych_v2",
    medhx_psych_follow_detail = "mh_follow_psych_y_v2",
    medhx_hosp = "mh_follow_hosp_v2",
    medhx_hosp_detail = "mh_follow_hosp_y_v2",
    medhx_notes = "mh_follow_notes"
  )

  baseline <- be_build_event_field_domain(
    redcap_df = redcap_df,
    field_map = baseline_map,
    years = intersect(years %||% c("baseline"), "baseline")
  )
  followup <- be_build_event_field_domain(
    redcap_df = redcap_df,
    field_map = followup_map,
    years = intersect(years %||% c("year2", "year3"), c("year2", "year3"))
  )

  pieces <- Filter(
    Negate(is.null),
    list(
      if (nrow(baseline)) baseline else NULL,
      if (nrow(followup)) followup else NULL
    )
  )

  if (!length(pieces)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  source_fields <- unlist(
    lapply(pieces, be_redcap_source_fields),
    recursive = FALSE,
    use.names = TRUE
  )
  source_fields <- source_fields[!duplicated(names(source_fields))]
  all_columns <- unique(unlist(lapply(pieces, names), use.names = FALSE))
  pieces <- lapply(
    pieces,
    function(df) {
      missing_columns <- setdiff(all_columns, names(df))
      for (column in missing_columns) {
        df[[column]] <- NA
      }
      df[, all_columns, drop = FALSE]
    }
  )
  out <- do.call(rbind, pieces)

  rownames(out) <- NULL
  out <- be_drop_empty_columns(out)
  out <- unique(out)
  be_set_redcap_source_fields(out, source_fields)
}
