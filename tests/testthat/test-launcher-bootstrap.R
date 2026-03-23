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

test_that("launcher temp dir is repo-local and exported to the session", {
  workdir <- tempfile("launcher-workdir-")
  dir.create(workdir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(workdir, recursive = TRUE), add = TRUE)

  old_env <- Sys.getenv(c("TMPDIR", "TMP", "TEMP"), unset = NA_character_)
  on.exit(
    {
      for (env_name in names(old_env)) {
        env_value <- old_env[[env_name]]
        if (is.na(env_value)) {
          Sys.unsetenv(env_name)
        } else {
          do.call(Sys.setenv, stats::setNames(list(env_value), env_name))
        }
      }
    },
    add = TRUE
  )

  path <- env$be_launcher_use_tmp_dir(workdir = workdir)
  expected <- normalizePath(
    file.path(workdir, ".cache", "tmp"),
    winslash = "/",
    mustWork = FALSE
  )

  expect_true(dir.exists(path))
  expect_equal(path, expected)
  expect_equal(Sys.getenv("TMPDIR"), expected)
  expect_equal(Sys.getenv("TMP"), expected)
  expect_equal(Sys.getenv("TEMP"), expected)
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
