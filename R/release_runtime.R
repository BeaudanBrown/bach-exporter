if (!exists("%||%", mode = "function")) {
  `%||%` <- function(x, y) {
    if (is.null(x)) {
      y
    } else {
      x
    }
  }
}

be_release_manifest_path <- function(release_root) {
  file.path(release_root, "manifest.json")
}

be_release_lockfile_path <- function(release_root) {
  file.path(release_root, "renv.lock")
}

be_release_description_path <- function(release_root) {
  file.path(release_root, "DESCRIPTION")
}

be_release_namespace_path <- function(release_root) {
  file.path(release_root, "NAMESPACE")
}

be_release_runtime_path <- function(release_root) {
  file.path(release_root, "R", "release_runtime.R")
}

be_release_paths_path <- function(release_root) {
  file.path(release_root, "R", "paths.R")
}

be_release_launcher_path <- function(release_root) {
  file.path(release_root, "scripts", "launch_from_share.R")
}

be_release_validate_script_path <- function(release_root) {
  file.path(release_root, "scripts", "validate_release.R")
}

be_release_required_files <- function(release_root, release_id = "dev") {
  required_paths <- c(
    be_release_description_path(release_root),
    be_release_namespace_path(release_root),
    be_release_paths_path(release_root),
    be_release_runtime_path(release_root),
    be_release_launcher_path(release_root),
    be_release_validate_script_path(release_root)
  )

  if (!identical(release_id, "dev")) {
    required_paths <- c(
      required_paths,
      be_release_manifest_path(release_root),
      be_release_lockfile_path(release_root)
    )
  }

  required_paths
}

be_validate_release_files <- function(release_root, release_id = "dev") {
  missing_paths <- be_release_required_files(
    release_root = release_root,
    release_id = release_id
  )
  missing_paths <- missing_paths[!file.exists(missing_paths)]

  if (length(missing_paths)) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Release is missing required files: %s",
        paste(basename(missing_paths), collapse = ", ")
      ),
      missing_paths = missing_paths
    ))
  }

  list(
    ok = TRUE,
    message = "Release contains the required runtime files.",
    missing_paths = character()
  )
}

be_validate_release_contract <- function(shared_root, allow_dev = TRUE) {
  if (is.null(shared_root) || !nzchar(shared_root)) {
    return(list(ok = FALSE, message = "Shared root path is empty."))
  }

  if (!dir.exists(shared_root)) {
    return(list(ok = FALSE, message = "Shared root directory does not exist."))
  }

  paths <- be_shared_paths(shared_root)
  if (is.null(paths$release_id)) {
    return(list(
      ok = FALSE,
      message = "Shared root is missing CURRENT_RELEASE.txt and does not look like a direct release root."
    ))
  }
  if (!allow_dev && identical(paths$release_id, "dev")) {
    return(list(
      ok = FALSE,
      message = "Dev-mode release roots are not valid for published release validation."
    ))
  }
  if (is.null(paths$release_root) || !dir.exists(paths$release_root)) {
    return(list(
      ok = FALSE,
      message = "Active release folder does not exist under releases/."
    ))
  }

  file_check <- be_validate_release_files(
    release_root = paths$release_root,
    release_id = paths$release_id
  )
  if (!isTRUE(file_check$ok)) {
    return(utils::modifyList(file_check, list(paths = paths)))
  }

  manifest_check <- be_validate_release_manifest(
    release_root = paths$release_root,
    release_id = paths$release_id
  )
  if (!isTRUE(manifest_check$ok)) {
    return(utils::modifyList(manifest_check, list(paths = paths)))
  }

  list(
    ok = TRUE,
    message = "Release contract is valid.",
    paths = paths,
    manifest = manifest_check$manifest,
    package = manifest_check$package
  )
}

be_read_release_description <- function(release_root) {
  description_path <- be_release_description_path(release_root)
  if (!file.exists(description_path)) {
    return(list(
      ok = FALSE,
      message = "Release DESCRIPTION file is missing."
    ))
  }

  description <- tryCatch(
    read.dcf(description_path),
    error = function(err) err
  )
  if (inherits(description, "error")) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Failed to read DESCRIPTION: %s",
        conditionMessage(description)
      )
    ))
  }

  package_name <- unname(description[1, "Package"] %||% NA_character_)
  package_version <- unname(description[1, "Version"] %||% NA_character_)
  if (!nzchar(package_name) || !nzchar(package_version)) {
    return(list(
      ok = FALSE,
      message = "DESCRIPTION must contain Package and Version fields."
    ))
  }

  list(
    ok = TRUE,
    package = package_name,
    version = package_version
  )
}

