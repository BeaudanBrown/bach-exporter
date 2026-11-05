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

be_read_redcap_snapshot <- function(
  shared_root,
  exclusions = be_read_exclusions(shared_root)
) {
  be_apply_exclusions(
    be_read_snapshot_csv(shared_root, "redcap", "raw.csv"),
    "redcap",
    exclusions
  )
}

be_read_redcap_labels_snapshot <- function(
  shared_root,
  exclusions = be_read_exclusions(shared_root)
) {
  labels_path <- be_snapshot_file_path(shared_root, "redcap", "labels.csv")
  if (!file.exists(labels_path)) {
    return(be_read_redcap_snapshot(shared_root, exclusions))
  }

  be_apply_exclusions(
    be_read_snapshot_csv(shared_root, "redcap", "labels.csv"),
    "redcap",
    exclusions
  )
}

be_read_psg_snapshot <- function(shared_root) {
  be_read_snapshot_csv(shared_root, "psg", "raw.csv")
}

be_read_biomarkers_snapshot <- function(
  shared_root,
  exclusions = be_read_exclusions(shared_root)
) {
  be_apply_exclusions(
    be_read_snapshot_csv(shared_root, "biomarkers", "raw.csv"),
    "biomarkers",
    exclusions
  )
}

# Configuration is read offline; absence explicitly means no exclusions.
be_read_exclusions <- function(shared_root) {
  path <- file.path(shared_root, "config", "exclusions.json")
  if (!file.exists(path)) {
    return(list())
  }
  config <- tryCatch(
    jsonlite::read_json(path, simplifyVector = FALSE),
    error = function(e) {
      stop("Invalid exclusions JSON: ", conditionMessage(e), call. = FALSE)
    }
  )
  be_validate_exclusions(config)
}

be_validate_exclusions <- function(config) {
  fail <- function(message) {
    stop("Invalid exclusions configuration: ", message, call. = FALSE)
  }
  text <- function(x) {
    is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x))
  }
  if (
    !is.list(config) ||
      !identical(names(config), "rules") ||
      !is.list(config$rules) ||
      !is.null(names(config$rules))
  ) {
    fail("expected an object containing a rules array.")
  }
  rules <- config$rules
  ids <- character()
  for (i in seq_along(rules)) {
    rule <- rules[[i]]
    required <- c("id", "participant_id", "source", "columns", "reason")
    if (
      !is.list(rule) ||
        anyDuplicated(names(rule)) ||
        !all(required %in% names(rule)) ||
        any(!names(rule) %in% c(required, "sampletype"))
    ) {
      fail(sprintf("rule %d has missing, duplicate, or unknown keys.", i))
    }
    if (
      !all(vapply(
        rule[c("id", "participant_id", "source", "reason")],
        text,
        logical(1)
      ))
    ) {
      fail(sprintf(
        "rule %d requires nonempty string identifiers, source, and reason.",
        i
      ))
    }
    if (!rule$source %in% c("redcap", "biomarkers")) {
      fail(sprintf("rule '%s' has an unsupported source.", rule$id))
    }
    if (
      !is.list(rule$columns) ||
        !is.null(names(rule$columns)) ||
        !length(rule$columns) ||
        !all(vapply(rule$columns, text, logical(1)))
    ) {
      fail(sprintf(
        "rule '%s' requires a nonempty array of source columns.",
        rule$id
      ))
    }
    rule$columns <- unlist(rule$columns, use.names = FALSE)
    if (anyDuplicated(rule$columns)) {
      fail("duplicate source columns.")
    }
    if (
      "sampletype" %in%
        names(rule) &&
        (!identical(rule$source, "biomarkers") ||
          !text(rule$sampletype) ||
          !rule$sampletype %in% c("csf", "plasma", "dbs"))
    ) {
      fail(sprintf("rule '%s' has an invalid sampletype restriction.", rule$id))
    }
    # Keys must remain intact so masking cannot change row identity or selection.
    protected <- c(
      "idno",
      "record_id",
      "participant_id",
      "study_id",
      "subject_id",
      "Sample ID",
      "Sample.ID",
      "sampletype",
      "Sample Type",
      "Sample.Type",
      "redcap_event_name",
      "redcap_repeat_instrument",
      "redcap_repeat_instance"
    )
    if (any(rule$columns %in% protected)) {
      fail("identifier and sample/event columns cannot be masked.")
    }
    ids <- c(ids, rule$id)
    rules[[i]] <- rule
  }
  if (anyDuplicated(ids)) {
    fail("rule IDs must be unique.")
  }
  rules
}

be_apply_exclusions <- function(df, source, rules) {
  audit <- list()
  for (rule in rules) {
    if (!identical(rule$source, source)) {
      next
    }
    missing <- setdiff(rule$columns, names(df))
    if (length(missing)) {
      stop(
        sprintf(
          "Exclusion '%s': unknown %s source columns: %s",
          rule$id,
          source,
          paste(missing, collapse = ", ")
        ),
        call. = FALSE
      )
    }
    id_column <- if (source == "redcap") {
      be_redcap_id_column(df)
    } else {
      be_biomarker_subject_column(df)
    }
    ids <- be_normalize_participant_merge_id(df[[id_column]])
    match_rows <- !is.na(ids) &
      ids == be_normalize_participant_merge_id(rule$participant_id)
    if (!is.null(rule$sampletype)) {
      types <- be_normalize_biomarker_sampletype(df[[be_biomarker_sampletype_column(
        df
      )]])
      match_rows <- match_rows & !is.na(types) & types == rule$sampletype
    }
    match_rows[is.na(match_rows)] <- FALSE
    if (!any(match_rows)) {
      next
    }
    count <- sum(vapply(
      df[match_rows, rule$columns, drop = FALSE],
      function(x) {
        sum(!is.na(x) & nzchar(trimws(as.character(x))))
      },
      integer(1)
    ))
    df[match_rows, rule$columns] <- NA
    audit[[length(audit) + 1L]] <- list(
      rule_id = rule$id,
      source = source,
      masked_values = count
    )
  }
  attr(df, "bach_exclusions_applied") <- audit
  df
}

be_exclusion_audit <- function(...) {
  unlist(
    lapply(list(...), function(df) {
      attr(df, "bach_exclusions_applied") %||% list()
    }),
    recursive = FALSE,
    use.names = FALSE
  )
}
