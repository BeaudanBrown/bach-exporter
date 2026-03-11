launch_from_share <- function(shared_root) {
  release_file <- file.path(shared_root, "CURRENT_RELEASE.txt")
  if (file.exists(release_file)) {
    release_id <- trimws(readLines(release_file, warn = FALSE, n = 1))
    release_root <- file.path(shared_root, "releases", release_id)
  } else {
    release_id <- "dev"
    release_root <- shared_root
  }

  source(file.path(release_root, "R", "paths.R"), local = TRUE)
  source(file.path(release_root, "R", "release_runtime.R"), local = TRUE)

  paths <- be_shared_paths(shared_root)
  if (is.null(paths$release_id) || is.null(paths$release_root)) {
    stop(
      "Unable to determine the active release from the shared root.",
      call. = FALSE
    )
  }
  if (!dir.exists(paths$release_root)) {
    stop("Active release directory does not exist.", call. = FALSE)
  }

  manifest_validation <- be_validate_release_manifest(
    release_root = paths$release_root,
    release_id = paths$release_id
  )
  if (!isTRUE(manifest_validation$ok)) {
    stop(manifest_validation$message, call. = FALSE)
  }

  local_library <- be_local_library_dir(paths$release_id)
  .libPaths(unique(c(local_library, .libPaths())))

  message(sprintf("Launching BACH Exporter from release %s", paths$release_id))
  message(sprintf("Shared root: %s", shared_root))
  message(sprintf("Release root: %s", paths$release_root))
  message(sprintf("Local library: %s", local_library))

  be_restore_release_dependencies(
    release_root = paths$release_root,
    release_id = paths$release_id,
    library_dir = local_library
  )
  be_install_release_package(
    release_root = paths$release_root,
    release_id = paths$release_id,
    library_dir = local_library,
    package_name = manifest_validation$package$package
  )

  if (!requireNamespace(manifest_validation$package$package, quietly = TRUE)) {
    stop(
      "Installed release package could not be loaded from the local library.",
      call. = FALSE
    )
  }

  shiny::runApp(
    bachExporter::run_app(shared_root = shared_root),
    launch.browser = TRUE
  )
}
