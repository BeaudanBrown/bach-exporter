be_domain_registry <- function() {
  data.frame(
    label = c(
      "Participants",
      "Participant Screening",
      "MRI Screening",
      "MRI",
      "LP Screening",
      "Lumbar Puncture",
      "MoCA",
      "AD8",
      "UCLA Loneliness",
      "Demographics",
      "CES-D",
      "STAI",
      "PSS",
      "CD-RISC",
      "DAS",
      "Informant DAS",
      "MFI",
      "SES",
      "ARIA",
      "IPAQ",
      "RHHI",
      "MIND Diet",
      "Alcohol Questionnaire",
      "CFI",
      "Global Health",
      "Biomarkers",
      "Genomics",
      "Bloods / Pathology",
      "Vitals",
      "24h Blood Pressure",
      "Medical History",
      "CDR",
      "MMSE",
      "SYDBAT",
      "Logical Memory",
      "Visual Reproduction",
      "Trail Making Test",
      "Frontal Assessment Battery",
      "COWAT",
      "HVOT",
      "TASIT",
      "TOPF",
      "Dementia Status",
      "PSQI",
      "ESS",
      "ISI",
      "PSG Screening",
      "PSG Sleep Health",
      "PSG Sleep Medications",
      "PSG Morning Questionnaire",
      "PSG Summary",
      "PSG Full",
      "PSG Power Spectral",
      "Actigraphy Full",
      "Actigraphy Summary",
      "Similarities",
      "Prose Passages",
      "Cognitive Screening",
      "Medications"
    ),
    id = c(
      "participants",
      "participant_screening",
      "mri_screening",
      "mri",
      "lp_screening",
      "lp",
      "moca",
      "ad8",
      "ucla",
      "demographics",
      "cesd",
      "stai",
      "pss",
      "cdrisc",
      "das",
      "informant_das",
      "mfi",
      "ses",
      "aria",
      "ipaq",
      "rhhi",
      "minddiet",
      "alcohol",
      "cfi",
      "global_health",
      "biomarkers",
      "genomics",
      "bloods",
      "vitals",
      "bp24h",
      "medical_history",
      "cdr",
      "mmse",
      "sydbat",
      "logical_memory",
      "visual_reproduction",
      "tmt",
      "fab",
      "cowat",
      "hvot",
      "tasit",
      "topf",
      "dementia_status",
      "psqi",
      "ess",
      "isi",
      "psg_screening",
      "psg_sleephealth",
      "psg_sleepmed",
      "psg_morningquest",
      "psg_summary",
      "psg_full",
      "psg_powerspec",
      "actigraphy_full",
      "actigraphy_summary",
      "similarities",
      "prose_passages",
      "cognitive_screening",
      "medications"
    ),
    group = c(
      "Required",
      "Surveys",
      "Imaging / LP",
      "Imaging / LP",
      "Imaging / LP",
      "Imaging / LP",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Surveys",
      "Genetics / Biomarkers",
      "Genetics / Biomarkers",
      "Clinical",
      "Clinical",
      "Clinical",
      "Clinical",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Sleep / PSG / Actigraphy",
      "Neuropsych",
      "Neuropsych",
      "Neuropsych",
      "Clinical"
    ),
    stringsAsFactors = FALSE
  )
}

be_domain_choices <- function() {
  registry <- be_domain_registry()
  stats::setNames(registry$id, registry$label)
}

be_domain_ids <- function() {
  be_domain_registry()$id
}

be_domain_group_slug <- function(group) {
  gsub("_+", "_", gsub("[^a-z0-9]+", "_", tolower(group)))
}

be_domain_group_input_id <- function(group) {
  paste0("domains_", be_domain_group_slug(group))
}

be_domain_group_toggle_input_id <- function(group) {
  paste0("domains_", be_domain_group_slug(group), "_all")
}

be_domain_group_choices <- function() {
  registry <- be_domain_registry()
  registry <- registry[registry$id != "participants", , drop = FALSE]
  groups <- split(registry, registry$group)
  group_order <- c(
    "Clinical",
    "Genetics / Biomarkers",
    "Surveys",
    "Neuropsych",
    "Imaging / LP",
    "Sleep / PSG / Actigraphy"
  )
  groups <- groups[intersect(group_order, names(groups))]
  lapply(groups, function(group_registry) {
    stats::setNames(group_registry$id, group_registry$label)
  })
}
