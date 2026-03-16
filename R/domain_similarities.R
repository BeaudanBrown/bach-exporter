be_similarity_score_until_three_zeros <- function(row) {
  values <- suppressWarnings(as.numeric(row))
  if (all(is.na(values))) {
    return(NA_real_)
  }

  values[is.na(values)] <- 0
  zero_run <- 0L

  for (idx in seq_along(values)) {
    if (identical(values[[idx]], 0)) {
      zero_run <- zero_run + 1L
    } else {
      zero_run <- 0L
    }

    if (zero_run >= 3L) {
      return(sum(values[seq_len(idx)], na.rm = TRUE))
    }
  }

  sum(values, na.rm = TRUE)
}

be_build_similarities_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

  similarity_fields <- intersect(
    paste0("similarities", 1:18),
    names(redcap_df)
  )
  if (!length(similarity_fields)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  grouped_rows <- lapply(
    split(
      redcap_df,
      interaction(redcap_df$participant_id, redcap_df$year, drop = TRUE)
    ),
    function(df) {
      similarity_row <- unlist(
        lapply(
          similarity_fields,
          function(field) be_first_nonempty(df[[field]])
        ),
        use.names = FALSE
      )
      tele_date <- if ("pp_date" %in% names(df)) {
        be_first_nonempty(df$pp_date)
      } else {
        NA_character_
      }

      data.frame(
        participant_id = df$participant_id[[1]],
        event_name = df$event_name[[1]],
        year = df$year[[1]],
        tele_date = tele_date,
        tele_similarities_corrected = be_similarity_score_until_three_zeros(
          similarity_row
        ),
        stringsAsFactors = FALSE
      )
    }
  )

  similarities <- do.call(rbind, grouped_rows)
  rownames(similarities) <- NULL
  similarities <- be_drop_empty_columns(similarities)
  unique(similarities)
}
