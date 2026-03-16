be_default_presets <- function() {
  list(
    baseline_core = list(
      label = "Baseline Core",
      years = c("baseline"),
      domains = c("participants", "participant_screening")
    ),
    annual_phone = list(
      label = "Annual Phone",
      years = c("baseline", "year2", "year3"),
      domains = c(
        "participants",
        "moca",
        "ad8",
        "ucla",
        "similarities",
        "prose_passages",
        "cognitive_screening"
      )
    ),
    clinical_medications = list(
      label = "Clinical Medications",
      years = c("baseline", "year2", "year3"),
      domains = c(
        "participants",
        "medications"
      )
    ),
    baseline_surveys = list(
      label = "Baseline Surveys",
      years = c("baseline"),
      domains = c(
        "participants",
        "demographics",
        "cesd",
        "stai",
        "pss",
        "cdrisc",
        "ses",
        "aria",
        "ipaq",
        "rhhi",
        "minddiet",
        "alcohol",
        "cfi",
        "global_health"
      )
    ),
    baseline_clinical = list(
      label = "Baseline Clinical",
      years = c("baseline"),
      domains = c(
        "participants",
        "bloods",
        "vitals",
        "bp24h",
        "medications"
      )
    ),
    medical_history = list(
      label = "Medical History",
      years = c("baseline", "year2", "year3"),
      domains = c(
        "participants",
        "medical_history"
      )
    )
  )
}
