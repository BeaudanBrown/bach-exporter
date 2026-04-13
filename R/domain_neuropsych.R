be_build_cdr_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      neuropsych_date = "neuropsych_date",
      cdr_memory = "cdr_memory",
      cdr_orientation = "cdr_orient",
      cdr_judgement = "cdr_judgment",
      cdr_community = "cdr_community",
      cdr_hobbies = "cdr_hobbies",
      cdr_personal = "cdr_personal",
      cdr_sobscore = "cdr_sob",
      cdr_globalscore = "cdr_global"
    )
  )
}

be_build_mmse_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      neuropsych_date = "neuropsych_date",
      mmse_total = "mmse_tot",
      mmse_notes = "mmse_comment",
      mmse_notes_detail = "mmse_comment_y"
    )
  )
}

be_build_sydbat_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      sydbat_date = "sydbat_date",
      sydbat_naming = "sydbat_naming_total",
      sydbat_repeat = "sydbat_repetition_total",
      sydbat_comprehend = "sydbat_comprehension_total",
      sydbat_semantic = "sydbat_semantic_total"
    )
  )
}

be_build_logical_memory_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      logicalmem_imm_time = "lmi_time",
      logicalmem_imm_storyb = "lmi_b_total",
      logicalmem_imm_storyc = "lmi_c_total",
      logicalmem_imm_total = "lmi_total_raw",
      logicalmem_delay_time = "lmii_time",
      logicalmem_delay_mins = "lmii_timediff",
      logicalmem_delay_storyb_cue = "lmii_bcue",
      logicalmem_delay_storyb = "lmii_b_total",
      logicalmem_delay_storyc_cue = "lmii_ccue",
      logicalmem_delay_storyc = "lmii_c_total",
      logicalmem_delay_total = "lmii_total_raw"
    )
  )
}

be_build_visual_reproduction_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      visualrepro1_time = "vri_time",
      visualrepro1_total = "vri_total_raw",
      visualrepro2_time = "vrii_time",
      visualrepro2_mins = "vrii_timediff",
      visualrepro2_total = "vrii_total_raw"
    )
  )
}

be_build_tmt_domain <- function(redcap_df, years = NULL) {
  tmt <- be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      tmt_date = "tmt_date",
      tmt_a_time = "tmt_a_total_sec",
      tmt_a_error = "tmt_a_err",
      tmt_b_time = "tmt_b_total_sec",
      tmt_b_error = "tmt_b_err"
    )
  )

  if (!nrow(tmt)) {
    return(tmt)
  }

  if (all(c("tmt_a_time", "tmt_b_time") %in% names(tmt))) {
    tmt$tmtbminusa <- be_compute_tmt_b_minus_a(
      tmt$tmt_b_time,
      tmt$tmt_a_time
    )
  }

  tmt <- be_drop_empty_columns(tmt)
  rownames(tmt) <- NULL
  tmt
}

be_build_fab_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      fab_date = "fab_date",
      fab_similarities = "fab_similarities",
      fab_lexical = "fab_lexical_fluency",
      fab_motor = "fab_motor",
      fab_interference = "fab_conflicting_instrx",
      fab_inhib = "fab_go_nogo",
      fab_autonomy = "fab_prehension",
      fab_total = "fab_total"
    )
  )
}

be_build_cowat_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      cowat_date = "cowat_date",
      cowat_f_score = "cowat_f_total",
      cowat_a_score = "cowat_a_total",
      cowat_s_score = "cowat_s_total",
      cowat_total = "cowat_fas_total",
      cowat_animal = "cowat_animals_total"
    )
  )
}

be_build_hvot_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      hvot_date = "hvot_date",
      hvot_total = "hvot_total"
    )
  )
}

be_build_tasit_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      tasit_date = "tasit_date",
      tasit_sincere = "tasit_p2_sin",
      tasit_sarcastic = "tasit_p2_sar",
      tasit_total = "tasit_p2_total"
    )
  )
}

be_build_topf_domain <- function(redcap_df, years = NULL) {
  redcap_df <- be_redcap_domain_input(redcap_df, years)

  topf_fields <- paste0("topf", seq_len(70))
  available_topf_fields <- topf_fields[topf_fields %in% names(redcap_df)]
  available_sources <- intersect(
    c("topf_date", available_topf_fields),
    names(redcap_df)
  )

  if (!length(available_sources) || !nrow(redcap_df)) {
    return(data.frame(participant_id = character(), stringsAsFactors = FALSE))
  }

  grouped_rows <- lapply(
    split(
      redcap_df,
      interaction(
        redcap_df$participant_id,
        redcap_df$event_name,
        redcap_df$year,
        drop = TRUE
      )
    ),
    function(df) {
      topf <- data.frame(
        participant_id = df$participant_id[[1]],
        event_name = df$event_name[[1]],
        year = df$year[[1]],
        stringsAsFactors = FALSE
      )

      if ("topf_date" %in% names(df)) {
        topf$topf_date <- be_first_nonempty(df$topf_date)
      }

      if (length(available_topf_fields)) {
        topf$topf_total_corrected <- be_compute_topf_total_corrected(
          vapply(
            available_topf_fields,
            function(field) as.character(be_first_nonempty(df[[field]])),
            FUN.VALUE = character(1)
          )
        )
      }

      topf
    }
  )

  topf <- do.call(rbind, grouped_rows)
  rownames(topf) <- NULL
  topf <- be_drop_empty_columns(topf)
  unique(topf)
}

be_build_dementia_status_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      demreview_date = "ds_adju_date",
      demreview_status = "ds_status",
      demreview_onset = "ds_onset_date",
      demreview_intactdate = "ds_cog_int_date",
      demreview_notes = "ds_notes"
    )
  )
}
