source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "release_runtime.R"))
source(file.path("..", "..", "R", "config.R"))
source(file.path("..", "..", "R", "source_snapshots.R"))
source(file.path("..", "..", "R", "source_side_data.R"))
source(file.path("..", "..", "R", "normalize_redcap.R"))
source(file.path("..", "..", "R", "cohort_filters.R"))
source(file.path("..", "..", "R", "split_events.R"))
source(file.path("..", "..", "R", "domain_participants.R"))
source(file.path("..", "..", "R", "domain_annual_phone_aux.R"))
source(file.path("..", "..", "R", "domain_screening_aux.R"))
source(file.path("..", "..", "R", "domain_imaging.R"))
source(file.path("..", "..", "R", "domain_surveys.R"))
source(file.path("..", "..", "R", "domain_clinical.R"))
source(file.path("..", "..", "R", "domain_neuropsych.R"))
source(file.path("..", "..", "R", "domain_sleep.R"))
source(file.path("..", "..", "R", "domain_similarities.R"))
source(file.path("..", "..", "R", "domain_prose_passages.R"))
source(file.path("..", "..", "R", "domain_cognitive_screening.R"))
source(file.path("..", "..", "R", "domain_medications.R"))
source(file.path("..", "..", "R", "assemble_export.R"))
source(file.path("..", "..", "R", "export_spec.R"))
source(file.path("..", "..", "R", "export_validate.R"))
source(file.path("..", "..", "R", "targets_graph.R"))
source(file.path("..", "..", "R", "export_pipeline.R"))
source(file.path("..", "..", "R", "export_run.R"))

