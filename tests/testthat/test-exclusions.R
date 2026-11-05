source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "source_snapshots.R"))
source(file.path("..", "..", "R", "normalize_redcap.R"))
source(file.path("..", "..", "R", "domain_biomarkers.R"))

exclusion_test_rule <- function(...) {
  rule <- list(
    id = "csf-quality",
    participant_id = "59",
    source = "biomarkers",
    sampletype = "csf",
    columns = list("AB40_mean_conc", "AB42_mean_conc"),
    reason = "Synthetic quality exclusion"
  )
  overrides <- list(...)
  rule[names(overrides)] <- overrides
  rule
}

test_that("exclusions validate structure even for sources not loaded", {
  root <- tempfile()
  expect_identical(be_read_exclusions(root), list())
  expect_identical(be_validate_exclusions(list(rules = list())), list())
  rule <- exclusion_test_rule()
  for (bad in list(
    list(),
    list(rules = NULL),
    list(rules = list(rule, rule)),
    list(rules = list(exclusion_test_rule(source = "unknown"))),
    list(rules = list(exclusion_test_rule(columns = list("participant_id")))),
    list(rules = list(exclusion_test_rule(columns = "AB40_mean_conc"))),
    list(rules = list(exclusion_test_rule(sampletype = "unknown"))),
    list(rules = list(exclusion_test_rule(reason = ""))),
    list(rules = list(exclusion_test_rule(extra = TRUE)))
  )) {
    expect_error(be_validate_exclusions(bad), "Invalid exclusions")
  }
  dir.create(file.path(root, "config"), recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE))
  writeLines("not json", file.path(root, "config", "exclusions.json"))
  expect_error(be_read_exclusions(root), "Invalid exclusions JSON")
})

test_that("masking normalizes IDs, preserves rows and isolates sample types", {
  df <- data.frame(
    Sample.ID = c("59", "BACH0059", "sub-0059", "59", "60"),
    Sample.Type = c("CSF", " csf ", "CSF", "Plasma", "CSF"),
    AB40_mean_conc = c(100, 200, 300, 400, 500),
    AB42_mean_conc = c(10, 20, NA, 40, 50)
  )
  rules <- be_validate_exclusions(list(rules = list(exclusion_test_rule())))
  masked <- be_apply_exclusions(df, "biomarkers", rules)
  expect_equal(nrow(masked), nrow(df))
  expect_equal(masked$Sample.ID, df$Sample.ID)
  expect_true(all(is.na(masked[1:3, c("AB40_mean_conc", "AB42_mean_conc")])))
  expect_equal(masked$AB40_mean_conc[4:5], c(400, 500))
  expect_equal(
    be_exclusion_audit(masked),
    list(list(
      rule_id = "csf-quality",
      source = "biomarkers",
      masked_values = 5L
    ))
  )
  unmatched <- be_apply_exclusions(df[5, ], "biomarkers", rules)
  expect_identical(be_exclusion_audit(unmatched), list())
  expect_error(
    be_apply_exclusions(df[, -3], "biomarkers", rules),
    "unknown biomarkers source columns"
  )
  expect_silent(be_apply_exclusions(data.frame(idno = "59"), "redcap", rules))
})

test_that("all rules match original IDs and audit counts avoid double counting", {
  rules <- be_validate_exclusions(list(
    rules = list(
      exclusion_test_rule(),
      exclusion_test_rule(id = "overlap")
    )
  ))
  df <- data.frame(
    subject_id = "0059",
    sampletype = "csf",
    AB40_mean_conc = 100,
    AB42_mean_conc = 10
  )
  masked <- be_apply_exclusions(df, "biomarkers", rules)
  expect_equal(
    vapply(be_exclusion_audit(masked), function(x) x$masked_values, integer(1)),
    c(2L, 0L)
  )
})
