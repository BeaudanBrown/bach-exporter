be_clean_participant_id <- function(x) {
  cleaned <- trimws(as.character(x))
  cleaned <- gsub("^BACH", "", cleaned, ignore.case = TRUE)
  cleaned[nchar(cleaned) == 0] <- NA_character_
  cleaned
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