populate_test_shared_app <- function(shared_root, build_id = "dev") {
  app_root <- file.path(shared_root, "app")
  dir.create(file.path(app_root, "R"), recursive = TRUE, showWarnings = FALSE)
  dir.create(
    file.path(app_root, "scripts"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(
    file.path(shared_root, "side-data"),
    recursive = TRUE,
    showWarnings = FALSE
  )

  writeLines(
    c("Package: bachExporter", "Version: 0.0.1"),
    file.path(app_root, "DESCRIPTION")
  )
  writeLines("{}", file.path(app_root, "renv.lock"))
  jsonlite::write_json(
    list(
      build_id = build_id,
      package = list(name = "bachExporter", version = "0.0.1")
    ),
    file.path(app_root, "manifest.json"),
    auto_unbox = TRUE
  )
  file.copy(
    file.path("..", "..", "NAMESPACE"),
    file.path(app_root, "NAMESPACE")
  )
  file.copy(
    file.path("..", "..", "R", "paths.R"),
    file.path(app_root, "R", "paths.R")
  )
  file.copy(
    file.path("..", "..", "R", "release_runtime.R"),
    file.path(app_root, "R", "release_runtime.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "launch_from_share.R"),
    file.path(app_root, "scripts", "launch_from_share.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "validate_release.R"),
    file.path(app_root, "scripts", "validate_release.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "refresh_snapshots.R"),
    file.path(app_root, "scripts", "refresh_snapshots.R")
  )

  invisible(app_root)
}

make_export_shared_root <- function() {
  shared_root <- tempfile("shared-root-")
  dir.create(file.path(shared_root, "snapshots", "redcap"), recursive = TRUE)
  dir.create(file.path(shared_root, "snapshots", "sidecars"), recursive = TRUE)
  populate_test_shared_app(shared_root)
  utils::write.csv(
    data.frame(
      POA_CODE_2016 = c("3000", "3001"),
      MB_CODE_2016 = c("MB1", "MB2"),
      decile_aus = c(9, 4),
      percentile_aus = c(90, 40),
      decile_state = c(8, 5),
      percentile_state = c(80, 50),
      stringsAsFactors = FALSE
    ),
    file.path(shared_root, "side-data", "absdf.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      MB_CODE_2016 = c("MB1", "MB2"),
      RA_NAME_2016 = c("Major Cities of Australia", "Inner Regional Australia"),
      STATE_NAME_2016 = c("Victoria", "Victoria"),
      stringsAsFactors = FALSE
    ),
    file.path(shared_root, "side-data", "RA_2016_AUST.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      subject_id = c("sub-BACH001", "sub-BACH002"),
      brainvol_novent = c(1100.5, 1048.2),
      hippo_left = c(3.2, 2.9),
      hippo_right = c(3.4, 3.0),
      wm_hypoint = c(12.1, 18.4),
      stringsAsFactors = FALSE
    ),
    file.path(shared_root, "side-data", "global_n241.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      idno = c("BACH001", "BACH002", "10000"),
      psg_locationsetup = c("Lab", "Home", "Test"),
      psg_ess = c(6, 12, 99),
      psg_height = c(170, 160, 150),
      psg_weight = c(70, 80, 50),
      psg_bmi = c(24.2, 31.2, 22.2),
      psg_lights_out = c("22:30", "23:00", "00:00"),
      psg_lights_on = c("06:30", "07:00", "08:00"),
      psg_tot_sleep_time = c(390, 360, 100),
      psg_sleep_effic = c(88, 76, 10),
      psg_overall_ahi_all = c(8.1, 26.4, 99),
      psg_nrem_ahi_all = c(7.8, 24.1, 99),
      psg_rem_ahi_all = c(10.2, 31.0, 99),
      psg_odi4_per = c(5.3, 18.6, 99),
      psg_total_plmi = c(3.5, 12.2, 99),
      psg_av_slp_hr = c(58, 64, 99),
      psg_highest_sleep_hr = c(77, 89, 99),
      psg_rswa = c("yes", "no", "yes"),
      stringsAsFactors = FALSE
    ),
    file.path(shared_root, "side-data", "psg_data.csv"),
    row.names = FALSE
  )

  export_snapshot <- data.frame(
    idno = c("BACH001", "BACH002", "BACH002"),
    redcap_event_name = c("Baseline", "Baseline", "Year 2"),
    redcap_repeat_instrument = c(NA, NA, NA),
    redcap_repeat_instance = c(NA, NA, NA),
    age = c(70, 71, NA),
    sex = c("F", "M", NA),
    highest_education = c("College", "TAFE", NA),
    education = c(NA, NA, NA),
    pp_date = c("2026-01-01", "2026-01-02", "2027-01-02"),
    similarities1 = c(1, 1, 1),
    similarities2 = c(1, 1, 1),
    similarities3 = c(1, 1, 1),
    similarities4 = c(0, 0, 0),
    similarities5 = c(0, 0, 0),
    similarities6 = c(0, 0, 0),
    tele_total = c(28, 27, 26),
    mri_date = c("2026-01-06", "2026-01-07", NA),
    mri_time = c("10:00", "10:30", NA),
    lp_successful = c("Yes", "No", "Yes"),
    lp_date = c("2026-01-08", "2026-01-09", "2027-01-09"),
    lp_time = c("11:00", "11:30", "11:15"),
    lp_successful_n = c(NA, "Participant declined", NA),
    lp_successful_n_other = c(NA, "Too anxious", NA),
    lp_notes = c("Clear CSF", "", "Repeat procedure"),
    lp_notes_y = c("", "No sample collected", "Tolerated well"),
    moca_total = c(25, 24, 23),
    ad8_who = c("Self", "Spouse", "Child"),
    ad8_date = c("2026-01-01", "2026-01-02", "2027-01-02"),
    ad8_total = c(1, 2, 3),
    ucla1_v2 = c(NA, 1, 2),
    ucla2_v2 = c(NA, 2, 3),
    ucla3_v2 = c(NA, 3, 4),
    ucla_total_v2 = c(NA, 6, 9),
    demographics_date = c("2026-01-01", "2026-01-02", NA),
    race = c("White", "Asian", NA),
    race_other = c("", "", NA),
    ethnicity = c("No", "Yes", NA),
    english_first = c("Yes", "No", NA),
    english_first_n = c(0, 10, NA),
    first_language = c("English", "Mandarin", NA),
    employment = c("Retired", "Part-time", NA),
    retire_age = c(65, NA, NA),
    occupation = c("Teacher", "Accountant", NA),
    personal_income = c("50-60k", "40-50k", NA),
    household_income = c("80-100k", "60-80k", NA),
    current_postcode = c("3000", "3001", NA),
    postcode_longest = c("3000", "3001", NA),
    postcode_longest_length = c(20, 15, NA),
    living_arrangements = c("Partner", "Family", NA),
    living_arrangements_other = c("", "", NA),
    number_household = c(2, 4, NA),
    relationship_status = c("Married", "Single", NA),
    ses_family = c("Average", "Low", NA),
    father_occ = c("Trades", "Farmer", NA),
    father_recent_occ = c("Manager", "Retired", NA),
    cesd_date = c("2026-01-03", "2026-01-04", NA),
    cesd_total = c(5, 7, NA),
    stai_date = c("2026-01-03", "2026-01-04", NA),
    stai_y1_tot = c(20, 25, NA),
    stai_y2_tot = c(30, 35, NA),
    pss_date = c("2026-01-03", "2026-01-04", NA),
    pss_total = c(10, 12, NA),
    cd_risc_date = c("2026-01-03", "2026-01-04", NA),
    cd_risc_total = c(28, 26, NA),
    ipaq_date = c("2026-01-03", "2026-01-04", NA),
    ipaq_vig_met = c(100, 200, NA),
    ipaq_mod_met = c(50, 80, NA),
    ipaq_walk_met = c(30, 40, NA),
    ipaq_tot_pa = c(180, 320, NA),
    ipaq_category = c("Moderate", "High", NA),
    rhhi_date = c("2026-01-03", "2026-01-04", NA),
    rhhi_total = c(2, 5, NA),
    mind_date = c("2026-01-03", "2026-01-04", NA),
    mind_total = c(8, 9, NA),
    alcohol_date = c("2026-01-03", "2026-01-04", NA),
    alcohol1 = c("Weekly", "Monthly", NA),
    alcohol1a = c(6, 4, NA),
    alcohol2 = c(1, 0, NA),
    alcohol3 = c("Rarely", "Never", NA),
    cfi_date = c("2026-01-03", "2026-01-04", NA),
    cfi_total = c(1, 3, NA),
    global_date = c("2026-01-03", "2026-01-04", NA),
    global_tot_physical = c(45, 40, NA),
    global_tot_mental = c(50, 42, NA),
    euro_qol = c(0.92, 0.81, NA),
    bloods_successful = c("Yes", "No", NA),
    bloods_date = c("2026-01-05", "2026-01-06", NA),
    bloods_time = c("08:00", "08:30", NA),
    bloods_who = c("Nurse", "Phleb", NA),
    bloods_ra = c("", "RA1", NA),
    bloods_notes = c("Fasted", "", NA),
    bloods_notes_y = c("", "", NA),
    bloods_glucose = c(5.1, 6.0, NA),
    bloods_chol = c(5.5, 4.8, NA),
    bloods_chol_hdl = c(1.5, 1.2, NA),
    bloods_non_hdl = c(4.0, 3.6, NA),
    bloods_ldl = c(3.1, 2.8, NA),
    bloods_trigly = c(1.3, 1.8, NA),
    bloods_hb = c(140, 135, NA),
    bloods_wbc = c(5.0, 6.0, NA),
    bloods_platelets = c(250, 275, NA),
    bloods_hematocrit = c(0.42, 0.41, NA),
    bloods_mcv = c(90, 88, NA),
    bloods_mch = c(30, 29, NA),
    bloods_mchc = c(333, 330, NA),
    bloods_rbc = c(4.7, 4.6, NA),
    bloods_rdw = c(12.5, 13.1, NA),
    bloods_neutrophils = c(2.5, 3.2, NA),
    bloods_lymphocytes = c(1.8, 2.0, NA),
    bloods_monocytes = c(0.4, 0.5, NA),
    bloods_eosinophils = c(0.1, 0.2, NA),
    bloods_basophils = c(0.0, 0.1, NA),
    bloods_inr = c(1.0, 1.1, NA),
    bloods_egfr = c(88, 79, NA),
    vitals_date = c("2026-01-05", "2026-01-06", NA),
    vitals_time = c("09:00", "09:15", NA),
    vitals_breakfast = c("Yes", "No", NA),
    vitals_breakfast_caff = c("No", "Yes", NA),
    vitals_breakfast_f = c("Toast", "", NA),
    vitals_breakfast_d = c("Tea", "Coffee", NA),
    height = c(170, 160, NA),
    weight = c(70, 80, NA),
    bmi = c(24.2, 31.2, NA),
    waist_circ = c(90, 100, NA),
    lying_hr1 = c(60, 70, NA),
    lying_systolic_bp1 = c(130, 145, NA),
    lying_diastolic_bp1 = c(80, 90, NA),
    lying_hr2 = c(62, 72, NA),
    lying_systolic_bp2 = c(128, 142, NA),
    lying_diastolic_bp2 = c(78, 88, NA),
    lying_hr3 = c(61, 71, NA),
    lying_systolic_bp3 = c(129, 141, NA),
    lying_diastolic_bp3 = c(79, 87, NA),
    lying_hr_av = c(61, 71, NA),
    lying_systolic_bp_av = c(129, 143, NA),
    lying_diastolic_bp_av = c(79, 88, NA),
    standing_hr_1m = c(68, 78, NA),
    standing_systolic_bp_1m = c(126, 138, NA),
    standing_diastolic_bp_1m = c(77, 86, NA),
    standing_hr_3m = c(66, 76, NA),
    standing_systolic_bp_3m = c(124, 136, NA),
    standing_diastolic_bp_3m = c(76, 85, NA),
    pwv = c(8.0, 9.0, NA),
    pwv2 = c(8.2, 9.3, NA),
    pwv_mean = c(NA, 9.1, NA),
    pwv3 = c(8.4, NA, NA),
    pwv_median = c(8.2, 9.0, NA),
    twenty4bp_start_datetime = c("2026-01-05 08:00", "2026-01-06 08:00", NA),
    twenty4bp_end_datetime = c("2026-01-06 08:00", "2026-01-07 08:00", NA),
    twenty4bp_overall_count = c(50, 48, NA),
    twenty4bp_awake_sys_ab_threshold = c(5, 6, NA),
    twenty4bp_awake_dia_ab_threshold = c(4, 5, NA),
    twenty4bp_awake_sys_load = c(10, 12, NA),
    twenty4bp_awake_dia_load = c(8, 9, NA),
    twenty4bp_asleep_sys_ab_threshold = c(3, 4, NA),
    twenty4bp_asleep_dia_ab_threshold = c(2, 3, NA),
    twenty4bp_asleep_sys_load = c(6, 7, NA),
    twenty4bp_asleep_dia_load = c(5, 6, NA),
    twenty4bp_total_sys_load = c(9, 10, NA),
    twenty4bp_total_dia_load = c(7, 8, NA),
    twenty4bp_awake_sys_mean = c(130, 142, NA),
    twenty4bp_awake_sys_max = c(150, 160, NA),
    twenty4bp_awake_sys_min = c(110, 120, NA),
    twenty4bp_awake_sys_sd = c(10, 11, NA),
    twenty4bp_asleep_sys_mean = c(115, 132, NA),
    twenty4bp_asleep_sys_max = c(130, 145, NA),
    twenty4bp_asleep_sys_min = c(100, 118, NA),
    twenty4bp_asleep_sys_sd = c(8, 9, NA),
    twenty4bp_total_sys_mean = c(123, 138, NA),
    twenty4bp_total_sys_max = c(150, 160, NA),
    twenty4bp_total_sys_min = c(100, 118, NA),
    twenty4bp_total_sys_sd = c(9, 10, NA),
    twenty4bp_awake_dia_mean = c(80, 88, NA),
    twenty4bp_awake_dia_max = c(95, 100, NA),
    twenty4bp_awake_dia_min = c(65, 70, NA),
    twenty4bp_awake_dia_sd = c(7, 8, NA),
    twenty4bp_asleep_dia_mean = c(70, 78, NA),
    twenty4bp_asleep_dia_max = c(82, 88, NA),
    twenty4bp_asleep_dia_min = c(60, 66, NA),
    twenty4bp_asleep_dia_sd = c(6, 7, NA),
    twenty4bp_total_dia_mean = c(76, 83, NA),
    twenty4bp_total_dia_max = c(95, 100, NA),
    twenty4bp_total_dia_min = c(60, 66, NA),
    twenty4bp_total_dia_sd = c(7, 8, NA),
    twenty4bp_awake_hr_mean = c(68, 74, NA),
    twenty4bp_awake_hr_max = c(90, 96, NA),
    twenty4bp_awake_hr_min = c(55, 60, NA),
    twenty4bp_awake_hr_sd = c(6, 7, NA),
    twenty4bp_asleep_hr_mean = c(58, 64, NA),
    twenty4bp_asleep_hr_max = c(72, 78, NA),
    twenty4bp_asleep_hr_min = c(48, 52, NA),
    twenty4bp_asleep_hr_sd = c(5, 6, NA),
    twenty4bp_total_hr_mean = c(64, 70, NA),
    twenty4bp_total_hr_max = c(90, 96, NA),
    twenty4bp_total_hr_min = c(48, 52, NA),
    twenty4bp_total_hr_sd = c(6, 7, NA),
    twenty4bp_awake_map_mean = c(97, 106, NA),
    twenty4bp_awake_map_max = c(112, 118, NA),
    twenty4bp_awake_map_min = c(82, 88, NA),
    twenty4bp_awake_map_sd = c(7, 8, NA),
    twenty4bp_asleep_map_mean = c(85, 96, NA),
    twenty4bp_asleep_map_max = c(95, 105, NA),
    twenty4bp_asleep_map_min = c(74, 84, NA),
    twenty4bp_asleep_map_sd = c(6, 7, NA),
    twenty4bp_total_map_mean = c(92, 101, NA),
    twenty4bp_total_map_max = c(112, 118, NA),
    twenty4bp_total_map_min = c(74, 84, NA),
    twenty4bp_total_map_sd = c(7, 8, NA),
    twenty4bp_awake_pulse_mean = c(50, 54, NA),
    twenty4bp_awake_pulse_max = c(65, 70, NA),
    twenty4bp_awake_pulse_min = c(40, 44, NA),
    twenty4bp_awake_pulse_sd = c(5, 5, NA),
    twenty4bp_asleep_pulse_mean = c(45, 48, NA),
    twenty4bp_asleep_pulse_max = c(55, 58, NA),
    twenty4bp_asleep_pulse_min = c(35, 38, NA),
    twenty4bp_asleep_pulse_sd = c(4, 4, NA),
    twenty4bp_total_pulse_mean = c(48, 51, NA),
    twenty4bp_total_pulse_max = c(65, 70, NA),
    twenty4bp_total_pulse_min = c(35, 38, NA),
    twenty4bp_total_pulse_sd = c(5, 5, NA),
    twenty4bp_sys_asleep_dip = c(11, 8, NA),
    twenty4bp_dia_asleep_dip = c(12, 7, NA),
    neuropsych_date = c("2026-01-07", "2026-01-08", "2027-01-08"),
    cdr_memory = c(0, 0.5, 1),
    cdr_orient = c(0, 0, 0.5),
    cdr_judgment = c(0, 0.5, 0.5),
    cdr_community = c(0, 0, 1),
    cdr_hobbies = c(0, 0.5, 1),
    cdr_personal = c(0, 0, 0),
    cdr_sob = c(0, 1.5, 4),
    cdr_global = c(0, 0.5, 1),
    mmse_tot = c(29, 27, 24),
    mmse_comment = c("", "Needed prompting", "Fatigued"),
    mmse_comment_y = c("", "Serial sevens slow", "Attention drift"),
    sydbat_date = c("2026-01-07", "2026-01-08", "2027-01-08"),
    sydbat_naming_total = c(27, 24, 21),
    sydbat_repetition_total = c(28, 25, 22),
    sydbat_comprehension_total = c(29, 26, 23),
    sydbat_semantic_total = c(30, 27, 24),
    lmi_time = c("09:00", "09:10", "09:20"),
    lmi_b_total = c(12, 11, 10),
    lmi_c_total = c(13, 12, 11),
    lmi_total_raw = c(25, 23, 21),
    lmii_time = c("09:30", "09:40", "09:50"),
    lmii_timediff = c(30, 30, 30),
    lmii_bcue = c(1, 0, 1),
    lmii_b_total = c(10, 9, 8),
    lmii_ccue = c(1, 1, 0),
    lmii_c_total = c(11, 10, 9),
    lmii_total_raw = c(21, 19, 17),
    vri_time = c("09:05", "09:15", "09:25"),
    vri_total_raw = c(35, 30, 28),
    vrii_time = c("09:35", "09:45", "09:55"),
    vrii_timediff = c(30, 30, 30),
    vrii_total_raw = c(18, 16, 14),
    tmt_date = c("2026-01-07", "2026-01-08", "2027-01-08"),
    tmt_a_total_sec = c(35, 42, 55),
    tmt_a_err = c(0, 1, 1),
    tmt_b_total_sec = c(80, 95, 120),
    tmt_b_err = c(1, 2, 3),
    fab_date = c("2026-01-07", "2026-01-08", "2027-01-08"),
    fab_similarities = c(3, 2, 2),
    fab_lexical_fluency = c(3, 2, 1),
    fab_motor = c(3, 3, 2),
    fab_conflicting_instrx = c(3, 2, 2),
    fab_go_nogo = c(3, 2, 1),
    fab_prehension = c(3, 3, 2),
    fab_total = c(18, 14, 10),
    cowat_date = c("2026-01-07", "2026-01-08", "2027-01-08"),
    cowat_f_total = c(14, 12, 10),
    cowat_a_total = c(13, 11, 9),
    cowat_s_total = c(15, 10, 8),
    cowat_fas_total = c(42, 33, 27),
    cowat_animals_total = c(20, 18, 14),
    hvot_date = c("2026-01-07", "2026-01-08", "2027-01-08"),
    hvot_total = c(25, 22, 18),
    tasit_date = c("2026-01-07", "2026-01-08", "2027-01-08"),
    tasit_p2_sin = c(8, 7, 6),
    tasit_p2_sar = c(7, 6, 5),
    tasit_p2_total = c(15, 13, 11),
    topf_date = c("2026-01-07", "2026-01-08", "2027-01-08"),
    topf1 = c(1, 1, 1),
    topf2 = c(1, 1, 1),
    topf3 = c(1, 0, 1),
    topf4 = c(0, 0, 1),
    topf5 = c(0, 0, 0),
    topf6 = c(0, 0, 0),
    ds_adju_date = c("2026-01-09", "2026-01-10", "2027-01-10"),
    ds_status = c("No dementia", "MCI", "Dementia"),
    ds_onset_date = c("", "2025-06-01", "2026-06-01"),
    ds_cog_int_date = c("2026-01-09", "2025-05-01", "2026-05-01"),
    ds_notes = c("", "Monitor progression", "Consensus adjudication"),
    psqi_date = c("2026-01-11", "2026-01-12", "2027-01-12"),
    psqi_tot = c(4, 8, 11),
    psqi_bed_tim = c("22:00", "23:00", "23:30"),
    psqi_f_aslp_m = c(15, 35, 50),
    psqi_tim_wake = c("06:30", "07:00", "08:00"),
    psqi_tot_slp_h = c(7.5, 6.0, 5.0),
    psqi_not30m = c(0, 2, 3),
    psqi_midnight = c(0, 1, 2),
    psqi_bathroom = c(1, 2, 2),
    psqi_breathe = c(0, 1, 2),
    psqi_cough = c(0, 0, 1),
    psqi_cold = c(0, 1, 1),
    psqi_hot = c(0, 0, 1),
    psqi_dreams = c(1, 2, 2),
    psqi_pain = c(0, 1, 2),
    psqi_oth = c(0, 1, 2),
    psqi_oth_sp = c("", "Noise", "Leg cramps"),
    psqi_slp_med = c(0, 1, 2),
    psqi_tro_awk = c(0, 1, 2),
    psqi_enthusi = c(0, 1, 2),
    psqi_slp_qual = c(0, 1, 2),
    psqi_c1 = c(0, 1, 2),
    psqi_c2 = c(1, 2, 3),
    psqi_c2_sub = c(0, 1, 2),
    psqi_c3 = c(0, 1, 2),
    psqi_c4 = c(0, 1, 2),
    psqi_c4_sub = c(0, 1, 2),
    psqi_c5 = c(1, 2, 3),
    psqi_c5_sub = c(2, 4, 6),
    psqi_c6 = c(0, 1, 2),
    psqi_c7 = c(0, 1, 2),
    ess_date = c("2026-01-11", "2026-01-12", "2027-01-12"),
    ess_tot = c(4, 9, 14),
    isi_date = c("2026-01-11", "2026-01-12", "2027-01-12"),
    isi_tot_co = c(5, 11, 18),
    isi_tot_ca = c("No insomnia", "Subthreshold", "Moderate"),
    pp_status_sleep = c("Collected", "Ineligible", "Collected"),
    pp_status_sleep_in = c("", "Shift work", ""),
    pp_date_sleep = c("2026-01-13", "2026-01-14", "2027-01-14"),
    pp_time = c(2, NA, 1),
    scr_1w_date = c("2026-01-06", "2026-01-07", "2027-01-07"),
    scr_1w_shi_work = c("No", "Yes", "No"),
    scr_1w_treat_ap = c("No", "Yes", "No"),
    sleephealth_date = c("2026-01-13", "2026-01-14", "2027-01-14"),
    sleephealth_site_adm = c("Clayton", "Alfred", "Clayton"),
    sleephealth_ess_tot = c(6, 12, 9),
    ms_date = c("2026-01-14", "2026-01-15", "2027-01-15"),
    ms_bed_time = c("22:15", "23:00", "22:45"),
    ms_lights_out = c("22:30", "23:15", "23:00"),
    ms_slp_time = c("22:45", "23:45", "23:20"),
    ms_wake_time = c("06:30", "07:15", "06:50"),
    ms_lights_on = c("06:45", "07:30", "07:00"),
    ms_slp_dur_hr = c(7, 6, 6),
    ms_slp_dur_min = c(45, 10, 50),
    ms_compare_slp_dur = c("Same", "Shorter", "Same"),
    ms_light_deep = c("Moderate", "Light", "Deep"),
    ms_short_long = c("Average", "Short", "Average"),
    ms_restless_restful = c("Restful", "Restless", "Restful"),
    ms_compare_slp = c("Same", "Worse", "Better"),
    ms_diff_fall_aslp = c("No", "Yes", "No"),
    ms_min_fall_aslp = c(15, 40, 20),
    ms_compare_fall_dur = c("Same", "Longer", "Shorter"),
    ms_alc = c("No", "Yes", "No"),
    ms_alc_beer = c(0, 1, 0),
    ms_alc_wine = c(0, 0, 0),
    ms_alc_mixed = c(0, 1, 0),
    ms_caffeine = c("Yes", "Yes", "No"),
    ms_caff_coff = c(1, 2, 0),
    ms_caff_tea = c(0, 1, 0),
    ms_caff_soda = c(0, 0, 0),
    ms_smk = c("No", "Yes", "No"),
    ms_smk_freq = c(NA, "1", NA),
    ms_discomfort = c("None", "Back pain", "None"),
    ms_time_finish = c("06:50", "07:35", "07:05"),
    prose_passage = c("Passage A", "Passage B", "Passage A"),
    prose_time = c(90, 95, 100),
    prose_s1_imm_story = c(20, 18, 24),
    prose_s1_imm_theme = c(4, 3, 5),
    prose_s2_imm_story = c(21, 20, 22),
    prose_s2_imm_theme = c(4, 3, 5),
    prose_del_time = c(
      "2026-01-01 10:10:00",
      "2026-01-02 10:20:00",
      "2027-01-02 10:15:00"
    ),
    prose_timediff = c(15, 20, 25),
    prose_s1_del_story = c(19, 17, 20),
    prose_s1_del_theme = c(4, 2, 4),
    prose_s2_del_story = c(20, 18, 21),
    prose_s2_del_theme = c(4, 3, 4),
    stringsAsFactors = FALSE
  )

  for (night in seq_len(14)) {
    export_snapshot[[paste0("acti_type", night)]] <- c(
      ifelse(night %% 7 %in% c(0, 6), "Weekend", "Weekday"),
      ifelse((night + 1) %% 7 %in% c(0, 6), "Weekend", "Weekday"),
      ifelse((night + 2) %% 7 %in% c(0, 6), "Weekend", "Weekday")
    )
    export_snapshot[[paste0("acti_slp", night)]] <- c(
      sprintf("%02d:%02d", 21 + (night %% 2), night %% 6 * 5),
      sprintf("%02d:%02d", 22 + (night %% 2), night %% 6 * 5),
      sprintf("%02d:%02d", 22 + ((night + 1) %% 2), night %% 6 * 5)
    )
    export_snapshot[[paste0("acti_sot", night)]] <- c(
      sprintf("%02d:%02d", 22 + (night %% 2), 10 + (night %% 5) * 3),
      sprintf("%02d:%02d", 23, 15 + (night %% 5) * 3),
      sprintf("%02d:%02d", 23, 20 + (night %% 5) * 3)
    )
    export_snapshot[[paste0("acti_aslp", night)]] <- c(
      10 + night,
      15 + night,
      20 + night
    )
    export_snapshot[[paste0("acti_awk", night)]] <- c(
      night %% 3,
      (night + 1) %% 4,
      (night + 2) %% 4
    )
    export_snapshot[[paste0("acti_awkd", night)]] <- c(
      20 + night,
      30 + night,
      40 + night
    )
    export_snapshot[[paste0("acti_fin", night)]] <- c(
      sprintf("%02d:%02d", 6 + (night %% 2), 20 + (night %% 4) * 5),
      sprintf("%02d:%02d", 7 + (night %% 2), 15 + (night %% 4) * 5),
      sprintf("%02d:%02d", 7 + ((night + 1) %% 2), 10 + (night %% 4) * 5)
    )
    export_snapshot[[paste0("acti_outb", night)]] <- c(
      450 - night * 2,
      420 - night * 2,
      390 - night * 2
    )
    export_snapshot[[paste0("acti_tot_slp", night)]] <- c(
      420 - night * 2,
      390 - night * 2,
      360 - night * 2
    )
    export_snapshot[[paste0("acti_slp_eff", night)]] <- c(
      93 - night * 0.3,
      89 - night * 0.3,
      85 - night * 0.3
    )
  }

  export_snapshot$acti_watch_num <- c(14, 12, 10)
  export_snapshot$acti_av_slp <- c("22:15", "22:45", "23:10")
  export_snapshot$acti_av_sot <- c("22:30", "23:05", "23:35")
  export_snapshot$acti_av_aslp <- c(18, 24, 31)
  export_snapshot$acti_av_awk <- c(1, 2, 3)
  export_snapshot$acti_av_awkd <- c(28, 42, 55)
  export_snapshot$acti_av_fin <- c("06:40", "07:05", "07:20")
  export_snapshot$acti_av_outb <- c(445, 418, 392)
  export_snapshot$acti_av_tot_slp <- c(418, 390, 362)
  export_snapshot$acti_av_slp_eff <- c(92, 88, 84)
  export_snapshot$acti_wd_slp <- c("22:05", "22:35", "23:00")
  export_snapshot$acti_wd_sot <- c("22:20", "22:55", "23:25")
  export_snapshot$acti_wd_aslp <- c(15, 20, 28)
  export_snapshot$acti_wd_awk <- c(1, 2, 2)
  export_snapshot$acti_wd_awkd <- c(25, 36, 48)
  export_snapshot$acti_wd_fin <- c("06:30", "06:55", "07:10")
  export_snapshot$acti_wd_outb <- c(440, 412, 386)
  export_snapshot$acti_wd_tot_slp <- c(415, 388, 360)
  export_snapshot$acti_wd_slp_eff <- c(93, 89, 85)
  export_snapshot$acti_we_slp <- c("22:40", "23:10", "23:40")
  export_snapshot$acti_we_sot <- c("22:55", "23:25", "23:55")
  export_snapshot$acti_we_aslp <- c(24, 30, 36)
  export_snapshot$acti_we_awk <- c(2, 3, 4)
  export_snapshot$acti_we_awkd <- c(34, 48, 62)
  export_snapshot$acti_we_fin <- c("06:55", "07:20", "07:40")
  export_snapshot$acti_we_outb <- c(452, 425, 398)
  export_snapshot$acti_we_tot_slp <- c(420, 392, 364)
  export_snapshot$acti_we_slp_eff <- c(91, 87, 83)

  psg_sleepmed_rows <- data.frame(
    idno = c("BACH001", "BACH002", "BACH002"),
    redcap_event_name = c("Baseline", "Baseline", "Year 2"),
    redcap_repeat_instrument = rep(
      "Sleep Medications In Last Two Weeks",
      3
    ),
    redcap_repeat_instance = c(1, 1, 2),
    m2w_med_name = c("Melatonin", "Temazepam", "Zolpidem"),
    m2w_med_streng_pres = c("2 mg", "10 mg", "5 mg"),
    m2w_med_dose_pres = c("Nightly", "PRN", "Nightly"),
    m2w_med_freq_pres = c("1 tablet", "1 capsule", "1 tablet"),
    m2w_med_dose_taken = c("Nightly", "PRN", "Nightly"),
    m2w_med_freq_taken = c("1 tablet", "1 capsule", "1 tablet"),
    m2w_med_atc = c("N05CH01", "N05CD07", "N05CF02"),
    stringsAsFactors = FALSE
  )
  export_snapshot <- be_bind_rows_fill(list(export_snapshot, psg_sleepmed_rows))

  utils::write.csv(
    export_snapshot,
    file.path(shared_root, "snapshots", "redcap", "raw.csv"),
    row.names = FALSE
  )
  jsonlite::write_json(
    list(refreshed_at = "2026-03-11T00:00:00Z", source = "redcap"),
    file.path(shared_root, "snapshots", "redcap", "metadata.json"),
    auto_unbox = TRUE
  )
  jsonlite::write_json(
    list(families = "redcap"),
    file.path(shared_root, "snapshots", "sidecars", "snapshot-index.json"),
    auto_unbox = TRUE
  )

  shared_root
}

make_medications_export_shared_root <- function() {
  shared_root <- tempfile("shared-root-meds-")
  dir.create(file.path(shared_root, "snapshots", "redcap"), recursive = TRUE)
  dir.create(file.path(shared_root, "snapshots", "sidecars"), recursive = TRUE)
  populate_test_shared_app(shared_root)
  utils::write.csv(
    data.frame(
      POA_CODE_2016 = c("3000", "3001"),
      MB_CODE_2016 = c("MB1", "MB2"),
      decile_aus = c(9, 4),
      percentile_aus = c(90, 40),
      decile_state = c(8, 5),
      percentile_state = c(80, 50),
      stringsAsFactors = FALSE
    ),
    file.path(shared_root, "side-data", "absdf.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      MB_CODE_2016 = c("MB1", "MB2"),
      RA_NAME_2016 = c("Major Cities of Australia", "Inner Regional Australia"),
      STATE_NAME_2016 = c("Victoria", "Victoria"),
      stringsAsFactors = FALSE
    ),
    file.path(shared_root, "side-data", "RA_2016_AUST.csv"),
    row.names = FALSE
  )

  utils::write.csv(
    data.frame(
      idno = c("BACH001", "BACH001", "BACH001", "BACH001", "BACH002"),
      redcap_event_name = c(
        "Baseline",
        "Baseline",
        "Year 2",
        "Year 2",
        "Baseline"
      ),
      redcap_repeat_instrument = c(
        "",
        "Medications",
        "",
        "Medication Follow",
        "Baseline Visit"
      ),
      redcap_repeat_instance = c(NA, 1, NA, 2, NA),
      pp_date = c(
        "2026-01-01",
        "2026-01-01",
        "2027-01-02",
        "2027-01-02",
        "2026-01-03"
      ),
      age = c(70, NA, NA, NA, 71),
      sex = c("F", NA, NA, NA, "M"),
      highest_education = c("College", NA, NA, NA, "TAFE"),
      lying_systolic_bp_av = c(145, NA, NA, NA, 128),
      lying_diastolic_bp_av = c(88, NA, NA, NA, 82),
      bloods_chol = c(6.1, NA, NA, NA, 4.8),
      bloods_chol_hdl = c(1.4, NA, NA, NA, 1.2),
      bloods_ldl = c(3.8, NA, NA, NA, 3.0),
      bloods_trigly = c(2.1, NA, NA, NA, 1.5),
      med_name = c(NA, "Aspirin", NA, NA, NA),
      med_strength = c(NA, "100mg", NA, NA, NA),
      med_freq = c(NA, "daily", NA, NA, NA),
      med_times = c(NA, "1", NA, NA, NA),
      med_reason = c(NA, "Heart", NA, NA, NA),
      med_reas = c(NA, "Prevention", NA, NA, NA),
      med_pres = c(NA, "Yes", NA, NA, NA),
      med_atc = c(NA, "B01AC06", NA, NA, NA),
      mh_follow_meds_v2 = c(NA, NA, "Yes", "Yes", NA),
      mh_follow_meds_startstop_v2 = c(NA, NA, NA, "Start", NA),
      mh_follow_meds_n_v2 = c(NA, NA, NA, "Metformin", NA),
      mh_follow_meds_str_v2 = c(NA, NA, NA, "500mg", NA),
      mh_follow_meds_freq_v2 = c(NA, NA, NA, "bid", NA),
      mh_follow_meds_times_v2 = c(NA, NA, NA, "2", NA),
      mh_follow_meds_why_v2 = c(NA, NA, NA, "Diabetes", NA),
      mh_follow_meds_why_y_v2 = c(NA, NA, NA, "", NA),
      mh_follow_meds_presc_v2 = c(NA, NA, NA, "Yes", NA),
      mh_follow_meds_atc_v2 = c(NA, NA, NA, "A10BA02", NA),
      stringsAsFactors = FALSE
    ),
    file.path(shared_root, "snapshots", "redcap", "raw.csv"),
    row.names = FALSE
  )
  jsonlite::write_json(
    list(refreshed_at = "2026-03-11T00:00:00Z", source = "redcap"),
    file.path(shared_root, "snapshots", "redcap", "metadata.json"),
    auto_unbox = TRUE
  )
  jsonlite::write_json(
    list(families = "redcap"),
    file.path(shared_root, "snapshots", "sidecars", "snapshot-index.json"),
    auto_unbox = TRUE
  )

  shared_root
}

make_medical_history_export_shared_root <- function() {
  shared_root <- tempfile("shared-root-medhx-")
  dir.create(file.path(shared_root, "snapshots", "redcap"), recursive = TRUE)
  dir.create(file.path(shared_root, "snapshots", "sidecars"), recursive = TRUE)
  populate_test_shared_app(shared_root)

  utils::write.csv(
    data.frame(
      idno = c("BACH001", "BACH001", "BACH002", "BACH001"),
      redcap_event_name = c("Baseline", "Year 2", "Baseline", "Year 3"),
      pp_date = c("2026-01-01", "2027-01-01", "2026-01-02", "2028-01-01"),
      age = c(70, NA, 71, NA),
      sex = c("F", NA, "M", NA),
      highest_education = c("College", NA, "TAFE", NA),
      medical_history_date = c("2026-02-01", NA, "2026-02-02", NA),
      smoked_recent = c("No", NA, "Yes", NA),
      smoked_lifetime = c("Yes", NA, "Yes", NA),
      smoked_years = c(10, NA, 25, NA),
      smoked_number = c(0.5, NA, 1.0, NA),
      smoked_agequit = c(50, NA, NA, NA),
      cvd_heartattack = c("No", NA, "Yes", NA),
      cvd_atrialfibrillation = c("No", NA, "Yes", NA),
      cva_stroke = c("No", NA, "No", NA),
      medical_diabetes = c("No", NA, "Yes", NA),
      medical_hypertension = c("Yes", NA, "Yes", NA),
      medical_hypercholesterolemia = c("Yes", NA, "No", NA),
      medical_apnoea = c("No", NA, "Yes", NA),
      mh_notes = c("Baseline note", NA, "Second baseline note", NA),
      mh_follow_cogimpair_v2 = c(NA, "Yes", NA, "No"),
      mh_follow_cogimpair_y_v2 = c(NA, "Memory issues", NA, ""),
      mh_follow_cd_v2 = c(NA, "No", NA, "Yes"),
      mh_follow_mycardial_v2 = c(NA, "No", NA, "Yes"),
      mh_follow_stroke_v2 = c(NA, "No", NA, "Yes"),
      mh_follow_stroke_t_v2 = c(NA, "", NA, "Ischemic"),
      mh_follow_tia_v2 = c(NA, "No", NA, "Yes"),
      mh_follow_hf_v2 = c(NA, "No", NA, "No"),
      mh_follow_af_v2 = c(NA, "Yes", NA, "No"),
      mh_follow_cvd_other_v2 = c(NA, "", NA, "Valve repair"),
      mh_follow_cancer_v2 = c(NA, "No", NA, "Yes"),
      mh_follow_cancer_y_v2 = c(NA, "", NA, "Skin"),
      mh_follow_sleep_v2 = c(NA, "Yes", NA, "No"),
      mh_follow_sleep_y_v2 = c(NA, "Insomnia", NA, ""),
      mh_follow_psych_v2 = c(NA, "No", NA, "Yes"),
      mh_follow_psych_y_v2 = c(NA, "", NA, "Anxiety"),
      mh_follow_hosp_v2 = c(NA, "Yes", NA, "No"),
      mh_follow_hosp_y_v2 = c(NA, "Knee surgery", NA, ""),
      mh_follow_notes = c(NA, "Year 2 note", NA, "Year 3 note"),
      stringsAsFactors = FALSE
    ),
    file.path(shared_root, "snapshots", "redcap", "raw.csv"),
    row.names = FALSE
  )
  jsonlite::write_json(
    list(refreshed_at = "2026-03-11T00:00:00Z", source = "redcap"),
    file.path(shared_root, "snapshots", "redcap", "metadata.json"),
    auto_unbox = TRUE
  )
  jsonlite::write_json(
    list(families = "redcap"),
    file.path(shared_root, "snapshots", "sidecars", "snapshot-index.json"),
    auto_unbox = TRUE
  )

  shared_root
}

test_that("participants domain normalizes IDs and event years", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH002", "  BACH002  "),
    redcap_event_name = c("Baseline", "Baseline", "Year 2"),
    age = c(70, 71, NA),
    sex = c("F", "M", NA),
    highest_education = c("College", "TAFE", NA),
    stringsAsFactors = FALSE
  )

  result <- be_build_participants_domain(
    redcap_df,
    years = c("baseline", "year2")
  )

  expect_equal(result$participant_id, c("001", "002", "002"))
  expect_equal(result$subject_id, c("001", "002", "002"))
  expect_equal(result$session, c("Baseline", "Baseline", "Year 2"))
  expect_equal(result$year, c("baseline", "baseline", "year2"))
  expect_true(all(c("age", "sex", "education") %in% names(result)))
  expect_equal(result$education, c("College", "TAFE", "TAFE"))
})

test_that("core scaffold drops unsupported IDs and incomplete rows", {
  redcap_df <- data.frame(
    idno = c("BACH001--1", "BACH001--2", "BACH301", "BACH004"),
    redcap_event_name = c("Baseline", "Baseline", "Baseline", "Baseline"),
    pa_date = c("2026-01-01", "2026-01-01", "2026-01-02", "2026-01-03"),
    participated_assessment_complete = c("2", "2", "2", "Incomplete"),
    stringsAsFactors = FALSE
  )

  result <- be_build_core_scaffold_domain(redcap_df, years = "baseline")

  expect_equal(nrow(result), 1)
  expect_equal(result$participant_id, "001")
  expect_equal(result$subject_id, "001")
  expect_equal(result$session, "Baseline")
  expect_equal(result$session_date, "2026-01-01")
})

test_that("participants domain carries baseline demographics onto later years", {
  redcap_df <- data.frame(
    idno = c("BACH100", "BACH100"),
    redcap_event_name = c("Baseline", "Year 2"),
    age = c(65, NA),
    sex = c("F", NA),
    highest_education = c("University", NA),
    stringsAsFactors = FALSE
  )

  result <- be_build_participants_domain(redcap_df, years = "year2")

  expect_equal(result$participant_id, "100")
  expect_equal(result$year, "year2")
  expect_equal(result$age, 65)
  expect_equal(result$sex, "F")
  expect_equal(result$education, "University")
})

test_that("participant screening domain maps legacy screening fields", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH001", "BACH002"),
    redcap_event_name = c("Baseline", "Year 2", "Baseline"),
    age = c(70, NA, 71),
    sex = c("F", NA, "M"),
    education = c("College", NA, "TAFE"),
    highest_education = c("University", NA, "Diploma"),
    highest_education_other = c("Arts", NA, ""),
    stringsAsFactors = FALSE
  )

  result <- be_build_participant_screening_domain(redcap_df)

  expect_equal(result$participant_id, c("001", "002"))
  expect_true(all(
    c(
      "age",
      "sex",
      "education",
      "education_highest"
    ) %in%
      names(result)
  ))
  expect_equal(result$education_highest, c("University", "Diploma"))
  expect_equal(result$education_highest_other_detail[[1]], "Arts")
})

test_that("MRI and LP screening domains map baseline-only legacy fields", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH001", "BACH002"),
    redcap_event_name = c("Baseline", "Year 2", "Baseline"),
    handedness = c("Right", NA, "Left"),
    lp_interest = c("Interested", NA, "Declined"),
    stringsAsFactors = FALSE
  )

  mri_result <- be_build_mri_screening_domain(
    redcap_df,
    years = c("baseline", "year2")
  )
  lp_result <- be_build_lp_screening_domain(
    redcap_df,
    years = c("baseline", "year2")
  )

  expect_equal(mri_result$participant_id, c("001", "002"))
  expect_equal(mri_result$year, c("baseline", "baseline"))
  expect_equal(mri_result$handedness, c("Right", "Left"))

  expect_equal(lp_result$participant_id, c("001", "002"))
  expect_equal(lp_result$year, c("baseline", "baseline"))
  expect_equal(lp_result$lp_interest, c("Interested", "Declined"))
})

