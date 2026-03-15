run_export <- function(
  spec,
  output_path = NULL,
  shared_root = NULL,
  refresh_mode = "auto",
  execution_mode = c("targets", "direct")
) {
  execution_mode <- match.arg(execution_mode)

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

  pipeline_result <- if (identical(execution_mode, "targets")) {
    be_run_export_pipeline(
      spec = spec,
      shared_root = validation$paths$shared_root,
      refresh_mode = refresh_mode,
      release_id = validation$paths$release_id
    )
  } else {
    list(
      export_df = be_assemble_export(
        spec = spec,
        shared_root = validation$paths$shared_root
      ),
      manifest = be_build_export_manifest(
        spec = spec,
        shared_root = validation$paths$shared_root,
        refresh_mode = refresh_mode,
        execution_mode = execution_mode
      )
    )
  }

  final_output <- spec$output$path
  dir.create(dirname(final_output), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(pipeline_result$export_df, final_output, row.names = FALSE)
  jsonlite::write_json(
    pipeline_result$manifest,
    path = paste0(final_output, ".manifest.json"),
    auto_unbox = TRUE,
    pretty = TRUE
  )

  invisible(list(
    output = final_output,
    manifest = paste0(final_output, ".manifest.json")
  ))
}
