.onLoad <- function(libname, pkgname) {
  options(
    bachExporter.placeholder_redcap_url = "https://redcap.example.org/api/",
    bachExporter.placeholder_redcap_api_key = "REPLACE_WITH_ADMIN_TOKEN"
  )
}