test_that("MRI domain merges baseline REDCap fields with shared side-data", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  redcap_df <- utils::read.csv(
    file.path(shared_root, "snapshots", "redcap", "raw.csv"),
    stringsAsFactors = FALSE
  )

  result <- be_build_mri_domain(
    redcap_df = redcap_df,
    shared_root = shared_root,
    years = c("baseline", "year2")
  )

  expect_equal(result$participant_id, c("001", "002"))
  expect_equal(result$year, c("baseline", "baseline"))
  expect_equal(result$mri_date, c("2026-01-06", "2026-01-07"))
  expect_equal(result$brainvol_novent, c(1100.5, 1048.2))
  expect_equal(result$hippo_left, c(3.2, 2.9))
})

test_that("LP domain maps REDCap event fields using legacy names", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  redcap_df <- utils::read.csv(
    file.path(shared_root, "snapshots", "redcap", "raw.csv"),
    stringsAsFactors = FALSE
  )

  result <- be_build_lp_domain(
    redcap_df = redcap_df,
    years = c("baseline", "year2")
  )

  expect_equal(result$participant_id, c("001", "002", "002"))
  expect_equal(result$year, c("baseline", "baseline", "year2"))
  expect_equal(result$lp_complete, c("Yes", "No", "Yes"))
  expect_equal(result$lp_fail_reason, c(NA, "Participant declined", NA))
  expect_equal(result$lp_fail_other, c(NA, "Too anxious", NA))
  expect_equal(
    result$lp_notes_detail,
    c(NA, "No sample collected", "Tolerated well")
  )
})

