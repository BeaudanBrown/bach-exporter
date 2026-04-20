be_release_refresh_script_path <- function(release_root) {
  file.path(release_root, "scripts", "refresh_snapshots.R")
}

be_shared_launcher_path <- function(shared_root) {
  file.path(shared_root, "launch_bach_exporter.R")
}

be_release_repo_paths <- function(repo_root) {
  list(
    description = file.path(repo_root, "DESCRIPTION"),
    namespace = file.path(repo_root, "NAMESPACE"),
    lockfile = file.path(repo_root, "renv.lock"),
    targets = file.path(repo_root, "_targets.R"),
    app = file.path(repo_root, "app.R"),
    r_dir = file.path(repo_root, "R"),
    presets_dir = file.path(repo_root, "inst", "presets"),
    inst_side_data_dir = file.path(repo_root, "inst", "side-data"),
    shared_side_data_dir = file.path(repo_root, "shared", "side-data"),
    shared_launcher = file.path(repo_root, "launch_bach_exporter.R"),
    launch_script = file.path(repo_root, "scripts", "launch_from_share.R"),
    validate_script = file.path(repo_root, "scripts", "validate_release.R"),
    refresh_script = file.path(repo_root, "scripts", "refresh_snapshots.R"),
    system_spec = file.path(repo_root, "specs", "system-spec.md")
  )
}

be_release_stage_root <- function(repo_root) {
  file.path(repo_root, "build", "shared-app-staging")
}

be_deployed_app_root <- function(shared_root) {
  file.path(shared_root, "app")
}

be_release_side_data_root <- function(shared_root) {
  file.path(shared_root, "side-data")
}

be_assert_build_id <- function(build_id) {
  build_id <- trimws(as.character(build_id %||% ""))
  if (!nzchar(build_id)) {
    stop("Build id is required.", call. = FALSE)
  }
  if (grepl("[/\\\\]", build_id)) {
    stop("Build id must not contain path separators.", call. = FALSE)
  }

  build_id
}

be_release_copy_tree <- function(from, to) {
  if (!dir.exists(from)) {
    stop(sprintf("Directory does not exist: %s", from), call. = FALSE)
  }

  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  entries <- list.files(
    from,
    all.files = TRUE,
    no.. = TRUE,
    full.names = TRUE,
    recursive = TRUE
  )
  if (!length(entries)) {
    return(invisible(to))
  }

  for (entry in entries) {
    relative <- substring(entry, nchar(from) + 2L)
    destination <- file.path(to, relative)
    if (dir.exists(entry)) {
      dir.create(destination, recursive = TRUE, showWarnings = FALSE)
      next
    }

    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    ok <- file.copy(entry, destination, overwrite = TRUE, copy.mode = TRUE)
    if (!isTRUE(ok)) {
      stop(
        sprintf("Failed to copy '%s' to '%s'.", entry, destination),
        call. = FALSE
      )
    }
  }

  invisible(to)
}

be_release_copy_file <- function(from, to) {
  if (!file.exists(from)) {
    stop(sprintf("File does not exist: %s", from), call. = FALSE)
  }

  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(from, to, overwrite = TRUE, copy.mode = TRUE)
  if (!isTRUE(ok)) {
    stop(
      sprintf("Failed to copy '%s' to '%s'.", from, to),
      call. = FALSE
    )
  }

  invisible(to)
}

be_release_dependency_name <- function(dependency) {
  dependency <- trimws(as.character(dependency %||% ""))
  dependency <- sub("\\s*\\(.*$", "", dependency)
  dependency <- trimws(dependency)
  dependency[nzchar(dependency)]
}

be_release_dependency_names <- function(value) {
  if (is.null(value) || !length(value)) {
    return(character())
  }

  dependencies <- unlist(value, use.names = FALSE)
  dependencies <- unlist(
    strsplit(as.character(dependencies), ","),
    use.names = FALSE
  )
  unique(be_release_dependency_name(dependencies))
}

be_release_description_runtime_packages <- function(description_path) {
  if (!file.exists(description_path)) {
    return(character())
  }

  description <- read.dcf(description_path)
  fields <- intersect(
    c("Depends", "Imports", "LinkingTo"),
    colnames(description)
  )
  dependencies <- unlist(description[1, fields, drop = TRUE], use.names = FALSE)
  packages <- be_release_dependency_names(dependencies)
  setdiff(packages, "R")
}

be_release_lockfile_package_dependencies <- function(package_record) {
  fields <- intersect(
    c("Depends", "Imports", "LinkingTo"),
    names(package_record)
  )
  dependencies <- unlist(
    package_record[fields],
    recursive = FALSE,
    use.names = FALSE
  )
  setdiff(be_release_dependency_names(dependencies), "R")
}

