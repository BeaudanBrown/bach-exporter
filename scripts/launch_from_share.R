launch_from_share <- function(shared_root) {
  source_root <- if (dir.exists(file.path(shared_root, "app"))) {
    file.path(shared_root, "app")
  } else {
    shared_root
  }
  if (
    !file.exists(file.path(source_root, "R", "paths.R")) ||
      !file.exists(file.path(source_root, "R", "release_runtime.R"))
  ) {
    stop("Release runtime files are missing.", call. = FALSE)
  }

  source(file.path(source_root, "R", "paths.R"), local = TRUE)
  source(file.path(source_root, "R", "release_runtime.R"), local = TRUE)

  validation <- be_validate_release_contract(shared_root = shared_root)
  if (!isTRUE(validation$ok)) {
    stop(validation$message, call. = FALSE)
  }
  paths <- validation$paths

  local_library <- be_local_library_dir(paths$build_id)
  .libPaths(unique(c(local_library, .libPaths())))

  message(sprintf("Launching BACH Exporter from build %s", paths$build_id))
  message(sprintf("Shared root: %s", shared_root))
  message(sprintf("App root: %s", paths$app_root))
  message(sprintf("Local library: %s", local_library))

  be_release_runtime_hook(
    "restore_dependencies",
    be_restore_release_dependencies
  )(
    release_root = paths$app_root,
    release_id = paths$build_id,
    library_dir = local_library
  )
  be_release_runtime_hook(
    "install_package",
    be_install_release_package
  )(
    release_root = paths$app_root,
    release_id = paths$build_id,
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
