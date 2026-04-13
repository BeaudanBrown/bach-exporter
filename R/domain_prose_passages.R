be_prose_story_denominator <- function(version) {
  normalized <- trimws(tolower(as.character(version %||% NA_character_)))

  if (identical(normalized, "passage a")) {
    return(51)
  }
  if (identical(normalized, "passage b")) {
    return(50)
  }

  NA_real_
}

be_prose_percent_correct <- function(version, story1, story2) {
  denominator <- be_prose_story_denominator(version)
  values <- suppressWarnings(as.numeric(c(story1, story2)))

  if (is.na(denominator) || any(is.na(values))) {
    return(NA_real_)
  }

  sum(values) / denominator
}

be_build_prose_passages_domain <- function(
  redcap_df,
  years = NULL,
  participant_year_rows = NULL
) {
  participant_year_rows <- participant_year_rows %||%
    be_participant_year_rows_input(redcap_df, years)

  prose_fields <- intersect(
    c(
      "prose_passage",
      "prose_time",
      "prose_s1_imm_story",
      "prose_s1_imm_theme",
      "prose_s2_imm_story",
      "prose_s2_imm_theme",
      "prose_del_time",
      "prose_timediff",
      "prose_s1_del_story",
      "prose_s1_del_theme",
      "prose_s2_del_story",
      "prose_s2_del_theme"
    ),
    names(participant_year_rows)
  )
  if (!length(prose_fields)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  prose <- participant_year_rows[,
    c("participant_id", "event_name", "year", prose_fields),
    drop = FALSE
  ]
  names(prose)[names(prose) == "prose_passage"] <- "tele_prose_version"
  names(prose)[names(prose) == "prose_time"] <- "tele_prose_imm_time"
  names(prose)[names(prose) == "prose_s1_imm_story"] <- "tele_prose_imm_story1"
  names(prose)[names(prose) == "prose_s1_imm_theme"] <- "tele_prose_imm_theme1"
  names(prose)[names(prose) == "prose_s2_imm_story"] <- "tele_prose_imm_story2"
  names(prose)[names(prose) == "prose_s2_imm_theme"] <- "tele_prose_imm_theme2"
  names(prose)[names(prose) == "prose_del_time"] <- "tele_prose_delay_time"
  names(prose)[names(prose) == "prose_timediff"] <- "tele_prose_delay_mins"
  names(prose)[
    names(prose) == "prose_s1_del_story"
  ] <- "tele_prose_delay_story1"
  names(prose)[
    names(prose) == "prose_s1_del_theme"
  ] <- "tele_prose_delay_theme1"
  names(prose)[
    names(prose) == "prose_s2_del_story"
  ] <- "tele_prose_delay_story2"
  names(prose)[
    names(prose) == "prose_s2_del_theme"
  ] <- "tele_prose_delay_theme2"
  prose$tele_prose_imm_percorrect <- vapply(
    seq_len(nrow(prose)),
    function(index) {
      be_prose_percent_correct(
        version = prose$tele_prose_version[[index]] %||% NA,
        story1 = prose$tele_prose_imm_story1[[index]] %||% NA,
        story2 = prose$tele_prose_imm_story2[[index]] %||% NA
      )
    },
    numeric(1)
  )
  prose$tele_prose_del_percorrect <- vapply(
    seq_len(nrow(prose)),
    function(index) {
      be_prose_percent_correct(
        version = prose$tele_prose_version[[index]] %||% NA,
        story1 = prose$tele_prose_delay_story1[[index]] %||% NA,
        story2 = prose$tele_prose_delay_story2[[index]] %||% NA
      )
    },
    numeric(1)
  )
  prose <- be_drop_empty_columns(prose)
  unique(prose)
}