be_validate_release_manifest <- function(release_root, release_id = "dev") {
  description <- be_read_release_description(release_root)
  if (!isTRUE(description$ok)) {
    return(description)
  }

  manifest_path <- be_release_manifest_path(release_root)
  if (!file.exists(manifest_path)) {
    if (identical(release_id, "dev")) {
      return(list(
        ok = TRUE,
        message = "Release manifest is missing for dev mode; continuing without manifest validation.",
        manifest = NULL,
        package = description
      ))
    }

    return(list(
      ok = FALSE,
      message = "Release manifest is missing."
    ))
  }

  manifest <- tryCatch(
    jsonlite::read_json(manifest_path, simplifyVector = TRUE),
    error = function(err) err
  )
  if (inherits(manifest, "error")) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Failed to read release manifest: %s",
        conditionMessage(manifest)
      )
    ))
  }

  manifest_release_id <- manifest$release_id %||% NULL
  if (
    !is.null(manifest_release_id) && !identical(manifest_release_id, release_id)
  ) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Release manifest release_id '%s' does not match active release '%s'.",
        manifest_release_id,
        release_id
      )
    ))
  }

  manifest_package_name <- manifest$package$name %||% NULL
  manifest_package_version <- manifest$package$version %||% NULL
  if (
    !is.null(manifest_package_name) &&
      !identical(manifest_package_name, description$package)
  ) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Release manifest package '%s' does not match DESCRIPTION package '%s'.",
        manifest_package_name,
        description$package
      )
    ))
  }
  if (
    !is.null(manifest_package_version) &&
      !identical(manifest_package_version, description$version)
  ) {
    return(list(
      ok = FALSE,
      message = sprintf(
        "Release manifest version '%s' does not match DESCRIPTION version '%s'.",
        manifest_package_version,
        description$version
      )
    ))
  }

  list(
    ok = TRUE,
    message = "Release manifest is valid.",
    manifest = manifest,
    package = description
  )
}

be_release_runtime_hook <- function(name, default) {
  hooks <- getOption("bachExporter.release_runtime_hooks", default = list())
  hook <- hooks[[name]] %||% default
  if (!is.function(hook)) {
    stop(
      sprintf("Release runtime hook '%s' must be a function.", name),
      call. = FALSE
    )
  }
  hook
}

be_ensure_bootstrap_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

be_restore_release_dependencies <- function(
  release_root,
  release_id,
  library_dir
) {
  lockfile_path <- be_release_lockfile_path(release_root)
  if (!file.exists(lockfile_path)) {
    if (identical(release_id, "dev")) {
      message(
        "Skipping renv restore for dev release because renv.lock is missing."
      )
      return(invisible(FALSE))
    }

    stop("Release renv.lock is missing.", call. = FALSE)
  }

  be_ensure_bootstrap_package("renv")
  renv::consent(provided = TRUE)
  renv::restore(
    project = release_root,
    library = library_dir,
    prompt = FALSE
  )

  invisible(TRUE)
}

be_install_release_package <- function(
  release_root,
  release_id,
  library_dir,
  package_name
) {
  be_ensure_bootstrap_package("remotes")

  local_library_norm <- normalizePath(
    library_dir,
    winslash = "/",
    mustWork = FALSE
  )
  installed_path <- suppressWarnings(find.package(package_name, quiet = TRUE))
  package_installed <- length(installed_path) == 1 &&
    startsWith(
      normalizePath(installed_path, winslash = "/", mustWork = FALSE),
      local_library_norm
    )
  if (package_installed && !identical(release_id, "dev")) {
    return(invisible(FALSE))
  }

  remotes::install_local(
    path = release_root,
    lib = library_dir,
    upgrade = "never",
    dependencies = FALSE,
    force = identical(release_id, "dev"),
    quiet = TRUE
  )

  invisible(TRUE)
}

be_release_run_app_fn <- function(package_name) {
  namespace <- asNamespace(package_name)
  run_app_fn <- tryCatch(
    getExportedValue(package_name, "run_app"),
    error = function(err) NULL
  )
  if (
    is.null(run_app_fn) &&
      exists("run_app", envir = namespace, inherits = FALSE)
  ) {
    run_app_fn <- get("run_app", envir = namespace, inherits = FALSE)
  }

  run_app_fn
}

be_launch_installed_release_app <- function(package_name, shared_root) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    stop(
      "Installed release package could not be loaded from the local library.",
      call. = FALSE
    )
  }

  run_app_fn <- be_release_run_app_fn(package_name)
  if (!is.function(run_app_fn)) {
    stop(
      sprintf(
        "Installed release package '%s' does not expose a usable run_app() entrypoint.",
        package_name
      ),
      call. = FALSE
    )
  }

  app <- run_app_fn(shared_root = shared_root)
  shiny::runApp(app, launch.browser = TRUE)
}