be_release_lockfile_runtime_packages <- function(
  lockfile,
  seed_packages
) {
  packages <- lockfile$Packages %||% list()
  package_names <- names(packages)
  selected <- character()
  queue <- unique(seed_packages)

  while (length(queue)) {
    package <- queue[[1]]
    queue <- queue[-1]
    if (package %in% selected || !(package %in% package_names)) {
      next
    }

    selected <- c(selected, package)
    dependencies <- be_release_lockfile_package_dependencies(packages[[
      package
    ]])
    queue <- unique(c(queue, setdiff(dependencies, selected)))
  }

  package_names[package_names %in% selected]
}

be_write_client_release_lockfile <- function(
  source_lockfile,
  description_path,
  output_lockfile,
  extra_packages = c("remotes")
) {
  if (!file.exists(source_lockfile)) {
    writeLines("{}", output_lockfile)
    return(invisible(character()))
  }

  lockfile <- jsonlite::read_json(source_lockfile, simplifyVector = FALSE)
  packages <- lockfile$Packages %||% list()
  seed_packages <- unique(c(
    be_release_description_runtime_packages(description_path),
    extra_packages
  ))
  runtime_packages <- be_release_lockfile_runtime_packages(
    lockfile = lockfile,
    seed_packages = seed_packages
  )

  lockfile$Packages <- packages[runtime_packages]
  dir.create(dirname(output_lockfile), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    lockfile,
    path = output_lockfile,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  invisible(runtime_packages)
}

be_release_git_metadata <- function(repo_root) {
  run_git <- function(args) {
    output <- tryCatch(
      system2("git", c("-C", repo_root, args), stdout = TRUE, stderr = FALSE),
      warning = function(warn) character(),
      error = function(err) character()
    )

    if (!length(output)) {
      return(NULL)
    }

    value <- trimws(output[[1]])
    if (!nzchar(value)) {
      return(NULL)
    }

    value
  }

  list(
    commit = run_git(c("rev-parse", "HEAD")),
    branch = run_git(c("rev-parse", "--abbrev-ref", "HEAD")),
    dirty = identical(run_git(c("status", "--porcelain")), NULL) == FALSE
  )
}

be_default_build_id <- function(repo_root, built_at = Sys.time()) {
  git <- be_release_git_metadata(repo_root)
  if (!is.null(git$commit) && nzchar(git$commit)) {
    if (isTRUE(git$dirty)) {
      return(sprintf(
        "%s-dirty-%s",
        substr(git$commit, 1L, 12L),
        format(as.POSIXct(built_at, tz = "UTC"), "%Y%m%dT%H%M%SZ", tz = "UTC")
      ))
    }

    return(substr(git$commit, 1L, 12L))
  }

  format(as.POSIXct(built_at, tz = "UTC"), "%Y%m%dT%H%M%SZ", tz = "UTC")
}

be_release_manifest_data <- function(
  build_id,
  repo_root,
  built_at = Sys.time()
) {
  description <- be_read_release_description(repo_root)
  if (!isTRUE(description$ok)) {
    stop(description$message, call. = FALSE)
  }

  git <- be_release_git_metadata(repo_root)

  list(
    build_id = build_id,
    built_at = format(
      as.POSIXct(built_at, tz = "UTC"),
      "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC"
    ),
    package = list(
      name = description$package,
      version = description$version
    ),
    source = list(
      repo_root = normalizePath(repo_root, winslash = "/", mustWork = TRUE),
      git_commit = git$commit,
      git_branch = git$branch,
      git_dirty = isTRUE(git$dirty)
    )
  )
}

be_write_release_manifest <- function(
  release_root,
  build_id,
  repo_root,
  built_at = Sys.time()
) {
  manifest <- be_release_manifest_data(
    build_id = build_id,
    repo_root = repo_root,
    built_at = built_at
  )
  jsonlite::write_json(
    manifest,
    path = be_release_manifest_path(release_root),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  invisible(manifest)
}

be_stage_shared_app <- function(
  output_root = NULL,
  repo_root = getwd(),
  build_id = NULL,
  include_side_data = TRUE,
  overwrite = FALSE,
  built_at = Sys.time()
) {
  repo_root <- normalizePath(repo_root, winslash = "/", mustWork = TRUE)
  build_id <- be_assert_build_id(
    build_id %||% be_default_build_id(repo_root, built_at)
  )
  output_root <- output_root %||% be_release_stage_root(repo_root)
  output_root <- normalizePath(output_root, winslash = "/", mustWork = FALSE)
  app_root <- be_deployed_app_root(output_root)
  repo_paths <- be_release_repo_paths(repo_root)

  if (dir.exists(output_root) || file.exists(output_root)) {
    if (!isTRUE(overwrite)) {
      stop(
        sprintf("Shared app staging root already exists: %s", output_root),
        call. = FALSE
      )
    }

    unlink(output_root, recursive = TRUE, force = TRUE)
  }

  dir.create(
    file.path(app_root, "scripts"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(
    file.path(output_root, "snapshots", "sidecars"),
    recursive = TRUE,
    showWarnings = FALSE
  )

  be_release_copy_file(
    repo_paths$description,
    file.path(app_root, "DESCRIPTION")
  )
  be_release_copy_file(repo_paths$namespace, file.path(app_root, "NAMESPACE"))
  be_write_client_release_lockfile(
    source_lockfile = repo_paths$lockfile,
    description_path = repo_paths$description,
    output_lockfile = file.path(app_root, "renv.lock")
  )
  if (file.exists(repo_paths$targets)) {
    be_release_copy_file(repo_paths$targets, file.path(app_root, "_targets.R"))
  }
  if (file.exists(repo_paths$app)) {
    be_release_copy_file(repo_paths$app, file.path(app_root, "app.R"))
  }
  be_release_copy_file(
    repo_paths$shared_launcher,
    be_shared_launcher_path(output_root)
  )
  be_release_copy_tree(repo_paths$r_dir, file.path(app_root, "R"))
  if (dir.exists(repo_paths$presets_dir)) {
    be_release_copy_tree(
      repo_paths$presets_dir,
      file.path(app_root, "inst", "presets")
    )
  }
  if (dir.exists(repo_paths$inst_side_data_dir)) {
    be_release_copy_tree(
      repo_paths$inst_side_data_dir,
      file.path(app_root, "inst", "side-data")
    )
  }
  be_release_copy_file(
    repo_paths$launch_script,
    be_release_launcher_path(app_root)
  )
  be_release_copy_file(
    repo_paths$validate_script,
    be_release_validate_script_path(app_root)
  )
  be_release_copy_file(
    repo_paths$refresh_script,
    be_release_refresh_script_path(app_root)
  )
  if (file.exists(repo_paths$system_spec)) {
    be_release_copy_file(
      repo_paths$system_spec,
      file.path(app_root, "specs_system_spec_snapshot.md")
    )
  }

  if (
    isTRUE(include_side_data) && dir.exists(repo_paths$shared_side_data_dir)
  ) {
    be_release_copy_tree(
      repo_paths$shared_side_data_dir,
      be_release_side_data_root(output_root)
    )
  }

  manifest <- be_write_release_manifest(
    release_root = app_root,
    build_id = build_id,
    repo_root = repo_root,
    built_at = built_at
  )
  validation <- be_validate_release_contract(output_root, allow_dev = FALSE)
  if (!isTRUE(validation$ok)) {
    stop(validation$message, call. = FALSE)
  }

  invisible(list(
    shared_root = output_root,
    app_root = app_root,
    build_id = build_id,
    manifest = manifest,
    validation = validation
  ))
}

be_prepare_release <- function(
  release_id = NULL,
  output_root = NULL,
  repo_root = getwd(),
  include_side_data = TRUE,
  overwrite = FALSE,
  prepared_at = Sys.time(),
  build_id = release_id
) {
  be_stage_shared_app(
    output_root = output_root,
    repo_root = repo_root,
    build_id = build_id,
    include_side_data = include_side_data,
    overwrite = overwrite,
    built_at = prepared_at
  )
}

be_write_admin_refresh_config <- function(
  shared_root,
  config_path = be_admin_refresh_config_path()
) {
  shared_root <- normalizePath(shared_root, winslash = "/", mustWork = FALSE)
  existing <- if (file.exists(config_path)) {
    jsonlite::read_json(config_path, simplifyVector = TRUE)
  } else {
    list()
  }

  existing$shared_root <- shared_root
  dir.create(dirname(config_path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    existing,
    path = config_path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  invisible(config_path)
}

be_resolve_admin_shared_root <- function(
  shared_root = NULL,
  config_path = NULL
) {
  if (!is.null(shared_root) && nzchar(shared_root)) {
    return(normalizePath(shared_root, winslash = "/", mustWork = FALSE))
  }

  config <- be_admin_refresh_config(config_path = config_path)
  resolved <- config$shared_root %||% NULL
  if (is.null(resolved) || !nzchar(resolved)) {
    stop(
      "Shared root is not configured. Use set-admin-shared-root, populate admin-refresh.json, or pass --shared-root.",
      call. = FALSE
    )
  }

  normalizePath(resolved, winslash = "/", mustWork = FALSE)
}

be_publish_shared_app <- function(
  staged_root,
  shared_root = NULL,
  overwrite = TRUE,
  sync_side_data = TRUE
) {
  staged_root <- normalizePath(staged_root, winslash = "/", mustWork = TRUE)
  staged_validation <- be_validate_release_contract(
    staged_root,
    allow_dev = FALSE
  )
  if (!isTRUE(staged_validation$ok)) {
    stop(staged_validation$message, call. = FALSE)
  }

  shared_root <- be_resolve_admin_shared_root(shared_root)
  target_app_root <- be_deployed_app_root(shared_root)
  temp_root <- file.path(
    shared_root,
    sprintf(".deploy-%s", staged_validation$paths$build_id)
  )

  dir.create(shared_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(
    file.path(shared_root, "snapshots", "sidecars"),
    recursive = TRUE,
    showWarnings = FALSE
  )

  if (dir.exists(temp_root) || file.exists(temp_root)) {
    unlink(temp_root, recursive = TRUE, force = TRUE)
  }
  dir.create(temp_root, recursive = TRUE, showWarnings = FALSE)
  be_release_copy_tree(
    staged_validation$paths$app_root,
    be_deployed_app_root(temp_root)
  )
  be_release_copy_file(
    be_shared_launcher_path(staged_root),
    be_shared_launcher_path(temp_root)
  )

  if (
    isTRUE(sync_side_data) && dir.exists(be_release_side_data_root(staged_root))
  ) {
    be_release_copy_tree(
      be_release_side_data_root(staged_root),
      be_release_side_data_root(temp_root)
    )
  }

  candidate_validation <- be_validate_release_contract(
    temp_root,
    allow_dev = FALSE
  )
  if (!isTRUE(candidate_validation$ok)) {
    unlink(temp_root, recursive = TRUE, force = TRUE)
    stop(candidate_validation$message, call. = FALSE)
  }

  previous_build_id <- be_read_build_id(shared_root)
  if (dir.exists(target_app_root) || file.exists(target_app_root)) {
    if (!isTRUE(overwrite)) {
      unlink(temp_root, recursive = TRUE, force = TRUE)
      stop(
        sprintf("Shared app already exists: %s", target_app_root),
        call. = FALSE
      )
    }

    unlink(target_app_root, recursive = TRUE, force = TRUE)
  }

  if (!file.rename(be_deployed_app_root(temp_root), target_app_root)) {
    unlink(temp_root, recursive = TRUE, force = TRUE)
    stop(
      "Failed to move validated app bundle into the shared root.",
      call. = FALSE
    )
  }
  if (file.exists(be_shared_launcher_path(shared_root))) {
    unlink(be_shared_launcher_path(shared_root), force = TRUE)
  }
  if (
    !file.rename(
      be_shared_launcher_path(temp_root),
      be_shared_launcher_path(shared_root)
    )
  ) {
    unlink(temp_root, recursive = TRUE, force = TRUE)
    stop(
      "Failed to move launch script into the shared root.",
      call. = FALSE
    )
  }

  if (dir.exists(be_release_side_data_root(temp_root))) {
    unlink(
      be_release_side_data_root(shared_root),
      recursive = TRUE,
      force = TRUE
    )
    if (
      !file.rename(
        be_release_side_data_root(temp_root),
        be_release_side_data_root(shared_root)
      )
    ) {
      unlink(temp_root, recursive = TRUE, force = TRUE)
      stop(
        "Failed to move shared side-data into the shared root.",
        call. = FALSE
      )
    }
  }
  unlink(temp_root, recursive = TRUE, force = TRUE)

  active_validation <- be_validate_release_contract(
    shared_root,
    allow_dev = FALSE
  )
  if (!isTRUE(active_validation$ok)) {
    stop(active_validation$message, call. = FALSE)
  }

  invisible(list(
    shared_root = shared_root,
    build_id = active_validation$paths$build_id,
    previous_build_id = previous_build_id,
    app_root = target_app_root,
    validation = active_validation
  ))
}

be_publish_release <- function(
  staged_root,
  shared_root = NULL,
  release_id = NULL,
  overwrite = TRUE,
  sync_side_data = TRUE
) {
  be_publish_shared_app(
    staged_root = staged_root,
    shared_root = shared_root,
    overwrite = overwrite,
    sync_side_data = sync_side_data
  )
}

be_parse_script_args <- function(args) {
  parsed <- list()
  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (!startsWith(arg, "--")) {
      parsed$positionals <- c(parsed$positionals %||% character(), arg)
      i <- i + 1L
      next
    }

    key <- substring(arg, 3L)
    if (i == length(args) || startsWith(args[[i + 1L]], "--")) {
      parsed[[key]] <- TRUE
      i <- i + 1L
      next
    }

    parsed[[key]] <- args[[i + 1L]]
    i <- i + 2L
  }

  parsed
}
