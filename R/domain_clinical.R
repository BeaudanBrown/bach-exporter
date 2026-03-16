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
    bloods$bloods_cholratio <- suppressWarnings(
      as.numeric(bloods$bloods_chol) / as.numeric(bloods$bloods_chol_hdl)
    )
  }

  if (all(c("bloods_triglyc", "bloods_glucose_fasting") %in% names(bloods))) {
    trig_mgdl <- suppressWarnings(as.numeric(bloods$bloods_triglyc)) * 88.545
    glucose_mgdl <- suppressWarnings(as.numeric(
      bloods$bloods_glucose_fasting
    )) *
      18.0
    bloods$bloods_tygindex <- log((trig_mgdl * glucose_mgdl) / 2)
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

  pwv1 <- suppressWarnings(as.numeric(vitals$vitals_pwv_1 %||% NA))
  pwv2 <- suppressWarnings(as.numeric(vitals$vitals_pwv_2 %||% NA))
  pwv3 <- suppressWarnings(as.numeric(vitals$vitals_pwv_3 %||% NA))
  pwv_mean <- suppressWarnings(as.numeric(vitals$vitals_pwv_mean %||% NA))
  computed_mean <- ifelse(
    !is.na(pwv3),
    (pwv1 + pwv2 + pwv3) / 3,
    ifelse(
      !is.na(pwv2),
      (pwv1 + pwv2) / 2,
      pwv1
    )
  )
  vitals$vitals_pwv_mean <- ifelse(is.na(pwv_mean), computed_mean, pwv_mean)

  mean_sys <- suppressWarnings(as.numeric(vitals$vitals_lying_mean_sys %||% NA))
  mean_dia <- suppressWarnings(as.numeric(vitals$vitals_lying_mean_dia %||% NA))
  vitals$vitals_map <- mean_dia + ((1 / 3) * (mean_sys - mean_dia))
  vitals$vitals_pulsepressure <- mean_sys - mean_dia

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
