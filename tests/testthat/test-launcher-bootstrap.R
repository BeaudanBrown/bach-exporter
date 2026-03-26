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
