be_build_psqi_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      psqi_date = "psqi_date",
      psqi_total = "psqi_tot",
      psqi_q1_bedtime = "psqi_bed_tim",
      psqi_q2_fallasleep = "psqi_f_aslp_m",
      psqi_q3_gotup = "psqi_tim_wake",
      psqi_q4_totalhrsleep = "psqi_tot_slp_h",
      psqi_q5a_30m = "psqi_not30m",
      psqi_q5b_midnight = "psqi_midnight",
      psqi_q5c_bathroom = "psqi_bathroom",
      psqi_q5d_breathe = "psqi_breathe",
      psqi_q5e_cough = "psqi_cough",
      psqi_q5f_cold = "psqi_cold",
      psqi_q5g_hot = "psqi_hot",
      psqi_q5h_dreams = "psqi_dreams",
      psqi_q5i_pain = "psqi_pain",
      psqi_q5j_other = "psqi_oth",
      psqi_q5j_other_detail = "psqi_oth_sp",
      psqi_q6_sleepmed = "psqi_slp_med",
      psqi_q7_stayawake = "psqi_tro_awk",
      psqi_q8_enthusi = "psqi_enthusi",
      psqi_q9_quality = "psqi_slp_qual",
      psqi_comp1 = "psqi_c1",
      psqi_comp2 = "psqi_c2",
      psqi_comp2_sub = "psqi_c2_sub",
      psqi_comp3 = "psqi_c3",
      psqi_comp4 = "psqi_c4",
      psqi_comp4_sub = "psqi_c4_sub",
      psqi_comp5 = "psqi_c5",
      psqi_comp5_sub = "psqi_c5_sub",
      psqi_comp6 = "psqi_c6",
      psqi_comp7 = "psqi_c7"
    )
  )
}

be_build_ess_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      ess_date = "ess_date",
      ess_total = "ess_tot"
    )
  )
}

be_build_isi_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      isi_date = "isi_date",
      isi_cont_score = "isi_tot_co",
      isi_cat_score = "isi_tot_ca"
    )
  )
}

be_build_psg_screening_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      psg_collected = "pp_status_sleep",
      psg_ineligible_detail = "pp_status_sleep_in",
      psg_date = "pp_date_sleep",
      psg_acti_diff = "pp_time",
      psg_screen_1week_date = "scr_1w_date",
      psg_shiftwork = "scr_1w_shi_work",
      psg_osa_treat = "scr_1w_treat_ap"
    )
  )
}

be_build_psg_sleephealth_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      psg_sleephealth_date = "sleephealth_date",
      psg_sleephealth_site = "sleephealth_site_adm",
      psg_sleephealth_total = "sleephealth_ess_tot"
    )
  )
}

be_build_psg_morningquest_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      psg_morningquest_date = "ms_date",
      psg_morningquest_bed_time = "ms_bed_time",
      psg_morningquest_lights_out = "ms_lights_out",
      psg_morningquest_sleeponset = "ms_slp_time",
      psg_morningquest_sleepoffset = "ms_wake_time",
      psg_morningquest_lights_on = "ms_lights_on",
      psg_morningquest_duration_hr = "ms_slp_dur_hr",
      psg_morningquest_duration_minutes = "ms_slp_dur_min",
      psg_morningquest_compare_normal_dur = "ms_compare_slp_dur",
      psg_morningquest_sleep_depth = "ms_light_deep",
      psg_morningquest_sleep_length = "ms_short_long",
      psg_morningquest_sleep_restfulness = "ms_restless_restful",
      psg_morningquest_compare_normal_qual = "ms_compare_slp",
      psg_morningquest_difficulty_fall_asleep = "ms_diff_fall_aslp",
      psg_morningquest_minutes_fall_asleep = "ms_min_fall_aslp",
      psg_morningquest_compare_normal_fall_asleep = "ms_compare_fall_dur",
      psg_morningquest_alcohol = "ms_alc",
      psg_morningquest_alcohol_beer = "ms_alc_beer",
      psg_morningquest_alcohol_wine = "ms_alc_wine",
      psg_morningquest_alcohol_mixed = "ms_alc_mixed",
      psg_morningquest_caffeine = "ms_caffeine",
      psg_morningquest_caffiene_coffee = "ms_caff_coff",
      psg_morningquest_caffiene_tea = "ms_caff_tea",
      psg_morningquest_caffiene_soda = "ms_caff_soda",
      psg_morningquest_smoke = "ms_smk",
      psg_morningquest_smoke_freq = "ms_smk_freq",
      psg_morningquest_discomfort = "ms_discomfort",
      psg_morningquest_time = "ms_time_finish"
    )
  )
}

be_psg_medication_repeat_labels <- function() {
  "Sleep Medications In Last Two Weeks"
}

