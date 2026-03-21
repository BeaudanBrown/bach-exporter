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

  run_id <- be_make_run_id()
  started_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  log_path <- be_export_log_path(run_id)

  be_append_export_log(
    log_path,
    "Export started.",
    data = list(
      execution_mode = execution_mode,
      refresh_mode = refresh_mode,
      shared_root = validation$paths$shared_root,
      build_id = validation$paths$build_id,
      output_path = spec$output$path,
      domains = spec$domains
    )
  )

  result <- tryCatch(
    {
      pipeline_result <- if (identical(execution_mode, "targets")) {
        be_run_export_pipeline(
          spec = spec,
          shared_root = validation$paths$shared_root,
          refresh_mode = refresh_mode,
          build_id = validation$paths$build_id
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

      be_append_export_log(
        log_path,
        "Export data assembled.",
        data = list(row_count = nrow(pipeline_result$export_df))
      )

      final_output <- spec$output$path
      dir.create(dirname(final_output), recursive = TRUE, showWarnings = FALSE)
      utils::write.csv(
        pipeline_result$export_df,
        final_output,
        row.names = FALSE
      )

      completed_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      manifest <- be_finalize_export_manifest(
        manifest = pipeline_result$manifest,
        run_id = run_id,
        log_path = log_path,
        started_at = started_at,
        completed_at = completed_at,
        output_path = final_output,
        row_count = nrow(pipeline_result$export_df)
      )
      manifest_path <- paste0(final_output, ".manifest.json")
      jsonlite::write_json(
        manifest,
        path = manifest_path,
        auto_unbox = TRUE,
        pretty = TRUE
      )

      be_append_export_log(
        log_path,
        "Export files written.",
        data = list(
          output_path = final_output,
          manifest_path = manifest_path,
          row_count = nrow(pipeline_result$export_df)
        )
      )

      be_append_export_history_record(
        be_build_export_history_record(
          manifest = manifest,
          output_path = final_output,
          manifest_path = manifest_path,
          log_path = log_path,
          status = "success",
          started_at = started_at,
          completed_at = completed_at,
          row_count = nrow(pipeline_result$export_df)
        )
      )

      list(
        output = final_output,
        manifest = manifest_path,
        log = log_path,
        run_id = run_id
      )
    },
    error = function(err) {
      completed_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

      be_append_export_log(
        log_path,
        conditionMessage(err),
        level = "ERROR"
      )

      failure_manifest <- be_build_export_manifest(
        spec = spec,
        shared_root = validation$paths$shared_root,
        refresh_mode = refresh_mode,
        execution_mode = execution_mode
      )
      failure_manifest <- be_finalize_export_manifest(
        manifest = failure_manifest,
        run_id = run_id,
        log_path = log_path,
        started_at = started_at,
        completed_at = completed_at,
        output_path = spec$output$path,
        row_count = NA_integer_
      )

      be_append_export_history_record(
        be_build_export_history_record(
          manifest = failure_manifest,
          output_path = spec$output$path,
          manifest_path = paste0(spec$output$path, ".manifest.json"),
          log_path = log_path,
          status = "failed",
          started_at = started_at,
          completed_at = completed_at,
          error_message = conditionMessage(err)
        )
      )

      stop(err)
    }
  )

  invisible(result)
}
