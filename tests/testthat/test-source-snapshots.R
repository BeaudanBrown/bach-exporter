source(file.path("..", "..", "R", "source_snapshots.R"))

make_shared_root_with_snapshots <- function() {
  shared_root <- tempfile("shared-root-")
  dir.create(file.path(shared_root, "snapshots", "redcap"), recursive = TRUE)
  dir.create(file.path(shared_root, "snapshots", "psg"), recursive = TRUE)
  dir.create(
    file.path(shared_root, "snapshots", "biomarkers"),
    recursive = TRUE
  )
  dir.create(file.path(shared_root, "snapshots", "sidecars"), recursive = TRUE)
  shared_root
}

test_that("snapshot paths follow the shared-drive layout", {
  shared_root <- make_shared_root_with_snapshots()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  paths <- be_snapshot_paths(shared_root)

  expect_equal(
    paths$redcap_raw,
    file.path(shared_root, "snapshots", "redcap", "raw.csv")
  )
  expect_equal(
    paths$snapshot_index,
    file.path(shared_root, "snapshots", "sidecars", "snapshot-index.json")
  )
})

test_that("snapshot readers load csv and metadata files", {
  shared_root <- make_shared_root_with_snapshots()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  utils::write.csv(
    data.frame(record_id = c(1, 2), age = c(50, 51)),
    file.path(shared_root, "snapshots", "redcap", "raw.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(field_name = "age", label = "Age"),
    file.path(shared_root, "snapshots", "redcap", "labels.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(participant_id = "p1", ahi = 4.2),
    file.path(shared_root, "snapshots", "psg", "raw.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(participant_id = "p1", crp = 1.8),
    file.path(shared_root, "snapshots", "biomarkers", "raw.csv"),
    row.names = FALSE
  )
  jsonlite::write_json(
    list(refreshed_at = "2026-03-11T00:00:00Z", source = "redcap"),
    file.path(shared_root, "snapshots", "redcap", "metadata.json"),
    auto_unbox = TRUE
  )
  jsonlite::write_json(
    list(refreshed_at = "2026-03-11T00:00:00Z", source = "psg"),
    file.path(shared_root, "snapshots", "psg", "metadata.json"),
    auto_unbox = TRUE
  )
  jsonlite::write_json(
    list(refreshed_at = "2026-03-11T00:00:00Z", source = "biomarkers"),
    file.path(shared_root, "snapshots", "biomarkers", "metadata.json"),
    auto_unbox = TRUE
  )
  jsonlite::write_json(
    list(families = c("redcap", "psg", "biomarkers")),
    file.path(shared_root, "snapshots", "sidecars", "snapshot-index.json"),
    auto_unbox = TRUE
  )

  redcap <- be_read_redcap_snapshot(shared_root)
  labels <- be_read_redcap_labels_snapshot(shared_root)
  psg <- be_read_psg_snapshot(shared_root)
  biomarkers <- be_read_biomarkers_snapshot(shared_root)
  redcap_metadata <- be_read_snapshot_metadata(shared_root, "redcap")
  snapshot_index <- be_read_snapshot_index(shared_root)

  expect_equal(names(redcap), c("record_id", "age"))
  expect_equal(labels$label[[1]], "Age")
  expect_equal(psg$ahi[[1]], 4.2)
  expect_equal(biomarkers$crp[[1]], 1.8)
  expect_equal(redcap_metadata$source, "redcap")
  expect_equal(snapshot_index$families, c("redcap", "psg", "biomarkers"))
})

test_that("snapshot readers fail clearly when files are missing", {
  shared_root <- make_shared_root_with_snapshots()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  expect_error(
    be_read_redcap_snapshot(shared_root),
    "Snapshot file for 'redcap/raw.csv' is missing"
  )
  expect_error(
    be_read_snapshot_metadata(shared_root, "psg"),
    "Snapshot metadata for 'psg' is missing"
  )
  expect_error(
    be_read_snapshot_index(shared_root),
    "Snapshot index is missing"
  )
})
