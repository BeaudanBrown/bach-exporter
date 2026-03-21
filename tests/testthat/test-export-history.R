source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "export_history.R"))
source(file.path("..", "..", "R", "source_snapshots.R"))

test_that("export history helpers append and read structured records", {
  data_dir <- tempfile("bach-data-")
  old_data_option <- getOption("bachExporter.local_data_dir")
  options(bachExporter.local_data_dir = data_dir)
  on.exit(options(bachExporter.local_data_dir = old_data_option), add = TRUE)

  manifest <- list(
    build_id = "build-1",
    domains = c("participants", "bloods"),
    cohort = list(years = c("baseline", "year2"), participant_ids = "001"),
    execution_mode = "targets",
    refresh_mode = "auto",
    run = list(run_id = "run-1")
  )

  record <- be_build_export_history_record(
    manifest = manifest,
    output_path = "/tmp/export.csv",
    manifest_path = "/tmp/export.csv.manifest.json",
    log_path = "/tmp/export.log",
    status = "success",
    started_at = "2026-03-21T08:00:00Z",
    completed_at = "2026-03-21T08:00:05Z",
    row_count = 12L
  )
  be_append_export_history_record(record)

  history <- be_read_export_history()

  expect_equal(history$run_id[[1]], "run-1")
  expect_equal(history$status[[1]], "success")
  expect_equal(history$row_count[[1]], 12L)
  expect_equal(history$domains[[1]], "participants, bloods")
})

test_that("snapshot metadata collection includes indexed families and errors", {
  shared_root <- tempfile("shared-root-")
  dir.create(file.path(shared_root, "snapshots", "redcap"), recursive = TRUE)
  dir.create(
    file.path(shared_root, "snapshots", "biomarkers"),
    recursive = TRUE
  )
  dir.create(file.path(shared_root, "snapshots", "sidecars"), recursive = TRUE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  jsonlite::write_json(
    list(refreshed_at = "2026-03-11T00:00:00Z", source = "redcap"),
    file.path(shared_root, "snapshots", "redcap", "metadata.json"),
    auto_unbox = TRUE
  )
  jsonlite::write_json(
    list(families = c("redcap", "biomarkers", "psg")),
    file.path(shared_root, "snapshots", "sidecars", "snapshot-index.json"),
    auto_unbox = TRUE
  )

  metadata <- be_collect_snapshot_metadata(shared_root)

  expect_equal(metadata$redcap$source, "redcap")
  expect_match(
    metadata$biomarkers$error,
    "Snapshot metadata for 'biomarkers' is missing"
  )
  expect_match(metadata$psg$error, "Snapshot metadata for 'psg' is missing")
  expect_equal(
    metadata$snapshot_index$families,
    c("redcap", "biomarkers", "psg")
  )
})
