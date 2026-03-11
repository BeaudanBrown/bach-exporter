be_default_presets <- function() {
  list(
    baseline_core = list(
      label = "Baseline Core",
      years = c("baseline"),
      domains = c("participants")
    ),
    annual_phone = list(
      label = "Annual Phone",
      years = c("baseline", "year2", "year3"),
      domains = c("participants", "annual_phone")
    )
  )
}