be_build_psg_sleepmed_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  if (!"redcap_repeat_instrument" %in% names(redcap_df)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  repeat_instrument <- trimws(as.character(redcap_df$redcap_repeat_instrument))
  medication_rows <- redcap_df[
    repeat_instrument %in% be_psg_medication_repeat_labels(),
    ,
    drop = FALSE
  ]
  if (!nrow(medication_rows)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  medication_rows$repeat_instance <- if (
    "redcap_repeat_instance" %in% names(medication_rows)
  ) {
    be_clean_repeat_instance(medication_rows$redcap_repeat_instance)
  } else {
    rep(NA_character_, nrow(medication_rows))
  }

  result <- data.frame(
    participant_id = medication_rows$participant_id,
    event_name = medication_rows$event_name,
    year = medication_rows$year,
    repeat_instance = medication_rows$repeat_instance,
    psg_medication_name = be_column_or_na(medication_rows, "m2w_med_name"),
    psg_medication_dose = be_column_or_na(
      medication_rows,
      "m2w_med_streng_pres"
    ),
    psg_medication_freq_presc = be_column_or_na(
      medication_rows,
      "m2w_med_dose_pres"
    ),
    psg_medication_dosenumber_presc = be_column_or_na(
      medication_rows,
      "m2w_med_freq_pres"
    ),
    psg_medication_freq_taken = be_column_or_na(
      medication_rows,
      "m2w_med_dose_taken"
    ),
    psg_medication_dosenumber_taken = be_column_or_na(
      medication_rows,
      "m2w_med_freq_taken"
    ),
    psg_medication_atc = be_column_or_na(medication_rows, "m2w_med_atc"),
    stringsAsFactors = FALSE
  )

  grouped <- split(
    result,
    interaction(
      result$participant_id,
      result$event_name,
      result$year,
      drop = TRUE
    )
  )

  wide_rows <- lapply(grouped, function(medication_rows) {
    key <- medication_rows[
      1,
      c("participant_id", "event_name", "year"),
      drop = FALSE
    ]
    row <- list(
      participant_id = key$participant_id[[1]],
      event_name = key$event_name[[1]],
      year = key$year[[1]]
    )

    instances <- suppressWarnings(as.integer(medication_rows$repeat_instance))
    fallback_instances <- seq_len(nrow(medication_rows))
    normalized_instances <- ifelse(
      is.na(instances),
      fallback_instances,
      instances
    )
    order_index <- order(normalized_instances)
    medication_rows <- medication_rows[order_index, , drop = FALSE]
    normalized_instances <- normalized_instances[order_index]

    value_columns <- setdiff(
      names(medication_rows),
      c("participant_id", "event_name", "year", "repeat_instance")
    )
    for (i in seq_len(nrow(medication_rows))) {
      suffix <- sprintf("med_psg_%02d", normalized_instances[[i]])
      for (column in value_columns) {
        row[[paste(column, suffix, sep = "_")]] <- medication_rows[[column]][[
          i
        ]]
      }
    }

    as.data.frame(row, stringsAsFactors = FALSE)
  })

  wide <- be_bind_rows_fill(wide_rows)
  wide <- be_drop_empty_columns(wide)
  unique(wide)
}

be_actigraphy_summary_field_map <- function() {
  c(
    acti_nightsrecorded = "acti_watch_num",
    acti_avg_bedtime = "acti_av_slp",
    acti_avg_onset = "acti_av_sot",
    acti_avg_onset_latency = "acti_av_aslp",
    acti_total_awakenings = "acti_av_awk",
    acti_total_WASO = "acti_av_awkd",
    acti_avg_offset = "acti_av_fin",
    acti_avg_timeoutbed = "acti_av_outb",
    acti_avg_TST = "acti_av_tot_slp",
    acti_avg_SE = "acti_av_slp_eff",
    acti_weekday_avg_bedtime = "acti_wd_slp",
    acti_weekday_avg_onset = "acti_wd_sot",
    acti_weekday_avg_onset_latency = "acti_wd_aslp",
    acti_weekday_total_no_awakenings = "acti_wd_awk",
    acti_weekday_total_WASO = "acti_wd_awkd",
    acti_weekday_avg_offset = "acti_wd_fin",
    acti_weekday_avg_timeoutbed = "acti_wd_outb",
    acti_weekday_avg_TST = "acti_wd_tot_slp",
    acti_weekday_avg_SE = "acti_wd_slp_eff",
    acti_weekend_avg_bedtime = "acti_we_slp",
    acti_weekend_avg_onset = "acti_we_sot",
    acti_weekend_avg_onset_latency = "acti_we_aslp",
    acti_weekend_total_no_awakenings = "acti_we_awk",
    acti_weekend_total_WASO = "acti_we_awkd",
    acti_weekend_avg_offset = "acti_we_fin",
    acti_weekend_avg_timeoutbed = "acti_we_outb",
    acti_weekend_avg_TST = "acti_we_tot_slp",
    acti_weekend_avg_SE = "acti_we_slp_eff"
  )
}

be_actigraphy_night_field_map <- function() {
  night_suffixes <- c(
    daytype = "type",
    bedtime = "slp",
    onset = "sot",
    onset_latency = "aslp",
    no_awakenings = "awk",
    WASO = "awkd",
    offset = "fin",
    timeoutbed = "outb",
    TST = "tot_slp",
    SE = "slp_eff"
  )

  field_map <- unlist(
    lapply(
      seq_len(14),
      function(index) {
        setNames(
          paste0("acti_", unname(night_suffixes), index),
          paste0("acti_night", index, "_", names(night_suffixes))
        )
      }
    ),
    use.names = TRUE
  )

  field_map
}

be_build_actigraphy_summary_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = be_actigraphy_summary_field_map()
  )
}

be_build_actigraphy_full_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      be_actigraphy_night_field_map(),
      be_actigraphy_summary_field_map()
    )
  )
}
