be_admin_refresh_config <- function() {
  list(
    redcap_url = getOption(
      "bachExporter.placeholder_redcap_url",
      "https://redcap.example.org/api/"
    ),
    api_key = getOption(
      "bachExporter.placeholder_redcap_api_key",
      "REPLACE_WITH_ADMIN_TOKEN"
    )
  )
}
