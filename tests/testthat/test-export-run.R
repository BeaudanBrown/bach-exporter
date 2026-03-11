source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "config.R"))
source(file.path("..", "..", "R", "source_snapshots.R"))
source(file.path("..", "..", "R", "normalize_redcap.R"))
source(file.path("..", "..", "R", "cohort_filters.R"))
source(file.path("..", "..", "R", "split_events.R"))
source(file.path("..", "..", "R", "domain_participants.R"))
source(file.path("..", "..", "R", "assemble_export.R"))
source(file.path("..", "..", "R", "export_spec.R"))
source(file.path("..", "..", "R", "export_validate.R"))
source(file.path("..", "..", "R", "export_run.R"))

make_export_shared_root <- function() {
  shared_root <- tempfile("shared-root-")
  dir.create(file.path(shared_root, "scripts"), recursive = TRUE)
  dir.create(file.path(shared_root, "R"), recursive = TRUE)
  dir.create(file.path(shared_root, "snapshots", "redcap"), recursive = TRUE)
  dir.create(file.path(shared_root, "snapshots", "sidecars"), recursive = TRUE)

  writeLines("dev", file.path(shared_root, "CURRENT_RELEASE.txt"))
  dir.create(
    file.path(shared_root, "releases", "dev", "scripts"),
    recursive = TRUE
  )
  writeLines(
    c("Package: bachExporter", "Version: 0.0.1"),
    file.path(shared_root, "releases", "dev", "DESCRIPTION")
  )
  file.create(file.path(
    shared_root,
    "releases",
    "dev",
    "scripts",
    "launch_from_share.R"
  ))

  utils::write.csv(
    data.frame(
      idno = c("BACH001", "BACH002", "BACH002"),
      redcap_event_name = c("Baseline", "Year 2", "Year 2"),
      participated = c("Yes", "Yes", "Yes"),
      age = c(70, 71, 71),
      sex = c("F", "M", "M"),
      education = c("College", "TAFE", "TAFE"),
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
    idno = c("BACH001", "  BACH002  "),
    redcap_event_name = c("Baseline", "Year 2"),
    age = c(70, 71),
    sex = c("F", "M"),
    education = c("College", "TAFE"),
    stringsAsFactors = FALSE
  )

  result <- be_build_participants_domain(
    redcap_df,
    years = c("baseline", "year2")
  )

  expect_equal(result$participant_id, c("001", "002"))
  expect_equal(result$year, c("baseline", "year2"))
  expect_true(all(c("age", "sex", "education") %in% names(result)))
})

test_that("run_export writes a snapshot-backed participants csv and manifest", {
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
    colClasses = c(participant_id = "character")
  )
  manifest <- jsonlite::read_json(result$manifest, simplifyVector = TRUE)

  expect_equal(export_df$participant_id, "002")
  expect_equal(export_df$year, "year2")
  expect_equal(manifest$domains, "participants")
  expect_equal(manifest$snapshot_metadata$redcap$source, "redcap")
  expect_equal(manifest$source$api_key, "[masked]")
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
