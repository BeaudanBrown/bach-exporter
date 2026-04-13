ui_env <- new.env(parent = globalenv())
sys.source(file.path("..", "..", "R", "domain_choices.R"), envir = ui_env)
sys.source(file.path("..", "..", "R", "app_ui.R"), envir = ui_env)

test_that("main app tabs keep shared root on export page", {
  ui_html <- paste(as.character(ui_env$be_app_ui()), collapse = "\n")

  expect_match(ui_html, "Export")
  expect_match(ui_html, "Status")
  expect_match(ui_html, "History")
  expect_match(ui_html, "shared_root")
  expect_match(ui_html, "browse_shared_root")
  expect_match(ui_html, "save_shared_root")
  expect_false(grepl(">Presets<", ui_html, fixed = TRUE))
  expect_false(grepl(">Shared Root<", ui_html, fixed = TRUE))
  expect_false(grepl("preset_detail", ui_html, fixed = TRUE))
})
