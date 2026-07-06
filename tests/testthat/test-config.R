source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "config.R"))

test_that("targets cache path includes running code identity", {
  cache_dir <- tempfile("bach-cache-")
  old_cache_option <- getOption("bachExporter.local_cache_dir")
  options(bachExporter.local_cache_dir = cache_dir)
  on.exit(
    options(bachExporter.local_cache_dir = old_cache_option),
    add = TRUE
  )

  targets_dir <- be_local_targets_dir(
    build_id = "build-a",
    shared_root = "/tmp/shared-root"
  )

  expect_match(targets_dir, "/targets/code-", fixed = TRUE)
  expect_match(targets_dir, "/build-a/root-", fixed = FALSE)
})

test_that("shared root config falls back to admin config and stays in sync", {
  config_dir <- tempfile("bach-config-")
  old_config_option <- getOption("bachExporter.local_config_dir")
  options(bachExporter.local_config_dir = config_dir)
  on.exit(
    options(bachExporter.local_config_dir = old_config_option),
    add = TRUE
  )

  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)

  jsonlite::write_json(
    list(shared_root = "/tmp/admin-root"),
    file.path(config_dir, "admin-refresh.json"),
    auto_unbox = TRUE,
    pretty = TRUE
  )

  expect_equal(be_load_shared_root(), "/tmp/admin-root")

  be_save_shared_root("/tmp/researcher-root")

  shared_config <- jsonlite::read_json(
    file.path(config_dir, "shared-root.json"),
    simplifyVector = TRUE
  )
  admin_config <- jsonlite::read_json(
    file.path(config_dir, "admin-refresh.json"),
    simplifyVector = TRUE
  )

  expect_equal(shared_config$shared_root, "/tmp/researcher-root")
  expect_equal(admin_config$shared_root, "/tmp/researcher-root")
})
