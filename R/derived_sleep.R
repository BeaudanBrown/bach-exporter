be_normalize_psg_rswa <- function(x, cat_labels = c("named", "numbered")) {
  cat_labels <- match.arg(cat_labels)
  values <- trimws(as.character(x))
  values[!nzchar(values)] <- NA_character_

  if (cat_labels == "named") {
    return(ifelse(
      grepl("yes", values, ignore.case = TRUE),
      "Yes",
      ifelse(grepl("no", values, ignore.case = TRUE), "No", NA_character_)
    ))
  }

  ifelse(
    grepl("yes", values, ignore.case = TRUE),
    1,
    ifelse(grepl("no", values, ignore.case = TRUE), 0, NA_real_)
  )
}

be_normalize_psg_powerspec_id <- function(x) {
  values <- trimws(as.character(x))
  values[!nzchar(values)] <- NA_character_
  values <- gsub("_[0-9]{8}$", "", values)
  be_normalize_participant_merge_id(values)
}

be_normalize_psg_channel_name <- function(x) {
  values <- trimws(as.character(x))
  values[!nzchar(values)] <- NA_character_
  gsub("_", "", values, fixed = TRUE)
}

be_widen_psg_powerspec_rows <- function(df) {
  row <- list(participant_id = df$participant_id[[1]])

  for (i in seq_len(nrow(df))) {
    suffix <- paste(df$B[[i]], df$CH[[i]], df$stage[[i]], sep = "_")
    if ("PSD" %in% names(df)) {
      row[[paste("PSD", suffix, sep = "_")]] <- df$PSD[[i]]
    }
    if ("RELPSD" %in% names(df)) {
      row[[paste("RELPSD", suffix, sep = "_")]] <- df$RELPSD[[i]]
    }
  }

  as.data.frame(row, stringsAsFactors = FALSE)
}
