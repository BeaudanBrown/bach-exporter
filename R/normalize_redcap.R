be_clean_participant_id <- function(x) {
  cleaned <- trimws(as.character(x))
  cleaned <- gsub("^BACH", "", cleaned, ignore.case = TRUE)
  cleaned <- gsub("(?:(?:--)|-)1$", "", cleaned, perl = TRUE)
  cleaned[nchar(cleaned) == 0] <- NA_character_
  cleaned
}

be_is_secondary_repeat_id <- function(x) {
  value <- trimws(as.character(x))
  grepl("(?:(?:--)|-)2$", value, perl = TRUE)
}

be_filter_supported_participants <- function(df, participant_id_column) {
  raw_ids <- df[[participant_id_column]]
  keep_rows <- !be_is_secondary_repeat_id(raw_ids)
  df <- df[keep_rows, , drop = FALSE]

  cleaned_ids <- be_clean_participant_id(df[[participant_id_column]])
  numeric_ids <- suppressWarnings(as.integer(cleaned_ids))
  supported_ids <- is.na(numeric_ids) | numeric_ids <= 300L
  df <- df[supported_ids, , drop = FALSE]
  df$participant_id <- cleaned_ids[supported_ids]

  if ("participated_assessment_complete" %in% names(df)) {
    completion <- trimws(as.character(df$participated_assessment_complete))
    incomplete <- completion %in% c("0", "Incomplete")
    df <- df[!incomplete, , drop = FALSE]
  }

  rownames(df) <- NULL
  df
}

be_prepare_redcap_snapshot <- function(df) {
  participant_id_column <- be_redcap_id_column(df)
  df <- be_filter_supported_participants(df, participant_id_column)
  be_split_redcap_events(df)
}

be_coalesce_columns <- function(df, fields) {
  out <- rep(NA_character_, nrow(df))

  for (field in fields) {
    if (!field %in% names(df)) {
      next
    }

    values <- df[[field]]
    if (is.factor(values)) {
      values <- as.character(values)
    }
    values <- trimws(as.character(values))
    values[!nzchar(values)] <- NA_character_

    fill <- is.na(out) & !is.na(values)
    out[fill] <- values[fill]
  }

  out
}

be_coalesce_vectors <- function(left, right) {
  if (is.null(left)) {
    return(right)
  }
  if (is.null(right)) {
    return(left)
  }

  out <- left
  fill <- is.na(out) & !is.na(right)
  out[fill] <- right[fill]
  out
}

be_drop_empty_columns <- function(df) {
  keep <- vapply(
    df,
    function(column) {
      values <- column
      if (is.factor(values)) {
        values <- as.character(values)
      }
      if (is.character(values)) {
        values <- trimws(values)
      }

      !all(is.na(values) | values == "")
    },
    logical(1)
  )

  df[, keep, drop = FALSE]
}

be_redcap_id_column <- function(df) {
  candidates <- c("idno", "record_id", "participant_id", "study_id")
  match <- candidates[candidates %in% names(df)]
  if (!length(match)) {
    stop(
      "REDCap snapshot is missing a participant identifier column. Expected one of: idno, record_id, participant_id, study_id.",
      call. = FALSE
    )
  }

  match[[1]]
}
