be_export_manifest_source <- function(source) {
  source_check <- be_researcher_source_spec(source)
  if (!isTRUE(source_check$ok)) {
    return(list(mode = "snapshot"))
  }

  source_check$source
}

be_build_export_manifest <- function(
  spec,
  shared_root,
  refresh_mode = "auto",
  snapshot_metadata = NULL,
  execution_mode = "targets"
) {
  if (is.null(snapshot_metadata)) {
    snapshot_metadata <- be_collect_snapshot_metadata(shared_root)
  }

  shared_paths <- be_shared_paths(shared_root)
  shared_manifest <- be_read_shared_manifest(shared_root)
  app_version <- tryCatch(
    as.character(utils::packageVersion("bachExporter")),
    error = function(err) "0.0.1"
  )

  list(
    exported_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    refresh_mode = refresh_mode,
    execution_mode = execution_mode,
    shared_root = spec$shared$root,
    build_id = shared_paths$build_id,
    snapshot_metadata = snapshot_metadata,
    app = list(
      package = "bachExporter",
      version = app_version,
      shared_manifest = shared_manifest
    ),
    platform = list(
      r_version = R.version.string,
      platform = R.version$platform
    ),
    source = be_export_manifest_source(spec$source),
    cohort = spec$cohort,
    domains = spec$domains,
    options = spec$options,
    output = spec$output
  )
}

be_targets_script_path <- function(targets_dir) {
  file.path(targets_dir, "_targets_export.R")
}

be_targets_store_path <- function(targets_dir) {
  file.path(targets_dir, "store")
}

be_resolve_export_project_root <- function(project_root = getwd()) {
  candidates <- c(
    project_root,
    file.path(project_root, ".."),
    file.path(project_root, "..", "..")
  )
  candidates <- normalizePath(
    candidates,
    winslash = "/",
    mustWork = FALSE
  )
  matches <- candidates[dir.exists(file.path(candidates, "R"))]
  if (length(matches)) {
    return(matches[[1]])
  }

  normalizePath(project_root, winslash = "/", mustWork = TRUE)
}

be_write_export_targets_script <- function(
  script_path,
  spec,
  shared_root,
  refresh_mode = "auto",
  project_root = getwd()
) {
  quote_r_string <- function(value) {
    encodeString(as.character(value), quote = "\"")
  }

  spec_lines <- capture.output(dput(spec))

  script_lines <- c(
    "library(targets)",
    "tar_option_set(",
    "  packages = c('jsonlite'),",
    "  format = 'rds',",
    "  seed = 20260311",
    ")",
    sprintf(
      "project_root <- %s",
      quote_r_string(normalizePath(
        project_root,
        winslash = "/",
        mustWork = TRUE
      ))
    ),
    "if (exists('be_target_graph', mode = 'function', inherits = TRUE)) {",
    "  be_target_graph <- get('be_target_graph', inherits = TRUE)",
    "} else if (dir.exists(file.path(project_root, 'R'))) {",
    "  for (path in sort(Sys.glob(file.path(project_root, 'R', '*.R')))) {",
    "    source(path, local = FALSE)",
    "  }",
    "} else if (requireNamespace('bachExporter', quietly = TRUE)) {",
    "  be_target_graph <- get('be_target_graph', envir = asNamespace('bachExporter'))",
    "} else {",
    "  stop('Cannot find bachExporter package or project R sources.', call. = FALSE)",
    "}",
    "spec <-"
  )
  script_lines <- c(script_lines, spec_lines)
  script_lines <- c(
    script_lines,
    sprintf("shared_root <- %s", quote_r_string(shared_root)),
    sprintf("refresh_mode <- %s", quote_r_string(refresh_mode)),
    "be_target_graph(",
    "  spec = spec,",
    "  shared_root = shared_root,",
    "  refresh_mode = refresh_mode",
    ")"
  )

  writeLines(script_lines, con = script_path)
  invisible(script_path)
}

be_run_export_pipeline <- function(
  spec,
  shared_root,
  refresh_mode = "auto",
  build_id = "dev",
  project_root = getwd()
) {
  project_root <- be_resolve_export_project_root(project_root)
  build_id <- build_id %||% "dev"
  targets_dir <- file.path(
    be_local_targets_dir(build_id, shared_root = shared_root),
    "export-pipeline"
  )
  dir.create(targets_dir, recursive = TRUE, showWarnings = FALSE)

  script_path <- be_targets_script_path(targets_dir)
  store_path <- be_targets_store_path(targets_dir)

  be_write_export_targets_script(
    script_path = script_path,
    spec = spec,
    shared_root = shared_root,
    refresh_mode = refresh_mode,
    project_root = project_root
  )

  targets::tar_make(
    script = script_path,
    store = store_path,
    callr_function = NULL,
    reporter = "silent"
  )

  list(
    export_df = targets::tar_read(
      export_data,
      store = store_path
    ),
    manifest = targets::tar_read(
      export_manifest,
      store = store_path
    )
  )
}
