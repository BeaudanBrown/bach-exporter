be_release_manifest_path <- function(release_root) {
  file.path(release_root, "manifest.json")
}

be_release_lockfile_path <- function(release_root) {
  file.path(release_root, "renv.lock")
}

be_release_description_path <- function(release_root) {
  file.path(release_root, "DESCRIPTION")
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