test_that("annual-phone MoCA, AD8, and UCLA domains map legacy fields by year", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH001", "BACH002"),
    redcap_event_name = c("Baseline", "Year 2", "Year 3"),
    pp_date = c("2026-01-01", "2027-01-01", "2028-01-01"),
    moca_total = c(25, 24, 23),
    ad8_who = c("Self", "Spouse", "Child"),
    ad8_date = c("2026-01-10", "2027-01-10", "2028-01-10"),
    ad8_total = c(1, 2, 3),
    ucla1_v2 = c(NA, 1, 2),
    ucla2_v2 = c(NA, 2, 3),
    ucla3_v2 = c(NA, 3, 4),
    ucla_total_v2 = c(NA, 6, 9),
    stringsAsFactors = FALSE
  )

  moca_result <- be_build_moca_domain(
    redcap_df,
    years = c("baseline", "year2", "year3")
  )
  ad8_result <- be_build_ad8_domain(
    redcap_df,
    years = c("baseline", "year2", "year3")
  )
  ucla_result <- be_build_ucla_domain(
    redcap_df,
    years = c("year2", "year3")
  )

  expect_equal(moca_result$participant_id, c("001", "001", "002"))
  expect_equal(moca_result$moca_total, c(25, 24, 23))
  expect_equal(
    moca_result$tele_date,
    c("2026-01-01", "2027-01-01", "2028-01-01")
  )

  expect_equal(ad8_result$ad8_person, c("Self", "Spouse", "Child"))
  expect_equal(ad8_result$ad8_total, c(1, 2, 3))
  expect_equal(
    ad8_result$tele_date,
    c("2026-01-01", "2027-01-01", "2028-01-01")
  )

  expect_equal(ucla_result$participant_id, c("001", "002"))
  expect_equal(ucla_result$year, c("year2", "year3"))
  expect_equal(ucla_result$ucla_total, c(6, 9))
})

