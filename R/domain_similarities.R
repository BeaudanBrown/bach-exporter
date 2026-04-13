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

be_build_similarities_domain <- function(
  redcap_df,
  years = NULL,
  participant_year_rows = NULL
) {
  participant_year_rows <- participant_year_rows %||%
    be_participant_year_rows_input(redcap_df, years)

  similarity_fields <- intersect(
    paste0("similarities", 1:18),
    names(participant_year_rows)
  )
  if (!length(similarity_fields)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  similarities <- participant_year_rows[,
    c("participant_id", "event_name", "year", "pp_date", similarity_fields),
    drop = FALSE
  ]
  names(similarities)[names(similarities) == "pp_date"] <- "tele_date"
  similarities$tele_similarities_corrected <- vapply(
    seq_len(nrow(similarities)),
    function(index) {
      be_similarity_score_until_three_zeros(
        similarities[index, similarity_fields, drop = TRUE]
      )
    },
    numeric(1)
  )
  similarities <- similarities[,
    c(
      "participant_id",
      "event_name",
      "year",
      "tele_date",
      "tele_similarities_corrected"
    ),
    drop = FALSE
  ]
  similarities <- be_drop_empty_columns(similarities)
  unique(similarities)
}
