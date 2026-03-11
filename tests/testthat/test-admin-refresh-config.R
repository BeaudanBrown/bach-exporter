source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "source_refresh_admin.R"))

test_that("admin refresh config reads local config json", {
  config_dir <- tempfile("admin-config-dir-")
  dir.create(config_dir, recursive = TRUE)
  on.exit(unlink(config_dir, recursive = TRUE), add = TRUE)

  config_path <- file.path(config_dir, "admin-refresh.json")
  jsonlite::write_json(
    list(
      shared_root = "/tmp/shared-root",
      redcap_url = "https://redcap.example.org/api/",
      api_key = "token-123",
      schema_snapshot_only = TRUE
    ),
    config_path,
    auto_unbox = TRUE
  )

  config <- be_admin_refresh_config(config_path = config_path)
  validation <- be_validate_admin_refresh_config(config)
  plan <- be_admin_refresh_plan(config)

  expect_true(validation$ok)
  expect_equal(config$shared_root, "/tmp/shared-root")
  expect_equal(config$api_key, "token-123")
  expect_true(config$schema_snapshot_only)
  expect_equal(
    plan$snapshot_paths$metadata,
    file.path(
      "/tmp/shared-root",
      "snapshots",
      "redcap",
      "schema",
      "metadata.json"
    )
  )
})

test_that("admin refresh config fails clearly when api key is missing", {
  config <- list(
    config_path = "/tmp/admin-refresh.json",
    shared_root = "/tmp/shared-root",
    redcap_url = "https://redcap.example.org/api/",
    api_key = "REPLACE_WITH_ADMIN_TOKEN"
  )

  validation <- be_validate_admin_refresh_config(config)

  expect_false(validation$ok)
  expect_match(validation$message, "api_key is not configured")
})