test_that("baseline survey domains map demographics and questionnaire fields", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH002", "BACH002"),
    redcap_event_name = c("Baseline", "Baseline", "Year 2"),
    demographics_date = c("2026-01-01", "2026-01-02", NA),
    race = c("White", "Asian", NA),
    race_other = c("", "", NA),
    ethnicity = c("No", "Yes", NA),
    english_first = c("Yes", "No", NA),
    english_first_n = c(0, 10, NA),
    first_language = c("English", "Mandarin", NA),
    employment = c("Retired", "Part-time", NA),
    retire_age = c(65, NA, NA),
    occupation = c("Teacher", "Accountant", NA),
    personal_income = c("50-60k", "40-50k", NA),
    household_income = c("80-100k", "60-80k", NA),
    current_postcode = c("3000", "3001", NA),
    postcode_longest = c("3000", "3001", NA),
    postcode_longest_length = c(20, 15, NA),
    living_arrangements = c("Partner", "Family", NA),
    living_arrangements_other = c("", "", NA),
    number_household = c(2, 4, NA),
    relationship_status = c("Married", "Single", NA),
    ses_family = c("Average", "Low", NA),
    father_occ = c("Trades", "Farmer", NA),
    father_recent_occ = c("Manager", "Retired", NA),
    cesd_date = c("2026-01-03", "2026-01-04", NA),
    cesd_total = c(5, 7, NA),
    stai_date = c("2026-01-03", "2026-01-04", NA),
    stai_y1_tot = c(20, 25, NA),
    stai_y2_tot = c(30, 35, NA),
    pss_date = c("2026-01-03", "2026-01-04", NA),
    pss_total = c(10, 12, NA),
    cd_risc_date = c("2026-01-03", "2026-01-04", NA),
    cd_risc_total = c(28, 26, NA),
    ipaq_date = c("2026-01-03", "2026-01-04", NA),
    ipaq_vig_met = c(100, 200, NA),
    ipaq_mod_met = c(50, 80, NA),
    ipaq_walk_met = c(30, 40, NA),
    ipaq_tot_pa = c(180, 320, NA),
    ipaq_category = c("Moderate", "High", NA),
    rhhi_date = c("2026-01-03", "2026-01-04", NA),
    rhhi_total = c(2, 5, NA),
    mind_date = c("2026-01-03", "2026-01-04", NA),
    mind_total = c(8, 9, NA),
    alcohol_date = c("2026-01-03", "2026-01-04", NA),
    alcohol1 = c("Weekly", "Monthly", NA),
    alcohol1a = c(6, 4, NA),
    alcohol2 = c(1, 0, NA),
    alcohol3 = c("Rarely", "Never", NA),
    cfi_date = c("2026-01-03", "2026-01-04", NA),
    cfi_total = c(1, 3, NA),
    global_date = c("2026-01-03", "2026-01-04", NA),
    global_tot_physical = c(45, 40, NA),
    global_tot_mental = c(50, 42, NA),
    euro_qol = c(0.92, 0.81, NA),
    stringsAsFactors = FALSE
  )

  demographics <- be_build_demographics_domain(redcap_df, years = "baseline")
  cesd <- be_build_cesd_domain(redcap_df, years = "baseline")
  lifestyle <- be_build_alcohol_domain(redcap_df, years = "baseline")
  global_health <- be_build_global_health_domain(redcap_df, years = "baseline")

  expect_equal(demographics$participant_id, c("001", "002"))
  expect_equal(demographics$employment_status, c("Retired", "Part-time"))
  expect_equal(demographics$postcode_current, c("3000", "3001"))

  expect_equal(cesd$cesd_total, c(5, 7))
  expect_equal(lifestyle$alcoholq_12mo_freq, c("Weekly", "Monthly"))
  expect_equal(global_health$globhealth_index, c(0.92, 0.81))
})

test_that("SES and ARIA domains enrich demographics from shared side-data", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  redcap_df <- be_read_redcap_snapshot(shared_root)
  ses <- be_build_ses_domain(
    redcap_df,
    shared_root = shared_root,
    years = "baseline"
  )
  aria <- be_build_aria_domain(
    redcap_df,
    shared_root = shared_root,
    years = "baseline"
  )

  expect_equal(ses$participant_id, c("001", "002"))
  expect_equal(ses$ses_MB_CODE_2016, c("MB1", "MB2"))
  expect_equal(ses$ses_decile_aus, c(9, 4))
  expect_equal(ses$ses_percentile_state, c(80, 50))

  expect_equal(
    aria$RAname,
    c("Major Cities of Australia", "Inner Regional Australia")
  )
  expect_equal(aria$RAcategory, c("Urban", "Rural"))
})

test_that("clinical domains map baseline clinical fields and derived outcomes", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  redcap_df <- be_read_redcap_snapshot(shared_root)
  bloods <- be_build_bloods_domain(redcap_df, years = "baseline")
  vitals <- be_build_vitals_domain(redcap_df, years = "baseline")
  bp24h <- be_build_bp24h_domain(redcap_df, years = "baseline")

  expect_equal(bloods$bloods_success, c("Yes", "No"))
  expect_equal(
    round(bloods$bloods_cholratio, 2),
    round(c(5.5 / 1.5, 4.8 / 1.2), 2)
  )
  expect_true("bloods_tygindex" %in% names(bloods))

  expect_equal(round(vitals$vitals_pwv_mean, 2), c(8.2, 9.1))
  expect_equal(round(vitals$vitals_map, 2), c(95.67, 106.33))
  expect_equal(vitals$vitals_pulsepressure, c(50, 55))

  expect_equal(bp24h$BP24h_records, c(50, 48))
  expect_equal(bp24h$BP24h_asleep_sys_dip_percent, c(11, 8))
  expect_equal(bp24h$BP24h_dipper, c("Yes", "No"))
})

test_that("medical history domain maps baseline and follow-up clinical history fields", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH001", "BACH001"),
    redcap_event_name = c("Baseline", "Year 2", "Year 3"),
    medical_history_date = c("2026-02-01", NA, NA),
    smoked_recent = c("No", NA, NA),
    smoked_lifetime = c("Yes", NA, NA),
    smoked_years = c(10, NA, NA),
    smoked_number = c(0.5, NA, NA),
    smoked_agequit = c(50, NA, NA),
    cvd_heartattack = c("No", NA, NA),
    cvd_atrialfibrillation = c("No", NA, NA),
    medical_diabetes = c("No", NA, NA),
    medical_hypertension = c("Yes", NA, NA),
    medical_apnoea = c("No", NA, NA),
    mh_notes = c("Baseline note", NA, NA),
    mh_follow_cogimpair_v2 = c(NA, "Yes", "No"),
    mh_follow_cogimpair_y_v2 = c(NA, "Memory issues", ""),
    mh_follow_cd_v2 = c(NA, "No", "Yes"),
    mh_follow_mycardial_v2 = c(NA, "No", "Yes"),
    mh_follow_stroke_v2 = c(NA, "No", "Yes"),
    mh_follow_stroke_t_v2 = c(NA, "", "Ischemic"),
    mh_follow_tia_v2 = c(NA, "No", "Yes"),
    mh_follow_hf_v2 = c(NA, "No", "No"),
    mh_follow_af_v2 = c(NA, "Yes", "No"),
    mh_follow_cvd_other_v2 = c(NA, "", "Valve repair"),
    mh_follow_cancer_v2 = c(NA, "No", "Yes"),
    mh_follow_cancer_y_v2 = c(NA, "", "Skin"),
    mh_follow_sleep_v2 = c(NA, "Yes", "No"),
    mh_follow_sleep_y_v2 = c(NA, "Insomnia", ""),
    mh_follow_psych_v2 = c(NA, "No", "Yes"),
    mh_follow_psych_y_v2 = c(NA, "", "Anxiety"),
    mh_follow_hosp_v2 = c(NA, "Yes", "No"),
    mh_follow_hosp_y_v2 = c(NA, "Knee surgery", ""),
    mh_follow_notes = c(NA, "Year 2 note", "Year 3 note"),
    stringsAsFactors = FALSE
  )

  result <- be_build_medical_history_domain(
    redcap_df,
    years = c("baseline", "year2", "year3")
  )

  expect_equal(result$participant_id, c("001", "001", "001"))
  expect_equal(result$year, c("baseline", "year2", "year3"))
  expect_equal(result$medhx_date[[1]], "2026-02-01")
  expect_equal(result$smoking_current[[1]], "No")
  expect_equal(result$medhx_htn[[1]], "Yes")
  expect_equal(result$medhx_cogimpair[2:3], c("Yes", "No"))
  expect_equal(result$medhx_sleep_follow[2:3], c("Yes", "No"))
  expect_equal(result$medhx_hosp_detail[2], "Knee surgery")
  expect_equal(
    result$medhx_notes,
    c("Baseline note", "Year 2 note", "Year 3 note")
  )
})

