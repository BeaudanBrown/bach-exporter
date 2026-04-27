be_build_das_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      das_date = "sdas_completion",
      das_1 = "sdas_1",
      das_2 = "sdas_2",
      das_3 = "sdas_3",
      das_4 = "sdas_4",
      das_5 = "sdas_5",
      das_6 = "sdas_6",
      das_7 = "sdas_7",
      das_8 = "sdas_8",
      das_9 = "sdas_9",
      das_10 = "sdas_10",
      das_11 = "sdas_11",
      das_12 = "sdas_12",
      das_13 = "sdas_13",
      das_14 = "sdas_14",
      das_15 = "sdas_15",
      das_16 = "sdas_16",
      das_17 = "sdas_17",
      das_18 = "sdas_18",
      das_19 = "sdas_19",
      das_20 = "sdas_20",
      das_21 = "sdas_21",
      das_22 = "sdas_22",
      das_23 = "sdas_23",
      das_24 = "sdas_24",
      das_total = "sdas_total",
      das_executive_score = "sdas_executive_score",
      das_emotional_score = "sdas_emotional_score",
      das_cognitive_score = "sdas_cognitive_score"
    )
  )
}

be_build_informant_das_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      informant_das_date = "i_das_date",
      informant_das_1 = "i_das_1",
      informant_das_2 = "i_das_2",
      informant_das_3 = "i_das_3",
      informant_das_4 = "i_das_4",
      informant_das_5 = "i_das_5",
      informant_das_6 = "i_das_6",
      informant_das_7 = "i_das_7",
      informant_das_8 = "i_das_8",
      informant_das_9 = "i_das_9",
      informant_das_10 = "i_das_10",
      informant_das_11 = "i_das_11",
      informant_das_12 = "i_das_12",
      informant_das_13 = "i_das_13",
      informant_das_14 = "i_das_14",
      informant_das_15 = "i_das_15",
      informant_das_16 = "i_das_16",
      informant_das_17 = "i_das_17",
      informant_das_18 = "i_das_18",
      informant_das_19 = "i_das_19",
      informant_das_20 = "i_das_20",
      informant_das_21 = "i_das_21",
      informant_das_22 = "i_das_22",
      informant_das_23 = "i_das_23",
      informant_das_24 = "i_das_24",
      informant_das_total = "i_das_total",
      informant_das_executive_score = "i_das_executive_score",
      informant_das_emotional_score = "i_das_emotional_score",
      informant_das_behaviour_score = "i_das_behaviour_score"
    )
  )
}

be_build_mfi_domain <- function(redcap_df, years = NULL) {
  be_build_event_field_domain(
    redcap_df = redcap_df,
    years = years,
    field_map = c(
      mfi_date = "mfi_date",
      mfi_1 = "mfi_1",
      mfi_2 = "mfi_2",
      mfi_3 = "mfi_3",
      mfi_4 = "mfi_4",
      mfi_5 = "mfi_5",
      mfi_6 = "mfi_6",
      mfi_7 = "mfi_7",
      mfi_8 = "mfi_8",
      mfi_9 = "mfi_9",
      mfi_10 = "mfi_10",
      mfi_11 = "mfi_11",
      mfi_12 = "mfi_12",
      mfi_13 = "mfi_13",
      mfi_14 = "mfi_14",
      mfi_15 = "mfi_15",
      mfi_16 = "mfi_16",
      mfi_17 = "mfi_17",
      mfi_18 = "mfi_18",
      mfi_19 = "mfi_19",
      mfi_20 = "mfi_20",
      mfi_total = "mfi_total",
      mfi_general_fatigue_score = "mfi_general_fatigue_score",
      mfi_phys_fatigue_score = "mfi_phys_fatigue_score",
      mfi_reduced_act_score = "mfi_reduced_act_score",
      mfi_reduced_motiv_score = "mfi_reduced_motiv_score",
      mfi_mental_fatigue_score = "mfi_mental_fatigue_score"
    )
  )
}
