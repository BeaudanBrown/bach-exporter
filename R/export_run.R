run_export <- function(
  spec,
  output_path = NULL,
  shared_root = NULL,
  refresh_mode = "auto"
) {
  if (!is.null(shared_root)) {
    spec$shared$root <- shared_root
  }

  if (!is.null(output_path)) {
    spec$output$path <- output_path
  }

  validation <- be_validate_export_spec(spec)
  if (!isTRUE(validation$ok)) {
    stop(validation$message, call. = FALSE)
  }

  export_df <- be_assemble_export(
    spec = spec,
    shared_root = validation$paths$shared_root
  )
  snapshot_metadata <- list(
    redcap = tryCatch(
      be_read_snapshot_metadata(validation$paths$shared_root, "redcap"),
      error = function(err) list(error = conditionMessage(err))
    ),
    snapshot_index = tryCatch(
      be_read_snapshot_index(validation$paths$shared_root),
      error = function(err) list(error = conditionMessage(err))
    )
  )

  final_output <- spec$output$path
  dir.create(dirname(final_output), recursive = TRUE, showWarnings = FALSE)
  app_version <- tryCatch(
    as.character(utils::packageVersion("bachExporter")),
    error = function(err) "0.0.1"
  )

  manifest <- list(
    exported_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    refresh_mode = refresh_mode,
    shared_root = spec$shared$root,
    release_id = validation$paths$release_id,
    snapshot_metadata = snapshot_metadata,
    app = list(
      package = "bachExporter",
      version = app_version
    ),
    platform = list(
      r_version = R.version.string,
      platform = R.version$platform
    ),
    source = utils::modifyList(spec$source, list(api_key = "[masked]")),
    cohort = spec$cohort,
    domains = spec$domains,
    options = spec$options,
    output = spec$output
  )

  utils::write.csv(export_df, final_output, row.names = FALSE)
  jsonlite::write_json(
    manifest,
    path = paste0(final_output, ".manifest.json"),
    auto_unbox = TRUE,
    pretty = TRUE
  )

  invisible(list(
    output = final_output,
    manifest = paste0(final_output, ".manifest.json")
  ))
}