test_that("similarities domain applies corrected stop-after-three-zeros score", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH001", "BACH002"),
    redcap_event_name = c("Baseline", "Year 2", "Year 3"),
    pp_date = c("2026-01-01", "2027-01-01", "2028-01-01"),
    similarities1 = c(1, 1, 1),
    similarities2 = c(1, 1, 1),
    similarities3 = c(1, 0, 1),
    similarities4 = c(0, 0, 1),
    similarities5 = c(0, 0, 1),
    similarities6 = c(0, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- be_build_similarities_domain(
    redcap_df,
    years = c("baseline", "year2", "year3")
  )

  expect_equal(result$participant_id, c("001", "001", "002"))
  expect_equal(result$year, c("baseline", "year2", "year3"))
  expect_equal(result$tele_similarities_corrected, c(3, 2, 6))
  expect_equal(result$tele_date, c("2026-01-01", "2027-01-01", "2028-01-01"))
})

test_that("prose passages domain maps legacy annual-phone prose fields", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH001", "BACH002"),
    redcap_event_name = c("Baseline", "Year 2", "Year 3"),
    prose_passage = c("Passage A", "Passage B", "Passage A"),
    prose_time = c(90, 95, 100),
    prose_s1_imm_story = c(20, 18, 24),
    prose_s1_imm_theme = c(4, 3, 5),
    prose_s2_imm_story = c(21, 20, 22),
    prose_s2_imm_theme = c(4, 3, 5),
    prose_del_time = c("09:10", "09:20", "09:30"),
    prose_timediff = c(15, 20, 25),
    prose_s1_del_story = c(19, 17, 20),
    prose_s1_del_theme = c(4, 2, 4),
    prose_s2_del_story = c(20, 18, 21),
    prose_s2_del_theme = c(4, 3, 4),
    stringsAsFactors = FALSE
  )

  result <- be_build_prose_passages_domain(
    redcap_df,
    years = c("baseline", "year2", "year3")
  )

  expect_equal(result$participant_id, c("001", "001", "002"))
  expect_equal(result$year, c("baseline", "year2", "year3"))
  expect_equal(
    result$tele_prose_version,
    c("Passage A", "Passage B", "Passage A")
  )
  expect_equal(result$tele_prose_imm_story1, c(20, 18, 24))
  expect_equal(result$tele_prose_delay_story2, c(20, 18, 21))
  expect_equal(result$tele_prose_imm_percorrect, c(41 / 51, 38 / 50, 46 / 51))
  expect_equal(result$tele_prose_del_percorrect, c(39 / 51, 35 / 50, 41 / 51))
})

test_that("cognitive screening domain maps tele_total to cogscreen_total", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH001", "BACH002"),
    redcap_event_name = c("Baseline", "Year 2", "Year 3"),
    tele_total = c(28, 27, 26),
    stringsAsFactors = FALSE
  )

  result <- be_build_cognitive_screening_domain(
    redcap_df,
    years = c("baseline", "year2", "year3")
  )

  expect_equal(result$participant_id, c("001", "001", "002"))
  expect_equal(result$year, c("baseline", "year2", "year3"))
  expect_equal(result$cogscreen_total, c(28, 27, 26))
})

test_that("medications domain returns one row per medication instance", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH001"),
    redcap_event_name = c("Baseline", "Year 2"),
    redcap_repeat_instrument = c("Medications", "Medication Follow"),
    redcap_repeat_instance = c(1, 2),
    med_name = c("Aspirin", NA),
    med_strength = c("100mg", NA),
    med_freq = c("daily", NA),
    med_times = c("1", NA),
    med_reason = c("Heart", NA),
    med_reas = c("Prevention", NA),
    med_pres = c("Yes", NA),
    med_atc = c("B01AC06", NA),
    mh_follow_meds_v2 = c(NA, "Yes"),
    mh_follow_meds_startstop_v2 = c(NA, "Start"),
    mh_follow_meds_n_v2 = c(NA, "Metformin"),
    mh_follow_meds_str_v2 = c(NA, "500mg"),
    mh_follow_meds_freq_v2 = c(NA, "bid"),
    mh_follow_meds_times_v2 = c(NA, "2"),
    mh_follow_meds_why_v2 = c(NA, "Diabetes"),
    mh_follow_meds_why_y_v2 = c(NA, ""),
    mh_follow_meds_presc_v2 = c(NA, "Yes"),
    mh_follow_meds_atc_v2 = c(NA, "A10BA02"),
    stringsAsFactors = FALSE
  )

  result <- be_build_medications_domain(
    redcap_df,
    years = c("baseline", "year2")
  )

  expect_equal(result$participant_id, c("001", "001"))
  expect_equal(result$repeat_instance, c("1", "2"))
  expect_equal(result$medication_name, c("Aspirin", "Metformin"))
  expect_equal(result$medication_atc, c("B01AC06", "A10BA02"))
})

test_that("medications wide domain keeps one row per participant year", {
  redcap_df <- data.frame(
    idno = c("BACH001", "BACH001", "BACH001", "BACH002"),
    redcap_event_name = c("Year 2", "Year 2", "Year 2", "Baseline"),
    redcap_repeat_instrument = c(
      "",
      "Medication Follow",
      "Medication Follow",
      ""
    ),
    redcap_repeat_instance = c(NA, 1, 2, NA),
    sex = c(NA, NA, NA, "Male"),
    mh_follow_meds_v2 = c("Yes", "Yes", "Yes", NA),
    mh_follow_meds_startstop_v2 = c(NA, "Start", "Stop", NA),
    mh_follow_meds_n_v2 = c(NA, "Metformin", "Diazepam", NA),
    mh_follow_meds_str_v2 = c(NA, "500mg", "5mg", NA),
    mh_follow_meds_freq_v2 = c(NA, "bid", "daily", NA),
    mh_follow_meds_times_v2 = c(NA, "2", "1", NA),
    mh_follow_meds_why_v2 = c(NA, "Diabetes", "Anxiety", NA),
    mh_follow_meds_why_y_v2 = c(NA, "", "", NA),
    mh_follow_meds_presc_v2 = c(NA, "Yes", "No", NA),
    mh_follow_meds_atc_v2 = c(NA, "A10BA02", "N05BA01", NA),
    lying_systolic_bp_av = c(NA, NA, NA, 128),
    lying_diastolic_bp_av = c(NA, NA, NA, 82),
    bloods_chol = c(NA, NA, NA, 4.8),
    bloods_chol_hdl = c(NA, NA, NA, 1.2),
    bloods_ldl = c(NA, NA, NA, 3.0),
    bloods_trigly = c(NA, NA, NA, 1.5),
    stringsAsFactors = FALSE
  )

  result <- be_build_medications_wide_domain(
    redcap_df,
    years = c("baseline", "year2")
  )

  expect_equal(nrow(result), 2)
  year2_row <- result[
    result$participant_id == "001" & result$year == "year2",
    ,
    drop = FALSE
  ]
  baseline_row <- result[
    result$participant_id == "002" & result$year == "baseline",
    ,
    drop = FALSE
  ]

  expect_equal(nrow(year2_row), 1)
  expect_equal(nrow(baseline_row), 1)
  expect_equal(year2_row$medication_change, "Yes")
  expect_equal(year2_row$medication_name_med_01, "Metformin")
  expect_equal(year2_row$medication_name_med_02, "Diazepam")
  expect_equal(year2_row$medication_atc_med_02, "N05BA01")
  expect_equal(year2_row$diabetes_meds, "Yes")
  expect_equal(year2_row$anxiety_meds, "Yes")
  expect_equal(year2_row$sedative_meds, "No")
  expect_true(is.na(year2_row$hypertension))
  expect_true(is.na(year2_row$dyslipidemia))
  expect_equal(baseline_row$diabetes_meds, "No")
  expect_equal(baseline_row$anxiety_meds, "No")
  expect_equal(baseline_row$hypertension, "No")
  expect_equal(baseline_row$dyslipidemia, "No")
})

test_that("run_export writes a snapshot-backed participants csv and manifest", {
  cache_dir <- tempfile("bach-cache-")
  old_cache_option <- getOption("bachExporter.local_cache_dir")
  options(bachExporter.local_cache_dir = cache_dir)
  on.exit(options(bachExporter.local_cache_dir = old_cache_option), add = TRUE)

  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "participants.csv")
  spec$domains <- "participants"
  spec$cohort$years <- "year2"

  result <- run_export(spec, refresh_mode = "auto")

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(
      participant_id = "character",
      subject_id = "character"
    )
  )
  manifest <- jsonlite::read_json(result$manifest, simplifyVector = TRUE)

  expect_equal(export_df$participant_id, "002")
  expect_equal(export_df$subject_id, "002")
  expect_equal(export_df$session, "Year 2")
  expect_equal(export_df$session_date, "2027-01-02")
  expect_equal(export_df$year, "year2")
  expect_equal(export_df$age, 71)
  expect_equal(export_df$education, "TAFE")
  expect_equal(manifest$domains, "participants")
  expect_equal(manifest$snapshot_metadata$redcap$source, "redcap")
  expect_equal(manifest$source$mode, "snapshot")
  expect_named(manifest$source, "mode")
  expect_equal(manifest$execution_mode, "targets")
})

test_that("run_export adds core scaffold columns to medications-only exports", {
  shared_root <- make_medications_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "medications.csv")
  spec$domains <- "medications"
  spec$cohort$years <- c("baseline", "year2")

  result <- run_export(
    spec,
    refresh_mode = "auto",
    execution_mode = "direct"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(
      participant_id = "character",
      subject_id = "character",
      repeat_instance = "character"
    )
  )

  expect_true(all(
    c("subject_id", "session", "session_date") %in% names(export_df)
  ))
  expect_equal(export_df$subject_id, c("001", "001"))
  expect_equal(export_df$session, c("Baseline", "Year 2"))
  expect_equal(export_df$session_date, c("2026-01-01", "2027-01-02"))
})

test_that("run_export supports annual-phone MoCA, AD8, and UCLA domains", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "annual-phone.csv")
  spec$domains <- c("participants", "moca", "ad8", "ucla")
  spec$cohort$years <- "year2"

  result <- run_export(
    spec,
    refresh_mode = "auto",
    execution_mode = "direct"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(
      participant_id = "character",
      subject_id = "character"
    )
  )

  expect_equal(export_df$participant_id, "002")
  expect_equal(export_df$moca_total, 23)
  expect_equal(export_df$ad8_person, "Child")
  expect_equal(export_df$ad8_total, 3)
  expect_equal(export_df$ucla_total, 9)
  expect_equal(export_df$tele_date, "2027-01-02")
})

