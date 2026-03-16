be_side_data_dir <- function(shared_root) {
  be_shared_paths(shared_root)$side_data_dir %||% ""
}

be_side_data_file_path <- function(shared_root, filename) {
  file.path(be_side_data_dir(shared_root), filename)
}

be_assert_side_data_file <- function(shared_root, filename, label = filename) {
  path <- be_side_data_file_path(shared_root, filename)
  if (!file.exists(path)) {
    stop(
      sprintf(
        "%s is missing from shared side-data: %s",
        label,
        path
      ),
      call. = FALSE
    )
  }

  invisible(path)
}

be_read_side_data_csv <- function(shared_root, filename, col_classes = NULL) {
  path <- be_assert_side_data_file(shared_root, filename)
  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    colClasses = col_classes
  )
}

be_normalize_postcode <- function(x) {
  values <- trimws(as.character(x))
  values[!nzchar(values)] <- NA_character_
  values
}
