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