test_that("run_export supports MRI domain with baseline-wide side-data merge", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "mri.csv")
  spec$domains <- c("participants", "mri")
  spec$cohort$years <- c("baseline", "year2")

  result <- run_export(
    spec,
    refresh_mode = "auto"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(export_df$participant_id, c(1, 2, 2))
  expect_equal(export_df$year, c("baseline", "baseline", "year2"))
  expect_equal(export_df$mri_date, c("2026-01-06", "2026-01-07", NA))
  expect_equal(export_df$brainvol_novent, c(1100.5, 1048.2, NA))
  expect_equal(export_df$hippo_right, c(3.4, 3.0, NA))
  expect_equal(export_df$wm_hypoint, c(12.1, 18.4, NA))
})

test_that("run_export supports LP domain", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "lp.csv")
  spec$domains <- c("participants", "lp")
  spec$cohort$years <- c("baseline", "year2")

  result <- run_export(
    spec,
    refresh_mode = "auto"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(export_df$participant_id, c(1, 2, 2))
  expect_equal(export_df$year, c("baseline", "baseline", "year2"))
  expect_equal(export_df$lp_complete, c("Yes", "No", "Yes"))
  expect_equal(export_df$lp_date, c("2026-01-08", "2026-01-09", "2027-01-09"))
  expect_equal(export_df$lp_time, c("11:00", "11:30", "11:15"))
  expect_equal(export_df$lp_fail_reason, c(NA, "Participant declined", NA))
  expect_equal(export_df$lp_fail_other, c(NA, "Too anxious", NA))
  expect_equal(export_df$lp_notes, c("Clear CSF", NA, "Repeat procedure"))
  expect_equal(
    export_df$lp_notes_detail,
    c(NA, "No sample collected", "Tolerated well")
  )
})

test_that("run_export supports PSG questionnaire and screening domains", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "psg-questionnaires.csv")
  spec$domains <- c(
    "participants",
    "psg_screening",
    "psg_sleephealth",
    "psg_sleepmed",
    "psg_morningquest"
  )
  spec$cohort$years <- c("baseline", "year2")

  result <- run_export(
    spec,
    refresh_mode = "auto"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(export_df$participant_id, c(1, 2, 2))
  expect_equal(
    export_df$psg_collected,
    c("Collected", "Ineligible", "Collected")
  )
  expect_equal(export_df$psg_ineligible_detail, c(NA, "Shift work", NA))
  expect_equal(export_df$psg_sleephealth_total, c(6, 12, 9))
  expect_equal(export_df$psg_medication_name_med_psg_01[[1]], "Melatonin")
  expect_equal(export_df$psg_medication_name_med_psg_01[[2]], "Temazepam")
  expect_equal(export_df$psg_medication_name_med_psg_02[[3]], "Zolpidem")
  expect_equal(export_df$psg_medication_atc_med_psg_02[[3]], "N05CF02")
  expect_equal(
    export_df$psg_morningquest_sleep_depth,
    c("Moderate", "Light", "Deep")
  )
  expect_equal(export_df$psg_morningquest_caffiene_coffee, c(1, 2, 0))
  expect_equal(
    export_df$psg_morningquest_discomfort,
    c("None", "Back pain", "None")
  )
})

test_that("run_export supports PSG summary and full domains", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  summary_spec <- be_default_export_spec(shared_root = shared_root)
  summary_spec$output$path <- file.path(output_dir, "psg-summary.csv")
  summary_spec$domains <- c("participants", "psg_summary")
  summary_spec$cohort$years <- c("baseline", "year2")

  summary_result <- run_export(summary_spec, refresh_mode = "auto")
  summary_df <- utils::read.csv(
    summary_result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(summary_df$participant_id, c(1, 2, 2))
  expect_equal(summary_df$psg_location, c("Lab", "Home", "Home"))
  expect_equal(summary_df$psg_ess, c(6, 12, 12))
  expect_equal(summary_df$psg_tst, c(390, 360, 360))
  expect_equal(summary_df$psg_ahi_total_all, c(8.1, 26.4, 26.4))
  expect_equal(summary_df$psg_odi_4per, c(5.3, 18.6, 18.6))
  expect_false("psg_hr_avg" %in% names(summary_df))
  expect_false("psg_rswa" %in% names(summary_df))

  full_spec <- be_default_export_spec(shared_root = shared_root)
  full_spec$output$path <- file.path(output_dir, "psg-full.csv")
  full_spec$domains <- c("participants", "psg_full")
  full_spec$cohort$years <- c("baseline", "year2")

  full_result <- run_export(full_spec, refresh_mode = "auto")
  full_df <- utils::read.csv(
    full_result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(full_df$psg_hr_avg, c(58, 64, 64))
  expect_equal(full_df$psg_hr_highest, c(77, 89, 89))
  expect_equal(full_df$psg_rswa, c("Yes", "No", "No"))

  full_spec$options$cat_labels <- "numbered"
  full_spec$output$path <- file.path(output_dir, "psg-full-numbered.csv")
  numbered_result <- run_export(full_spec, refresh_mode = "auto")
  numbered_df <- utils::read.csv(
    numbered_result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(numbered_df$psg_rswa, c(1, 0, 0))
})

test_that("run_export supports CDR and MMSE neuropsych domains", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "neuropsych.csv")
  spec$domains <- c("participants", "cdr", "mmse")
  spec$cohort$years <- c("baseline", "year2")

  result <- run_export(
    spec,
    refresh_mode = "auto"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(export_df$participant_id, c(1, 2, 2))
  expect_equal(export_df$year, c("baseline", "baseline", "year2"))
  expect_equal(
    export_df$neuropsych_date,
    c("2026-01-07", "2026-01-08", "2027-01-08")
  )
  expect_equal(export_df$cdr_sobscore, c(0, 1.5, 4))
  expect_equal(export_df$cdr_globalscore, c(0, 0.5, 1))
  expect_equal(export_df$mmse_total, c(29, 27, 24))
  expect_equal(export_df$mmse_notes, c(NA, "Needed prompting", "Fatigued"))
  expect_equal(
    export_df$mmse_notes_detail,
    c(NA, "Serial sevens slow", "Attention drift")
  )
})

test_that("run_export supports extended neuropsych battery domains", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "neuropsych-battery.csv")
  spec$domains <- c(
    "participants",
    "sydbat",
    "logical_memory",
    "visual_reproduction",
    "tmt",
    "fab",
    "cowat",
    "hvot",
    "tasit",
    "topf"
  )
  spec$cohort$years <- c("baseline", "year2")

  result <- run_export(
    spec,
    refresh_mode = "auto"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(export_df$participant_id, c(1, 2, 2))
  expect_equal(export_df$sydbat_naming, c(27, 24, 21))
  expect_equal(export_df$logicalmem_delay_total, c(21, 19, 17))
  expect_equal(export_df$visualrepro2_total, c(18, 16, 14))
  expect_equal(export_df$tmtbminusa, c(45, 53, 65))
  expect_equal(export_df$fab_total, c(18, 14, 10))
  expect_equal(export_df$cowat_total, c(42, 33, 27))
  expect_equal(export_df$hvot_total, c(25, 22, 18))
  expect_equal(export_df$tasit_total, c(15, 13, 11))
  expect_equal(export_df$topf_total_corrected, c(3, 2, 4))
})

test_that("run_export supports dementia status domain", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "dementia-status.csv")
  spec$domains <- c("participants", "dementia_status")
  spec$cohort$years <- c("baseline", "year2")

  result <- run_export(
    spec,
    refresh_mode = "auto"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(export_df$participant_id, c(1, 2, 2))
  expect_equal(
    export_df$demreview_date,
    c("2026-01-09", "2026-01-10", "2027-01-10")
  )
  expect_equal(export_df$demreview_status, c("No dementia", "MCI", "Dementia"))
  expect_equal(export_df$demreview_onset, c(NA, "2025-06-01", "2026-06-01"))
  expect_equal(
    export_df$demreview_intactdate,
    c("2026-01-09", "2025-05-01", "2026-05-01")
  )
  expect_equal(
    export_df$demreview_notes,
    c(NA, "Monitor progression", "Consensus adjudication")
  )
})

test_that("run_export supports sleep questionnaire domains", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "sleep-questionnaires.csv")
  spec$domains <- c("participants", "psqi", "ess", "isi")
  spec$cohort$years <- c("baseline", "year2")

  result <- run_export(
    spec,
    refresh_mode = "auto"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(export_df$participant_id, c(1, 2, 2))
  expect_equal(export_df$psqi_total, c(4, 8, 11))
  expect_equal(export_df$psqi_q5j_other_detail, c(NA, "Noise", "Leg cramps"))
  expect_equal(export_df$psqi_comp5_sub, c(2, 4, 6))
  expect_equal(export_df$ess_total, c(4, 9, 14))
  expect_equal(export_df$isi_cont_score, c(5, 11, 18))
  expect_equal(
    export_df$isi_cat_score,
    c("No insomnia", "Subthreshold", "Moderate")
  )
})

test_that("run_export supports actigraphy full and summary domains", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "actigraphy.csv")
  spec$domains <- c("participants", "actigraphy_full", "actigraphy_summary")
  spec$cohort$years <- c("baseline", "year2")

  result <- run_export(
    spec,
    refresh_mode = "auto"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  expect_equal(export_df$participant_id, c(1, 2, 2))
  expect_equal(
    export_df$acti_night1_daytype,
    c("Weekday", "Weekday", "Weekday")
  )
  expect_equal(export_df$acti_night1_onset_latency, c(11, 16, 21))
  expect_equal(export_df$acti_night14_TST, c(392, 362, 332))
  expect_equal(export_df$acti_nightsrecorded, c(14, 12, 10))
  expect_equal(export_df$acti_avg_TST, c(418, 390, 362))
  expect_equal(export_df$acti_weekday_avg_SE, c(93, 89, 85))
  expect_equal(export_df$acti_weekend_total_WASO, c(34, 48, 62))
})

test_that("run_export supports baseline survey and demographics domains", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "baseline-surveys.csv")
  spec$domains <- c(
    "participants",
    "demographics",
    "cesd",
    "stai",
    "pss",
    "cdrisc",
    "ipaq",
    "rhhi",
    "minddiet",
    "alcohol",
    "cfi",
    "global_health"
  )
  spec$cohort$years <- "baseline"

  result <- run_export(
    spec,
    refresh_mode = "auto",
    execution_mode = "direct"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(
      participant_id = "character",
      subject_id = "character"
    )
  )

  expect_equal(export_df$participant_id, c("001", "002"))
  expect_equal(export_df$employment_status, c("Retired", "Part-time"))
  expect_equal(export_df$cesd_total, c(5, 7))
  expect_equal(export_df$stai_total_trait, c(30, 35))
  expect_equal(export_df$ipaq_total_met, c(180, 320))
  expect_equal(export_df$alcoholq_12mo_freq, c("Weekly", "Monthly"))
  expect_equal(export_df$globhealth_index, c(0.92, 0.81))
})

test_that("run_export supports SES and ARIA enrichment from shared side-data", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "baseline-ses-aria.csv")
  spec$domains <- c("participants", "demographics", "ses", "aria")
  spec$cohort$years <- "baseline"

  result <- run_export(
    spec,
    refresh_mode = "auto",
    execution_mode = "direct"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(
      participant_id = "character",
      subject_id = "character",
      ses_MB_CODE_2016 = "character"
    )
  )

  expect_equal(export_df$participant_id, c("001", "002"))
  expect_equal(export_df$ses_MB_CODE_2016, c("MB1", "MB2"))
  expect_equal(export_df$ses_decile_aus, c(9, 4))
  expect_equal(export_df$RAcategory, c("Urban", "Rural"))
})

