source(file.path("..", "..", "R", "domain_medications.R"))
source(file.path("..", "..", "R", "domain_sleep.R"))

test_that("repeat instrument matchers accept raw and labelled REDCap names", {
  expect_true(all(
    c(
      "Medications",
      "Medication Follow",
      "medications",
      "medication_follow_2"
    ) %in%
      be_medication_repeat_labels()
  ))
  expect_true(all(
    c("Medications", "medications") %in%
      be_medication_baseline_repeat_labels()
  ))
  expect_true(all(
    c("Medication Follow", "medication_follow_2") %in%
      be_medication_follow_repeat_labels()
  ))
  expect_true(all(
    c(
      "Sleep Medications In Last Two Weeks",
      "sleep_medications_in_last_two_weeks"
    ) %in%
      be_psg_medication_repeat_labels()
  ))
})
