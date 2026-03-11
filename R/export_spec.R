be_default_export_spec <- function(shared_root = NULL) {
  release_id <- if (!is.null(shared_root)) {
    be_read_release_id(shared_root)
  } else {
    NULL
  }
  list(
    shared = list(root = shared_root, release_id = release_id),
    source = list(
      mode = "snapshot",
      redcap_url = getOption(
        "bachExporter.placeholder_redcap_url",
        "https://redcap.example.org/api/"
      ),
      api_key = getOption(
        "bachExporter.placeholder_redcap_api_key",
        "REPLACE_WITH_ADMIN_TOKEN"
      )
    ),
    cohort = list(
      years = c("baseline"),
      subset_file = NULL,
      participant_ids = NULL
    ),
    domains = c("participants"),
    options = list(cat_labels = "named"),
    output = list(format = "csv", path = "")
  )
}
