source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "release_runtime.R"))
source(file.path("..", "..", "R", "source_refresh_admin.R"))
source(file.path("..", "..", "R", "release_management.R"))

test_that("stage_shared_app stages a valid shared app bundle", {
  repo_root <- normalizePath(
    file.path("..", ".."),
    winslash = "/",
    mustWork = TRUE
  )
  output_root <- tempfile("prepared-app-root-")
  on.exit(unlink(output_root, recursive = TRUE), add = TRUE)

  result <- be_stage_shared_app(
    output_root = output_root,
    repo_root = repo_root,
    build_id = "build-20260321",
    built_at = as.POSIXct("2026-03-21 02:00:00", tz = "UTC")
  )

  manifest <- jsonlite::read_json(
    file.path(output_root, "app", "manifest.json"),
    simplifyVector = TRUE
  )

  expect_true(file.exists(file.path(
    output_root,
    "app",
    "scripts",
    "refresh_snapshots.R"
  )))
  expect_true(file.exists(file.path(output_root, "side-data", "absdf.csv")))
  expect_true(result$validation$ok)
  expect_equal(manifest$build_id, "build-20260321")
  expect_equal(manifest$package$name, "bachExporter")
  expect_equal(manifest$built_at, "2026-03-21T02:00:00Z")
})

test_that("publish_shared_app deploys the staged app to the fixed app directory", {
  repo_root <- normalizePath(
    file.path("..", ".."),
    winslash = "/",
    mustWork = TRUE
  )
  staged_root <- tempfile("staged-app-root-")
  shared_root <- tempfile("published-app-root-")
  dir.create(shared_root, recursive = TRUE)
  on.exit(unlink(staged_root, recursive = TRUE), add = TRUE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)

  be_stage_shared_app(
    output_root = staged_root,
    repo_root = repo_root,
    build_id = "build-20260321",
    built_at = as.POSIXct("2026-03-21 02:10:00", tz = "UTC")
  )

  result <- be_publish_shared_app(
    staged_root = staged_root,
    shared_root = shared_root
  )

  expect_equal(result$build_id, "build-20260321")
  expect_true(result$validation$ok)
  expect_true(file.exists(file.path(
    shared_root,
    "app",
    "scripts",
    "refresh_snapshots.R"
  )))
  expect_true(file.exists(file.path(
    shared_root,
    "side-data",
    "RA_2016_AUST.csv"
  )))
})

test_that("publish_shared_app reports the previous build id when overwriting", {
  repo_root <- normalizePath(
    file.path("..", ".."),
    winslash = "/",
    mustWork = TRUE
  )
  shared_root <- tempfile("overwrite-app-root-")
  stage_a <- tempfile("stage-app-a-")
  stage_b <- tempfile("stage-app-b-")
  dir.create(shared_root, recursive = TRUE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)
  on.exit(unlink(stage_a, recursive = TRUE), add = TRUE)
  on.exit(unlink(stage_b, recursive = TRUE), add = TRUE)

  be_stage_shared_app(
    output_root = stage_a,
    repo_root = repo_root,
    build_id = "build-a"
  )
  be_stage_shared_app(
    output_root = stage_b,
    repo_root = repo_root,
    build_id = "build-b"
  )

  be_publish_shared_app(stage_a, shared_root = shared_root)
  result <- be_publish_shared_app(stage_b, shared_root = shared_root)

  expect_equal(result$previous_build_id, "build-a")
  expect_equal(result$build_id, "build-b")
})

test_that("admin shared root persistence updates admin refresh config", {
  config_path <- tempfile("admin-refresh-config-")
  shared_root <- tempfile("admin-shared-root-")
  dir.create(shared_root, recursive = TRUE)
  on.exit(unlink(shared_root, recursive = TRUE), add = TRUE)
  on.exit(unlink(config_path, recursive = TRUE, force = TRUE), add = TRUE)

  jsonlite::write_json(
    list(project_alias = "bach-exporter"),
    path = config_path,
    auto_unbox = TRUE
  )

  be_write_admin_refresh_config(
    shared_root = shared_root,
    config_path = config_path
  )
  config <- be_admin_refresh_config(config_path = config_path)

  expect_equal(
    config$shared_root,
    normalizePath(shared_root, winslash = "/", mustWork = FALSE)
  )
  expect_equal(config$project_alias, "bach-exporter")
})
