source(file.path("..", "..", "R", "paths.R"))
source(file.path("..", "..", "R", "release_runtime.R"))

make_release_root <- function() {
  release_root <- tempfile("release-root-")
  dir.create(release_root, recursive = TRUE)
  release_root
}

test_that("manifest validation succeeds for matching release metadata", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c(
      "Package: bachExporter",
      "Version: 0.0.1"
    ),
    file.path(release_root, "DESCRIPTION")
  )
  jsonlite::write_json(
    list(
      release_id = "2026-03-11",
      package = list(name = "bachExporter", version = "0.0.1")
    ),
    path = file.path(release_root, "manifest.json"),
    auto_unbox = TRUE
  )

  result <- be_validate_release_manifest(
    release_root,
    release_id = "2026-03-11"
  )

  expect_true(result$ok)
  expect_equal(result$package$package, "bachExporter")
  expect_equal(result$package$version, "0.0.1")
})

test_that("manifest validation rejects published releases without manifest", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c(
      "Package: bachExporter",
      "Version: 0.0.1"
    ),
    file.path(release_root, "DESCRIPTION")
  )

  result <- be_validate_release_manifest(
    release_root,
    release_id = "2026-03-11"
  )

  expect_false(result$ok)
  expect_match(result$message, "manifest is missing")
})

test_that("manifest validation allows missing dev manifest", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c(
      "Package: bachExporter",
      "Version: 0.0.1"
    ),
    file.path(release_root, "DESCRIPTION")
  )

  result <- be_validate_release_manifest(release_root, release_id = "dev")

  expect_true(result$ok)
  expect_null(result$manifest)
})

test_that("manifest validation catches package mismatch", {
  release_root <- make_release_root()
  on.exit(unlink(release_root, recursive = TRUE), add = TRUE)

  writeLines(
    c(
      "Package: bachExporter",
      "Version: 0.0.1"
    ),
    file.path(release_root, "DESCRIPTION")
  )
  jsonlite::write_json(
    list(
      release_id = "2026-03-11",
      package = list(name = "otherPkg", version = "0.0.1")
    ),
    path = file.path(release_root, "manifest.json"),
    auto_unbox = TRUE
  )

  result <- be_validate_release_manifest(
    release_root,
    release_id = "2026-03-11"
  )

  expect_false(result$ok)
  expect_match(result$message, "does not match DESCRIPTION package")
})
