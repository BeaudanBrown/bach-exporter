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

be_build_prose_passages_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_prepare_redcap_snapshot(redcap_df)
  redcap_df <- be_filter_years(redcap_df, years)

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
    names(redcap_df)
  )
  if (!length(prose_fields)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  grouped_rows <- lapply(
    split(
      redcap_df,
      interaction(redcap_df$participant_id, redcap_df$year, drop = TRUE)
    ),
    function(df) {
      prose <- lapply(df[, prose_fields, drop = FALSE], be_first_nonempty)
      version <- prose$prose_passage %||% NA_character_

      data.frame(
        participant_id = df$participant_id[[1]],
        event_name = df$event_name[[1]],
        year = df$year[[1]],
        tele_prose_version = version,
        tele_prose_imm_time = prose$prose_time %||% NA,
        tele_prose_imm_story1 = prose$prose_s1_imm_story %||% NA,
        tele_prose_imm_theme1 = prose$prose_s1_imm_theme %||% NA,
        tele_prose_imm_story2 = prose$prose_s2_imm_story %||% NA,
        tele_prose_imm_theme2 = prose$prose_s2_imm_theme %||% NA,
        tele_prose_delay_time = prose$prose_del_time %||% NA,
        tele_prose_delay_mins = prose$prose_timediff %||% NA,
        tele_prose_delay_story1 = prose$prose_s1_del_story %||% NA,
        tele_prose_delay_theme1 = prose$prose_s1_del_theme %||% NA,
        tele_prose_delay_story2 = prose$prose_s2_del_story %||% NA,
        tele_prose_delay_theme2 = prose$prose_s2_del_theme %||% NA,
        tele_prose_imm_percorrect = be_prose_percent_correct(
          version = version,
          story1 = prose$prose_s1_imm_story %||% NA,
          story2 = prose$prose_s2_imm_story %||% NA
        ),
        tele_prose_del_percorrect = be_prose_percent_correct(
          version = version,
          story1 = prose$prose_s1_del_story %||% NA,
          story2 = prose$prose_s2_del_story %||% NA
        ),
        stringsAsFactors = FALSE
      )
    }
  )

  prose <- do.call(rbind, grouped_rows)
  rownames(prose) <- NULL
  prose <- be_drop_empty_columns(prose)
  unique(prose)
}
