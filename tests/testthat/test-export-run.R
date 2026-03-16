source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "release_runtime.R"))
source(file.path("..", "..", "R", "config.R"))
source(file.path("..", "..", "R", "source_snapshots.R"))
source(file.path("..", "..", "R", "normalize_redcap.R"))
source(file.path("..", "..", "R", "cohort_filters.R"))
source(file.path("..", "..", "R", "split_events.R"))
source(file.path("..", "..", "R", "domain_participants.R"))
source(file.path("..", "..", "R", "domain_screening_aux.R"))
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

make_export_shared_root <- function() {
  shared_root <- tempfile("shared-root-")
  dir.create(file.path(shared_root, "snapshots", "redcap"), recursive = TRUE)
  dir.create(file.path(shared_root, "snapshots", "sidecars"), recursive = TRUE)

  writeLines("dev", file.path(shared_root, "CURRENT_RELEASE.txt"))
  dir.create(
    file.path(shared_root, "releases", "dev", "R"),
    recursive = TRUE
  )
  dir.create(
    file.path(shared_root, "releases", "dev", "scripts"),
    recursive = TRUE
  )
  writeLines(
    c("Package: bachExporter", "Version: 0.0.1"),
    file.path(shared_root, "releases", "dev", "DESCRIPTION")
  )
  file.copy(
    file.path("..", "..", "NAMESPACE"),
    file.path(shared_root, "releases", "dev", "NAMESPACE")
  )
  file.copy(
    file.path("..", "..", "R", "paths.R"),
    file.path(shared_root, "releases", "dev", "R", "paths.R")
  )
  file.copy(
    file.path("..", "..", "R", "release_runtime.R"),
    file.path(shared_root, "releases", "dev", "R", "release_runtime.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "launch_from_share.R"),
    file.path(shared_root, "releases", "dev", "scripts", "launch_from_share.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "validate_release.R"),
    file.path(shared_root, "releases", "dev", "scripts", "validate_release.R")
  )

  utils::write.csv(
    data.frame(
      idno = c("BACH001", "BACH002", "BACH002"),
      redcap_event_name = c("Baseline", "Baseline", "Year 2"),
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

make_medications_export_shared_root <- function() {
  shared_root <- tempfile("shared-root-meds-")
  dir.create(file.path(shared_root, "snapshots", "redcap"), recursive = TRUE)
  dir.create(file.path(shared_root, "snapshots", "sidecars"), recursive = TRUE)

  writeLines("dev", file.path(shared_root, "CURRENT_RELEASE.txt"))
  dir.create(
    file.path(shared_root, "releases", "dev", "R"),
    recursive = TRUE
  )
  dir.create(
    file.path(shared_root, "releases", "dev", "scripts"),
    recursive = TRUE
  )
  writeLines(
    c("Package: bachExporter", "Version: 0.0.1"),
    file.path(shared_root, "releases", "dev", "DESCRIPTION")
  )
  file.copy(
    file.path("..", "..", "NAMESPACE"),
    file.path(shared_root, "releases", "dev", "NAMESPACE")
  )
  file.copy(
    file.path("..", "..", "R", "paths.R"),
    file.path(shared_root, "releases", "dev", "R", "paths.R")
  )
  file.copy(
    file.path("..", "..", "R", "release_runtime.R"),
    file.path(shared_root, "releases", "dev", "R", "release_runtime.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "launch_from_share.R"),
    file.path(shared_root, "releases", "dev", "scripts", "launch_from_share.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "validate_release.R"),
    file.path(shared_root, "releases", "dev", "scripts", "validate_release.R")
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
    idno = c("BACH001", "BACH001", "BACH001"),
    redcap_event_name = c("Year 2", "Year 2", "Year 2"),
    redcap_repeat_instrument = c("", "Medication Follow", "Medication Follow"),
    redcap_repeat_instance = c(NA, 1, 2),
    mh_follow_meds_v2 = c("Yes", "Yes", "Yes"),
    mh_follow_meds_startstop_v2 = c(NA, "Start", "Stop"),
    mh_follow_meds_n_v2 = c(NA, "Metformin", "Vitamin D"),
    mh_follow_meds_str_v2 = c(NA, "500mg", "1000IU"),
    mh_follow_meds_freq_v2 = c(NA, "bid", "daily"),
    mh_follow_meds_times_v2 = c(NA, "2", "1"),
    mh_follow_meds_why_v2 = c(NA, "Diabetes", "Bone"),
    mh_follow_meds_why_y_v2 = c(NA, "", ""),
    mh_follow_meds_presc_v2 = c(NA, "Yes", "No"),
    mh_follow_meds_atc_v2 = c(NA, "A10BA02", "A11CC05"),
    stringsAsFactors = FALSE
  )

  result <- be_build_medications_wide_domain(redcap_df, years = "year2")

  expect_equal(nrow(result), 1)
  expect_equal(result$medication_change, "Yes")
  expect_equal(result$medication_name_med_01, "Metformin")
  expect_equal(result$medication_name_med_02, "Vitamin D")
  expect_equal(result$medication_atc_med_02, "A11CC05")
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
