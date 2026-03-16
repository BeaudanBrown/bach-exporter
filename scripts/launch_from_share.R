launch_from_share <- function(shared_root) {
  `%||%` <- function(x, y) {
    if (is.null(x)) y else x
  }

  release_file <- file.path(shared_root, "CURRENT_RELEASE.txt")
  release_id <- if (file.exists(release_file)) {
    trimws(readLines(release_file, warn = FALSE, n = 1))
  } else {
    "dev"
  }
  if (!nzchar(release_id)) {
    stop("CURRENT_RELEASE.txt is empty.", call. = FALSE)
  }
  release_root <- if (
    identical(release_id, "dev") &&
      !file.exists(release_file) &&
      file.exists(file.path(shared_root, "DESCRIPTION"))
  ) {
    shared_root
  } else {
    file.path(shared_root, "releases", release_id)
  }
  if (
    !file.exists(file.path(release_root, "R", "paths.R")) ||
      !file.exists(file.path(release_root, "R", "release_runtime.R"))
  ) {
    stop("Release runtime files are missing.", call. = FALSE)
  }

  source(file.path(release_root, "R", "paths.R"), local = TRUE)
  source(file.path(release_root, "R", "release_runtime.R"), local = TRUE)

  validation <- be_validate_release_contract(shared_root = shared_root)
  if (!isTRUE(validation$ok)) {
    stop(validation$message, call. = FALSE)
  }
  paths <- validation$paths

  local_library <- be_local_library_dir(paths$release_id)
  .libPaths(unique(c(local_library, .libPaths())))

  message(sprintf("Launching BACH Exporter from release %s", paths$release_id))
  message(sprintf("Shared root: %s", shared_root))
  message(sprintf("Release root: %s", paths$release_root))
  message(sprintf("Local library: %s", local_library))

  be_release_runtime_hook(
    "restore_dependencies",
    be_restore_release_dependencies
  )(
    release_root = paths$release_root,
    release_id = paths$release_id,
    library_dir = local_library
  )
  be_release_runtime_hook(
    "install_package",
    be_install_release_package
  )(
    release_root = paths$release_root,
    release_id = paths$release_id,
    library_dir = local_library,
    package_name = validation$package$package
  )
  be_release_runtime_hook(
    "launch_app",
    be_launch_installed_release_app
  )(
    package_name = validation$package$package,
    shared_root = shared_root
  )
}
