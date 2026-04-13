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

be_read_snapshot_index_safe <- function(shared_root) {
  tryCatch(
    be_read_snapshot_index(shared_root),
    error = function(err) list(error = conditionMessage(err))
  )
}

be_read_snapshot_metadata_safe <- function(shared_root, family) {
  tryCatch(
    be_read_snapshot_metadata(shared_root, family),
    error = function(err) list(error = conditionMessage(err))
  )
}

be_read_snapshot_index <- function(shared_root) {
  path <- be_snapshot_file_path(shared_root, "sidecars", "snapshot-index.json")
  be_assert_snapshot_file(path, "Snapshot index")

  jsonlite::read_json(path, simplifyVector = TRUE)
}

be_collect_snapshot_metadata_families <- function(snapshot_index) {
  families <- c("redcap")
  if (is.null(snapshot_index$error)) {
    if (!is.null(snapshot_index$families)) {
      families <- union(families, as.character(snapshot_index$families))
    }
    if (!is.null(snapshot_index$snapshots)) {
      families <- union(families, names(snapshot_index$snapshots))
    }
  }

  families
}

be_collect_snapshot_metadata <- function(shared_root) {
  be_build_snapshot_metadata(
    snapshot_index = be_read_snapshot_index_safe(shared_root),
    redcap_metadata = be_read_snapshot_metadata_safe(shared_root, "redcap"),
    psg_metadata = be_read_snapshot_metadata_safe(shared_root, "psg"),
    biomarkers_metadata = be_read_snapshot_metadata_safe(
      shared_root,
      "biomarkers"
    )
  )
}

be_build_snapshot_metadata <- function(
  snapshot_index,
  redcap_metadata = NULL,
  psg_metadata = NULL,
  biomarkers_metadata = NULL
) {
  families <- be_collect_snapshot_metadata_families(snapshot_index)
  metadata <- list(snapshot_index = snapshot_index)

  for (family in families) {
    metadata[[family]] <- switch(
      family,
      redcap = redcap_metadata,
      psg = psg_metadata,
      biomarkers = biomarkers_metadata,
      list(
        error = sprintf(
          "Missing cached metadata target for snapshot family '%s'.",
          family
        )
      )
    )
  }

  metadata
}

be_read_redcap_snapshot <- function(shared_root) {
  be_read_snapshot_csv(shared_root, "redcap", "raw.csv")
}

be_read_redcap_labels_snapshot <- function(shared_root) {
  labels_path <- be_snapshot_file_path(shared_root, "redcap", "labels.csv")
  if (!file.exists(labels_path)) {
    return(be_read_redcap_snapshot(shared_root))
  }

  be_read_snapshot_csv(shared_root, "redcap", "labels.csv")
}

be_read_psg_snapshot <- function(shared_root) {
  be_read_snapshot_csv(shared_root, "psg", "raw.csv")
}

be_read_biomarkers_snapshot <- function(shared_root) {
  be_read_snapshot_csv(shared_root, "biomarkers", "raw.csv")
}
