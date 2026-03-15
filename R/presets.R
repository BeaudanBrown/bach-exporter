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
    )
  )
}
