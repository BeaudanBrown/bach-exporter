env <- new.env(parent = baseenv())
sys.source(file.path("..", "..", "launch_bach_exporter.R"), envir = env)

make_launcher_packaged_shared_root <- function(build_id = "build-20260311") {
  shared_root <- tempfile("launcher-shared-root-")
  app_root <- file.path(shared_root, "app")

  dir.create(file.path(app_root, "R"), recursive = TRUE, showWarnings = FALSE)
  dir.create(
    file.path(app_root, "scripts"),
    recursive = TRUE,
    showWarnings = FALSE
  )

  writeLines(
    c(
      "Package: bachExporter",
      "Version: 0.0.1"
    ),
    file.path(app_root, "DESCRIPTION")
  )
  file.copy(
    file.path("..", "..", "NAMESPACE"),
    file.path(app_root, "NAMESPACE")
  )
  writeLines("{}", file.path(app_root, "renv.lock"))
  jsonlite::write_json(
    list(
      build_id = build_id,
      package = list(name = "bachExporter", version = "0.0.1")
    ),
    path = file.path(app_root, "manifest.json"),
    auto_unbox = TRUE
  )
  file.copy(
    file.path("..", "..", "R", "paths.R"),
    file.path(app_root, "R", "paths.R")
  )
  file.copy(
    file.path("..", "..", "R", "release_runtime.R"),
    file.path(app_root, "R", "release_runtime.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "launch_from_share.R"),
    file.path(app_root, "scripts", "launch_from_share.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "validate_release.R"),
    file.path(app_root, "scripts", "validate_release.R")
  )
  file.copy(
    file.path("..", "..", "scripts", "refresh_snapshots.R"),
    file.path(app_root, "scripts", "refresh_snapshots.R")
  )

  shared_root
}

test_that("launcher status text is always length-one character output", {
  expect_equal(env$be_launcher_status_text(NULL), "")
  expect_equal(env$be_launcher_status_text("ok"), "ok")
  expect_equal(
    env$be_launcher_status_text(c("line one", "line two")),
    "line one\nline two"
  )
  expect_length(env$be_launcher_status_text(c("a", "b", "c")), 1)
})

test_that("launcher safe copy can overwrite read-only dependency files", {
  temp_root <- tempfile("launcher-safe-copy-")
  dir.create(temp_root, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(temp_root, recursive = TRUE), add = TRUE)

  source_dir <- file.path(temp_root, "src")
  out_dir <- file.path(temp_root, "out")
  dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  source_file <- file.path(source_dir, "asset.js")
  writeLines("first", source_file)

  expect_true(env$be_safe_copy_into_dir(source_file, out_dir))

  dest_file <- file.path(out_dir, basename(source_file))
  Sys.chmod(dest_file, mode = "444", use_umask = FALSE)
  writeLines("second", source_file)

  expect_true(env$be_safe_copy_into_dir(source_file, out_dir))
  expect_identical(readLines(dest_file), "second")
})

test_that("launcher overwrite preparation makes existing read-only files writable", {
  temp_root <- tempfile("launcher-writable-")
  dir.create(temp_root, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(temp_root, recursive = TRUE), add = TRUE)

  target_file <- file.path(temp_root, "asset.js")
  writeLines("content", target_file)
  Sys.chmod(target_file, mode = "444", use_umask = FALSE)

  env$be_prepare_overwrite_targets(target_file)

  expect_equal(unname(file.access(target_file, 2)), 0)
})

test_that("launcher tempdir uses the user-local cache root by default", {
  local_cache <- tempfile("launcher-cache-")
  dir.create(local_cache, recursive = TRUE, showWarnings = FALSE)
  Sys.setenv(BACH_EXPORTER_LOCAL_CACHE_DIR = local_cache)
  on.exit(
    {
      Sys.unsetenv("BACH_EXPORTER_LOCAL_CACHE_DIR")
      unlink(local_cache, recursive = TRUE)
    },
    add = TRUE
  )

  expected <- normalizePath(
    file.path(local_cache, "tmp"),
    winslash = "/",
    mustWork = FALSE
  )

  expect_equal(env$be_launcher_local_cache_root(), local_cache)
  expect_equal(env$be_launcher_tmp_dir(), expected)
})

test_that("launcher bootstrap library is user-local and added before system libraries", {
  local_cache <- tempfile("launcher-cache-")
  dir.create(local_cache, recursive = TRUE, showWarnings = FALSE)
  Sys.setenv(BACH_EXPORTER_LOCAL_CACHE_DIR = local_cache)
  old_libpaths <- .libPaths()
  on.exit(
    {
      .libPaths(old_libpaths)
      Sys.unsetenv("BACH_EXPORTER_LOCAL_CACHE_DIR")
      unlink(local_cache, recursive = TRUE)
    },
    add = TRUE
  )

  library_dir <- env$be_launcher_use_local_library()

  expect_true(dir.exists(library_dir))
  expect_true(startsWith(library_dir, local_cache))
  expect_equal(.libPaths()[[1]], library_dir)
})

test_that("launcher tempdir readiness checks for user-local tmp roots", {
  local_cache <- tempfile("launcher-cache-")
  dir.create(local_cache, recursive = TRUE, showWarnings = FALSE)
  Sys.setenv(BACH_EXPORTER_LOCAL_CACHE_DIR = local_cache)
  on.exit(
    {
      Sys.unsetenv("BACH_EXPORTER_LOCAL_CACHE_DIR")
      unlink(local_cache, recursive = TRUE)
    },
    add = TRUE
  )

  expected <- normalizePath(
    file.path(local_cache, "tmp"),
    winslash = "/",
    mustWork = FALSE
  )

  expect_true(
    env$be_launcher_tempdir_ready(
      current_tempdir = file.path(expected, "Rtmp123")
    )
  )
  expect_false(
    env$be_launcher_tempdir_ready(
      current_tempdir = "/tmp/Rtmp123"
    )
  )
})

test_that("launcher tempdir cleanup preparation makes session assets writable", {
  temp_root <- tempfile("launcher-tempdir-cleanup-")
  session_dir <- file.path(temp_root, "Rtmp123")
  asset_dir <- file.path(session_dir, "bslib-asset", "fonts")
  dir.create(asset_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(temp_root, recursive = TRUE), add = TRUE)

  asset_file <- file.path(asset_dir, "glyphicons-halflings-regular.woff")
  writeLines("asset", asset_file)
  Sys.chmod(
    c(session_dir, asset_dir, asset_file),
    mode = "555",
    use_umask = FALSE
  )

  env$be_launcher_prepare_tempdir_cleanup(current_tempdir = session_dir)

  expect_equal(unname(file.access(asset_file, 2)), 0)
})

test_that("launcher re-execs itself with user-local tmpdir when needed", {
  local_cache <- tempfile("launcher-cache-")
  dir.create(local_cache, recursive = TRUE, showWarnings = FALSE)
  Sys.setenv(BACH_EXPORTER_LOCAL_CACHE_DIR = local_cache)
  on.exit(
    {
      Sys.unsetenv("BACH_EXPORTER_LOCAL_CACHE_DIR")
      unlink(local_cache, recursive = TRUE)
    },
    add = TRUE
  )
  launcher_path <- normalizePath(
    file.path("..", "..", "launch_bach_exporter.R"),
    winslash = "/",
    mustWork = TRUE
  )

  calls <- list()
  status <- env$be_launcher_reexec_status(
    command_args = sprintf("--file=%s", launcher_path),
    trailing_args = c("--example", "value"),
    current_tempdir = "/tmp/Rtmp123",
    system2_runner = function(command, args, env, wait) {
      calls[[length(calls) + 1]] <<- list(
        command = command,
        args = args,
        env = env,
        wait = wait
      )
      0L
    }
  )

  expected <- normalizePath(
    file.path(local_cache, "tmp"),
    winslash = "/",
    mustWork = FALSE
  )

  expect_equal(status, 0L)
  expect_length(calls, 1)
  expect_match(calls[[1]]$command, "Rscript$")
  expect_equal(
    calls[[1]]$args,
    c(launcher_path, "--example", "value")
  )
  expect_true(calls[[1]]$wait)
  expect_equal(
    calls[[1]]$env,
    c(
      sprintf("TMPDIR=%s", expected),
      sprintf("TMP=%s", expected),
      sprintf("TEMP=%s", expected)
    )
  )
})

test_that("launcher resolves script path from RStudio active document fallback", {
  launcher_path <- normalizePath(
    file.path("..", "..", "launch_bach_exporter.R"),
    winslash = "/",
    mustWork = TRUE
  )

  expect_equal(
    env$be_launcher_script_path(
      command_args = character(),
      active_document_path = launcher_path,
      source_frames = list()
    ),
    launcher_path
  )
})

test_that("launcher resolves script path from source metadata", {
  launcher_path <- normalizePath(
    file.path("..", "..", "launch_bach_exporter.R"),
    winslash = "/",
    mustWork = TRUE
  )
  source_frame <- new.env(parent = emptyenv())
  source_frame$ofile <- launcher_path

  expect_equal(
    env$be_launcher_script_path(
      command_args = character(),
      source_frames = list(source_frame),
      install_rstudioapi = FALSE
    ),
    launcher_path
  )
})

test_that("launcher resolves script path from rig script arguments", {
  launcher_path <- normalizePath(
    file.path("..", "..", "launch_bach_exporter.R"),
    winslash = "/",
    mustWork = TRUE
  )

  expect_equal(
    env$be_launcher_script_path(
      command_args = c("R", "-f", launcher_path),
      source_frames = list(),
      install_rstudioapi = FALSE
    ),
    launcher_path
  )
  expect_equal(
    env$be_launcher_script_path(
      command_args = c("R", "--script", launcher_path),
      source_frames = list(),
      install_rstudioapi = FALSE
    ),
    launcher_path
  )
  expect_equal(
    env$be_launcher_script_path(
      command_args = c("R", paste0("--script=", launcher_path)),
      source_frames = list(),
      install_rstudioapi = FALSE
    ),
    launcher_path
  )
})

test_that("launcher resolves script path from launcher environment fallback", {
  launcher_path <- normalizePath(
    file.path("..", "..", "launch_bach_exporter.R"),
    winslash = "/",
    mustWork = TRUE
  )

  Sys.setenv(BACH_EXPORTER_LAUNCHER = launcher_path)
  on.exit(Sys.unsetenv("BACH_EXPORTER_LAUNCHER"), add = TRUE)

  expect_equal(
    env$be_launcher_script_path(
      command_args = character(),
      source_frames = list(),
      install_rstudioapi = FALSE
    ),
    launcher_path
  )
})

test_that("launcher accepts matching R major/minor versions", {
  expect_true(env$be_launcher_r_version_compatible("4.5.1", "4.5.1"))
  expect_true(env$be_launcher_r_version_compatible("4.5.1", "4.5.2"))
  expect_false(env$be_launcher_r_version_compatible("4.5.1", "4.6.0"))
})

test_that("launcher installs rstudioapi when needed for active document fallback", {
  launcher_path <- normalizePath(
    file.path("..", "..", "launch_bach_exporter.R"),
    winslash = "/",
    mustWork = TRUE
  )
  installed <- FALSE
  installs <- list()

  result <- env$be_launcher_rstudio_document_path(
    install_rstudioapi = TRUE,
    install_package_runner = function(pkgs, repos) {
      installs[[length(installs) + 1]] <<- list(pkgs = pkgs, repos = repos)
      installed <<- TRUE
    },
    rstudioapi_available = function() installed,
    rstudioapi_is_available = function() TRUE,
    rstudioapi_path_reader = function() launcher_path
  )

  expect_equal(result, launcher_path)
  expect_length(installs, 1)
  expect_equal(installs[[1]]$pkgs, "rstudioapi")
  expect_equal(installs[[1]]$repos, env$be_launcher_package_repos())
})

test_that("launcher configures Posit Package Manager for dependency installs", {
  old_repos <- getOption("repos")
  old_override <- getOption("renv.config.repos.override")
  old_pkg_type <- getOption("pkgType")
  old_env <- Sys.getenv("RENV_CONFIG_REPOS_OVERRIDE", unset = NA)
  on.exit(
    {
      options(
        repos = old_repos,
        renv.config.repos.override = old_override,
        pkgType = old_pkg_type
      )
      if (is.na(old_env)) {
        Sys.unsetenv("RENV_CONFIG_REPOS_OVERRIDE")
      } else {
        Sys.setenv(RENV_CONFIG_REPOS_OVERRIDE = old_env)
      }
    },
    add = TRUE
  )

  repos <- env$be_launcher_configure_package_repos()

  expect_equal(repos, c(CRAN = "https://packagemanager.posit.co/cran/latest"))
  expect_equal(getOption("repos"), repos)
  expect_equal(getOption("renv.config.repos.override"), repos)
  expect_equal(
    Sys.getenv("RENV_CONFIG_REPOS_OVERRIDE"),
    unname(repos[["CRAN"]])
  )
})

test_that("launcher uses its own directory as the default shared root", {
  launcher_path <- normalizePath(
    file.path("..", "..", "launch_bach_exporter.R"),
    winslash = "/",
    mustWork = TRUE
  )

  expect_equal(
    env$be_launcher_default_shared_root(
      command_args = character(),
      active_document_path = launcher_path,
      source_frames = list()
    ),
    dirname(launcher_path)
  )
})

test_that("launcher uses parent shared root when installed under launcher dir", {
  shared_root <- tempfile("launcher-shared-root-")
  launcher_dir <- file.path(shared_root, "launcher")
  dir.create(file.path(shared_root, "app"), recursive = TRUE)
  dir.create(launcher_dir, recursive = TRUE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  launcher_path <- file.path(launcher_dir, "launch_bach_exporter.R")
  file.create(launcher_path)

  expect_equal(
    env$be_launcher_default_shared_root(
      command_args = character(),
      active_document_path = launcher_path,
      source_frames = list()
    ),
    shared_root
  )
})

test_that("launcher re-exec can use RStudio active document path", {
  local_cache <- tempfile("launcher-cache-")
  dir.create(local_cache, recursive = TRUE, showWarnings = FALSE)
  Sys.setenv(BACH_EXPORTER_LOCAL_CACHE_DIR = local_cache)
  on.exit(
    {
      Sys.unsetenv("BACH_EXPORTER_LOCAL_CACHE_DIR")
      unlink(local_cache, recursive = TRUE)
    },
    add = TRUE
  )
  launcher_path <- normalizePath(
    file.path("..", "..", "launch_bach_exporter.R"),
    winslash = "/",
    mustWork = TRUE
  )

  calls <- list()
  status <- env$be_launcher_reexec_status(
    command_args = character(),
    trailing_args = character(),
    current_tempdir = "/tmp/Rtmp123",
    active_document_path = launcher_path,
    source_frames = list(),
    system2_runner = function(command, args, env, wait) {
      calls[[length(calls) + 1]] <<- list(
        command = command,
        args = args,
        env = env,
        wait = wait
      )
      0L
    }
  )

  expect_equal(status, 0L)
  expect_length(calls, 1)
  expect_equal(calls[[1]]$args, launcher_path)
})

test_that("launcher stays in process for interactive and RStudio sessions", {
  expect_false(env$be_launcher_should_reexec(interactive_session = TRUE))
  expect_false(env$be_launcher_should_reexec(
    interactive_session = FALSE,
    running_in_rstudio = TRUE
  ))
  expect_true(env$be_launcher_should_reexec(
    interactive_session = FALSE,
    running_in_rstudio = FALSE
  ))
})

test_that("launcher skips re-exec when tempdir is already user-local", {
  local_cache <- tempfile("launcher-cache-")
  dir.create(local_cache, recursive = TRUE, showWarnings = FALSE)
  Sys.setenv(BACH_EXPORTER_LOCAL_CACHE_DIR = local_cache)
  on.exit(
    {
      Sys.unsetenv("BACH_EXPORTER_LOCAL_CACHE_DIR")
      unlink(local_cache, recursive = TRUE)
    },
    add = TRUE
  )

  expected <- normalizePath(
    file.path(local_cache, "tmp", "Rtmp123"),
    winslash = "/",
    mustWork = FALSE
  )

  expect_null(
    env$be_launcher_reexec_status(
      current_tempdir = expected
    )
  )
})

test_that("launcher temp root stays outside the repo workdir", {
  local_cache <- tempfile("launcher-cache-")
  workdir <- tempfile("launcher-workdir-")
  dir.create(local_cache, recursive = TRUE, showWarnings = FALSE)
  dir.create(workdir, recursive = TRUE, showWarnings = FALSE)
  Sys.setenv(BACH_EXPORTER_LOCAL_CACHE_DIR = local_cache)
  on.exit(
    {
      Sys.unsetenv("BACH_EXPORTER_LOCAL_CACHE_DIR")
      unlink(local_cache, recursive = TRUE)
      unlink(workdir, recursive = TRUE)
    },
    add = TRUE
  )

  tmp_root <- env$be_launcher_tmp_dir()
  normalized_workdir <- normalizePath(workdir, winslash = "/", mustWork = FALSE)

  expect_false(startsWith(tmp_root, paste0(normalized_workdir, "/")))
})

test_that("launcher bootstrap validation uses canonical release contract", {
  shared_root <- make_launcher_packaged_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  result <- env$be_launcher_validate_shared_root(
    shared_root,
    allow_dev = FALSE
  )

  expect_true(result$ok)
  expect_equal(result$paths$build_id, "build-20260311")
  expect_match(result$message, "Release contract is valid")
})

test_that("launcher bootstrap rejects published apps without manifest", {
  shared_root <- make_launcher_packaged_shared_root()
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)
  unlink(file.path(shared_root, "app", "manifest.json"))

  result <- env$be_launcher_validate_shared_root(
    shared_root,
    allow_dev = FALSE
  )

  expect_false(result$ok)
  expect_match(result$message, "manifest is missing a build_id")
})
