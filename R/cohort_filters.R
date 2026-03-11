be_parse_participant_ids <- function(x) {
  if (is.null(x) || !length(x)) {
    return(NULL)
  }

  if (length(x) == 1 && is.character(x)) {
    x <- unlist(strsplit(x, "[,\r\n\t ]+"))
  }

  ids <- be_clean_participant_id(x)
  ids <- ids[!is.na(ids)]
  ids <- unique(ids)
  if (!length(ids)) {
    return(NULL)
  }

  ids
}

be_read_subset_file_ids <- function(path) {
  if (is.null(path) || !nzchar(path)) {
    return(NULL)
  }
  if (!file.exists(path)) {
    stop(sprintf("Subset file does not exist: %s", path), call. = FALSE)
  }

  lines <- readLines(path, warn = FALSE)
  be_parse_participant_ids(lines)
}

be_resolve_cohort_ids <- function(spec) {
  ids_from_spec <- be_parse_participant_ids(
    spec$cohort$participant_ids %||% NULL
  )
  ids_from_file <- be_read_subset_file_ids(spec$cohort$subset_file %||% NULL)

  ids <- unique(c(ids_from_spec, ids_from_file))
  if (!length(ids)) {
    return(NULL)
  }

  ids
}

be_filter_participants <- function(df, participant_ids = NULL) {
  if (is.null(participant_ids) || !length(participant_ids)) {
    return(df)
  }

  if (!"participant_id" %in% names(df)) {
    stop(
      "Cannot filter participants: participant_id column is missing.",
      call. = FALSE
    )
  }

  df[df$participant_id %in% participant_ids, , drop = FALSE]
}
