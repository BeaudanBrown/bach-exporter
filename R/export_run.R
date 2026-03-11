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

  final_output <- spec$output$path
  dir.create(dirname(final_output), recursive = TRUE, showWarnings = FALSE)

  manifest <- list(
    exported_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    refresh_mode = refresh_mode,
    shared_root = spec$shared$root,
    release_id = validation$paths$release_id,
    source = utils::modifyList(spec$source, list(api_key = "[masked]")),
    cohort = spec$cohort,
    domains = spec$domains,
    options = spec$options,
    output = spec$output
  )

  # Placeholder output until domain migration begins.
  output_df <- data.frame(
    message = "Placeholder export: backend scaffold only",
    release_id = validation$paths$release_id,
    redcap_url = spec$source$redcap_url,
    stringsAsFactors = FALSE
  )

  utils::write.csv(output_df, final_output, row.names = FALSE)
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
