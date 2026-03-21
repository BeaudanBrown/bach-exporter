be_snapshot_family_dir <- function(shared_root, family) {
  file.path(shared_root, "snapshots", family)
}

be_snapshot_file_path <- function(shared_root, family, filename) {
  file.path(be_snapshot_family_dir(shared_root, family), filename)
}

be_snapshot_paths <- function(shared_root) {
  list(
    redcap_raw = be_snapshot_file_path(shared_root, "redcap", "raw.csv"),
    redcap_labels = be_snapshot_file_path(shared_root, "redcap", "labels.csv"),
    redcap_metadata = be_snapshot_file_path(
      shared_root,
      "redcap",
      "metadata.json"
    ),
    psg_raw = be_snapshot_file_path(shared_root, "psg", "raw.csv"),
    psg_metadata = be_snapshot_file_path(shared_root, "psg", "metadata.json"),
    biomarkers_raw = be_snapshot_file_path(
      shared_root,
      "biomarkers",
      "raw.csv"
    ),
    biomarkers_metadata = be_snapshot_file_path(
      shared_root,
      "biomarkers",
      "metadata.json"
    ),
    snapshot_index = be_snapshot_file_path(
      shared_root,
      "sidecars",
      "snapshot-index.json"
    )
  )
}

be_assert_snapshot_file <- function(path, label) {
  if (!file.exists(path)) {
    stop(sprintf("%s is missing: %s", label, path), call. = FALSE)
  }

  invisible(path)
}

be_read_snapshot_csv <- function(shared_root, family, filename = "raw.csv") {
  path <- be_snapshot_file_path(shared_root, family, filename)
  be_assert_snapshot_file(
    path,
    sprintf("Snapshot file for '%s/%s'", family, filename)
  )

  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

be_read_snapshot_metadata <- function(shared_root, family) {
  path <- be_snapshot_file_path(shared_root, family, "metadata.json")
  be_assert_snapshot_file(
    path,
    sprintf("Snapshot metadata for '%s'", family)
  )

  jsonlite::read_json(path, simplifyVector = TRUE)
}

be_read_snapshot_index <- function(shared_root) {
  path <- be_snapshot_file_path(shared_root, "sidecars", "snapshot-index.json")
  be_assert_snapshot_file(path, "Snapshot index")

  jsonlite::read_json(path, simplifyVector = TRUE)
}

be_collect_snapshot_metadata <- function(shared_root) {
  snapshot_index <- tryCatch(
    be_read_snapshot_index(shared_root),
    error = function(err) list(error = conditionMessage(err))
  )

  families <- c("redcap")
  if (is.null(snapshot_index$error)) {
    if (!is.null(snapshot_index$families)) {
      families <- union(families, as.character(snapshot_index$families))
    }
    if (!is.null(snapshot_index$snapshots)) {
      families <- union(families, names(snapshot_index$snapshots))
    }
  }

  metadata <- list(snapshot_index = snapshot_index)
  for (family in families) {
    metadata[[family]] <- tryCatch(
      be_read_snapshot_metadata(shared_root, family),
      error = function(err) list(error = conditionMessage(err))
    )
  }

  metadata
}

be_read_redcap_snapshot <- function(shared_root) {
  be_read_snapshot_csv(shared_root, "redcap", "raw.csv")
}

be_read_redcap_labels_snapshot <- function(shared_root) {
  be_read_snapshot_csv(shared_root, "redcap", "labels.csv")
}

be_read_psg_snapshot <- function(shared_root) {
  be_read_snapshot_csv(shared_root, "psg", "raw.csv")
}

be_read_biomarkers_snapshot <- function(shared_root) {
  be_read_snapshot_csv(shared_root, "biomarkers", "raw.csv")
}
