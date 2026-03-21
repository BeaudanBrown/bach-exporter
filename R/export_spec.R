be_default_export_spec <- function(shared_root = NULL) {
  build_id <- if (!is.null(shared_root)) {
    be_read_build_id(shared_root)
  } else {
    NULL
  }
  list(
    shared = list(root = shared_root, build_id = build_id),
    source = list(mode = "snapshot"),
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