test_that("run_export supports baseline clinical domains", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "baseline-clinical.csv")
  spec$domains <- c("participants", "bloods", "vitals", "bp24h")
  spec$cohort$years <- "baseline"

  result <- run_export(
    spec,
    refresh_mode = "auto",
    execution_mode = "direct"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(
      participant_id = "character",
      subject_id = "character"
    )
  )

  expect_equal(export_df$participant_id, c("001", "002"))
  expect_equal(export_df$bloods_success, c("Yes", "No"))
  expect_equal(round(export_df$vitals_pwv_mean, 2), c(8.2, 9.1))
  expect_equal(round(export_df$vitals_map, 2), c(95.67, 106.33))
  expect_equal(export_df$BP24h_dipper, c("Yes", "No"))
})

test_that("run_export supports multi-year medical history exports", {
  shared_root <- make_medical_history_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "medical-history.csv")
  spec$domains <- c("participants", "medical_history")
  spec$cohort$years <- c("baseline", "year2", "year3")

  result <- run_export(
    spec,
    refresh_mode = "auto",
    execution_mode = "direct"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(
      participant_id = "character",
      subject_id = "character"
    )
  )

  expect_equal(export_df$participant_id, c("001", "001", "001", "002"))
  expect_equal(export_df$subject_id, c("001", "001", "001", "002"))
  expect_equal(export_df$year, c("baseline", "year2", "year3", "baseline"))
  expect_equal(
    export_df$session_date,
    c("2026-01-01", "2027-01-01", "2028-01-01", "2026-01-02")
  )
  expect_equal(
    export_df$medhx_notes,
    c("Baseline note", "Year 2 note", "Year 3 note", "Second baseline note")
  )
  expect_equal(export_df$medhx_cogimpair[2:3], c("Yes", "No"))
  expect_equal(export_df$medhx_sleep_follow[2:3], c("Yes", "No"))
  expect_equal(export_df$medhx_hosp_detail[[2]], "Knee surgery")
})

test_that("run_export supports direct mode for export debugging", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "participants-direct.csv")
  spec$domains <- "participants"
  spec$cohort$years <- "year2"

  result <- run_export(
    spec,
    refresh_mode = "auto",
    execution_mode = "direct"
  )

  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(participant_id = "character")
  )
  manifest <- jsonlite::read_json(result$manifest, simplifyVector = TRUE)

  expect_equal(export_df$participant_id, "002")
  expect_equal(manifest$execution_mode, "direct")
  expect_equal(manifest$source$mode, "snapshot")
})

test_that("targets script writer emits ASCII-quoted paths", {
  script_path <- tempfile("targets-script-", fileext = ".R")
  on.exit(unlink(script_path), add = TRUE)

  spec <- be_default_export_spec(shared_root = "/tmp/shared-root")
  spec$output$path <- "/tmp/output.csv"

  be_write_export_targets_script(
    script_path = script_path,
    spec = spec,
    shared_root = "/tmp/shared-root",
    refresh_mode = "auto",
    project_root = getwd()
  )

  script_lines <- readLines(script_path, warn = FALSE)
  project_root_line <- grep("^project_root <- ", script_lines, value = TRUE)
  shared_root_line <- grep("^shared_root <- ", script_lines, value = TRUE)

  expect_length(project_root_line, 1)
  expect_length(shared_root_line, 1)
  expect_match(project_root_line, '^project_root <- "')
  expect_match(shared_root_line, '^shared_root <- "')
  expect_false(any(grepl("[“”]", script_lines)))
})

test_that("export validation rejects unsupported source modes and years", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- tempfile(fileext = ".csv")

  spec$source$mode <- "redcap"
  source_result <- be_validate_export_spec(spec)
  expect_false(source_result$ok)
  expect_match(source_result$message, "snapshot mode")

  spec$source$mode <- "snapshot"
  spec$cohort$years <- c("baseline", "year4")
  year_result <- be_validate_export_spec(spec)
  expect_false(year_result$ok)
  expect_match(year_result$message, "not supported")
})

test_that("export validation rejects extra researcher source settings", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- tempfile(fileext = ".csv")
  spec$source$redcap_url <- "https://redcap.example.org/api/"
  spec$source$api_token <- "not-allowed"

  validation <- be_validate_export_spec(spec)

  expect_false(validation$ok)
  expect_match(validation$message, "snapshot-only")
  expect_match(validation$message, "api_token")
  expect_match(validation$message, "redcap_url")
})

test_that("export validation rejects duplicate domains and empty years", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- tempfile(fileext = ".csv")
  spec$cohort$years <- character()

  no_years <- be_validate_export_spec(spec)
  expect_false(no_years$ok)
  expect_match(no_years$message, "at least one cohort year")

  spec$cohort$years <- "baseline"
  spec$domains <- c("participants", "participants")

  duplicate_domains <- be_validate_export_spec(spec)
  expect_false(duplicate_domains$ok)
  expect_match(duplicate_domains$message, "domains must be unique")
})

test_that("run_export merges participant screening onto participants output", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "participants-screening.csv")
  spec$domains <- c("participants", "participant_screening")
  spec$cohort$years <- "year2"

  result <- run_export(spec, refresh_mode = "auto")
  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(participant_id = "character")
  )

  expect_equal(export_df$participant_id, "002")
  expect_equal(export_df$education_highest, "TAFE")
})

test_that("run_export merges similarities onto participants output", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "participants-similarities.csv")
  spec$domains <- c("participants", "similarities")
  spec$cohort$years <- "year2"

  result <- run_export(spec, refresh_mode = "auto")
  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(participant_id = "character")
  )

  expect_equal(export_df$participant_id, "002")
  expect_equal(export_df$tele_date, "2027-01-02")
  expect_equal(export_df$tele_similarities_corrected, 3)
})

test_that("run_export merges prose passages onto participants output", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "participants-prose.csv")
  spec$domains <- c("participants", "prose_passages")
  spec$cohort$years <- "year2"

  result <- run_export(spec, refresh_mode = "auto")
  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(participant_id = "character")
  )

  expect_equal(export_df$participant_id, "002")
  expect_equal(export_df$tele_prose_version, "Passage A")
  expect_equal(export_df$tele_prose_imm_story1, 24)
  expect_equal(export_df$tele_prose_imm_percorrect, 46 / 51)
  expect_equal(export_df$tele_prose_del_percorrect, 41 / 51)
})

test_that("run_export merges cognitive screening onto participants output", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "participants-cognitive.csv")
  spec$domains <- c("participants", "cognitive_screening")
  spec$cohort$years <- "year2"

  result <- run_export(spec, refresh_mode = "auto")
  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(participant_id = "character")
  )

  expect_equal(export_df$participant_id, "002")
  expect_equal(export_df$cogscreen_total, 26)
})

test_that("run_export merges medications onto participants without row explosion", {
  cache_dir <- tempfile("bach-cache-")
  old_cache_option <- getOption("bachExporter.local_cache_dir")
  options(bachExporter.local_cache_dir = cache_dir)
  on.exit(options(bachExporter.local_cache_dir = old_cache_option), add = TRUE)

  shared_root <- make_medications_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "participants-medications.csv")
  spec$domains <- c("participants", "medications")
  spec$cohort$years <- c("baseline", "year2")
  spec$cohort$participant_ids <- "BACH001"

  result <- run_export(spec, refresh_mode = "auto")
  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(participant_id = "character")
  )

  expect_equal(nrow(export_df), 2)
  expect_equal(export_df$participant_id, c("001", "001"))
  expect_equal(export_df$medication_name_med_01[[1]], "Aspirin")
  expect_equal(export_df$medication_name_med_02[[2]], "Metformin")
  expect_equal(export_df$depression_meds, c("No", "No"))
  expect_equal(export_df$diabetes_meds, c("No", "Yes"))
  expect_equal(export_df$hypertension, c("Yes", NA))
  expect_equal(export_df$dyslipidemia, c("Yes", NA))
})

test_that("run_export can export medications as a standalone long table", {
  cache_dir <- tempfile("bach-cache-")
  old_cache_option <- getOption("bachExporter.local_cache_dir")
  options(bachExporter.local_cache_dir = cache_dir)
  on.exit(options(bachExporter.local_cache_dir = old_cache_option), add = TRUE)

  shared_root <- make_medications_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "medications.csv")
  spec$domains <- "medications"
  spec$cohort$years <- c("baseline", "year2")
  spec$cohort$participant_ids <- "BACH001"

  result <- run_export(spec, refresh_mode = "auto")
  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(participant_id = "character", repeat_instance = "character")
  )

  expect_equal(nrow(export_df), 2)
  expect_equal(export_df$repeat_instance, c("1", "2"))
  expect_equal(export_df$medication_name, c("Aspirin", "Metformin"))
})

test_that("unsupported domains fail validation clearly", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- tempfile(fileext = ".csv")
  spec$domains <- c("participants", "annual_phone")

  validation <- be_validate_export_spec(spec)

  expect_false(validation$ok)
  expect_match(validation$message, "not implemented yet")
})

test_that("validation fails clearly when MRI side-data is missing", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)
  unlink(file.path(shared_root, "side-data", "global_n241.csv"))

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- tempfile(fileext = ".csv")
  spec$domains <- c("participants", "mri")

  validation <- be_validate_export_spec(spec)

  expect_false(validation$ok)
  expect_match(validation$message, "MRI side-data is missing")
})

test_that("validation fails clearly when PSG side-data is missing", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)
  unlink(file.path(shared_root, "side-data", "psg_data.csv"))

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- tempfile(fileext = ".csv")
  spec$domains <- c("participants", "psg_summary")

  validation <- be_validate_export_spec(spec)

  expect_false(validation$ok)
  expect_match(validation$message, "PSG side-data is missing")
})

test_that("run_export filters by participant_ids from the spec", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "participants-filtered.csv")
  spec$domains <- "participants"
  spec$cohort$years <- c("baseline", "year2")
  spec$cohort$participant_ids <- "BACH001"

  result <- run_export(spec, refresh_mode = "auto")
  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(participant_id = "character")
  )

  expect_equal(export_df$participant_id, "001")
})

test_that("run_export filters by participant IDs from a subset file", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  subset_file <- file.path(output_dir, "subset.txt")
  writeLines(c("BACH002"), subset_file)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "participants-subset.csv")
  spec$domains <- "participants"
  spec$cohort$years <- c("baseline", "year2")
  spec$cohort$subset_file <- subset_file

  result <- run_export(spec, refresh_mode = "auto")
  export_df <- utils::read.csv(
    result$output,
    stringsAsFactors = FALSE,
    colClasses = c(participant_id = "character")
  )

  expect_equal(unique(export_df$participant_id), "002")
})

test_that("manifest strips unsupported source placeholders from researcher export", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  output_dir <- tempfile("export-dir-")
  dir.create(output_dir, recursive = TRUE)
  on.exit(unlink(output_dir, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- file.path(output_dir, "participants.csv")
  spec$domains <- "participants"
  spec$cohort$years <- "year2"

  manifest <- be_build_export_manifest(
    spec = spec,
    shared_root = shared_root,
    refresh_mode = "auto",
    execution_mode = "direct"
  )

  expect_equal(manifest$source$mode, "snapshot")
  expect_named(manifest$source, "mode")
})

test_that("validation fails clearly when subset_file is missing", {
  shared_root <- make_export_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  spec <- be_default_export_spec(shared_root = shared_root)
  spec$output$path <- tempfile(fileext = ".csv")
  spec$cohort$subset_file <- file.path(shared_root, "missing.txt")

  validation <- be_validate_export_spec(spec)

  expect_false(validation$ok)
  expect_match(validation$message, "Subset file does not exist")
})
