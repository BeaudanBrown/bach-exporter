be_assemble_export <- function(spec, shared_root) {
  domains <- unique(spec$domains %||% character())
  supported_domains <- c("participants")
  unsupported_domains <- setdiff(domains, supported_domains)
  if (length(unsupported_domains)) {
    stop(
      sprintf(
        "The following domains are not implemented yet: %s",
        paste(unsupported_domains, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  redcap_df <- be_read_redcap_snapshot(shared_root)
  output <- NULL
  participant_ids <- be_resolve_cohort_ids(spec)

  if ("participants" %in% domains) {
    output <- be_build_participants_domain(
      redcap_df = redcap_df,
      years = spec$cohort$years %||% NULL
    )
    output <- be_filter_participants(output, participant_ids = participant_ids)
  }

  if (is.null(output)) {
    stop("No supported domains were selected for export.", call. = FALSE)
  }

  output
}
