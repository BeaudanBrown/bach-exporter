source(file.path("..", "..", "R", "normalize_redcap.R"))
source(file.path("..", "..", "R", "derived_clinical.R"))
source(file.path("..", "..", "R", "derived_neuropsych.R"))
source(file.path("..", "..", "R", "derived_biomarkers.R"))
source(file.path("..", "..", "R", "derived_genomics.R"))
source(file.path("..", "..", "R", "derived_sleep.R"))

test_that("clinical derived helpers compute ratios and hemodynamics", {
  expect_equal(be_compute_ratio(c(10, 10, NA), c(2, 0, 2)), c(5, NA, NA))
  expect_equal(
    round(be_compute_tyg_index(1.5, 5.5), 6),
    round(log(((1.5 * 88.545) * (5.5 * 18.0)) / 2), 6)
  )
  expect_equal(
    be_compute_pwv_mean(c(10, 10), c(12, NA), c(14, NA), c(NA, 11)),
    c(12, 11)
  )
  expect_equal(
    be_compute_mean_arterial_pressure(c(120, NA), c(90, 80)),
    c(100, NA)
  )
  expect_equal(be_compute_pulse_pressure(c(120, NA), c(90, 80)), c(30, NA))
})

test_that("neuropsych derived helpers preserve legacy scoring rules", {
  expect_equal(
    be_sum_until_three_zeros(c("1", "1", "0", "0", "0", "1")),
    2
  )
  expect_equal(be_compute_tmt_b_minus_a(c("90", "50"), c("30", NA)), c(60, NA))
  expect_equal(
    be_compute_topf_total_corrected(c("Yes", "Yes", "No", "No", "No", "Yes")),
    2
  )
})

test_that("biomarker derived helpers guard divide-by-zero", {
  expect_equal(
    be_compute_ab42_40_ratio(c(20, 20, NA), c(10, 0, 2)),
    c(2, NA, NA)
  )
})

test_that("genomics derived helpers classify genotypes and status", {
  expect_equal(
    be_derive_aqp4_genotype("AG", "AC", "TG"),
    "heterozygous"
  )
  expect_equal(
    be_derive_aqp4_status(c("heterozygous", "mixed", NA)),
    c("carrier", "noncarrier", NA)
  )
  expect_equal(be_derive_apoe_genotype("CC", "TC"), "e3e4")
  expect_equal(
    be_derive_apoe_e4_status(c("e3e4", "e2e3", NA)),
    c("carrier", "noncarrier", NA)
  )
})

test_that("sleep derived helpers normalize and widen PSG values", {
  expect_equal(
    be_normalize_psg_rswa(c("yes", "no", "", NA)),
    c("Yes", "No", NA, NA)
  )
  expect_equal(
    be_normalize_psg_rswa(c("yes", "no"), cat_labels = "numbered"),
    c(1, 0)
  )
  expect_equal(
    be_normalize_psg_powerspec_id(c("BACH001_07082023", " bach002_01012024 ")),
    c("0001", "0002")
  )
  expect_equal(
    be_normalize_psg_powerspec_id(c("BACH0007_07082023", "0007_01012024")),
    c("0007", "0007")
  )
  expect_equal(
    be_normalize_psg_channel_name(c("C3_M2", "F4_M1")),
    c("C3M2", "F4M1")
  )

  widened <- be_widen_psg_powerspec_rows(
    data.frame(
      participant_id = c("001", "001"),
      B = c("DELTA", "ALPHA"),
      CH = c("C3M2", "C3M2"),
      stage = c("N2", "REM"),
      PSD = c(12.5, 4.2),
      RELPSD = c(0.42, 0.18),
      stringsAsFactors = FALSE
    )
  )
  expect_equal(widened$PSD_DELTA_C3M2_N2, 12.5)
  expect_equal(widened$RELPSD_ALPHA_C3M2_REM, 0.18)
})
