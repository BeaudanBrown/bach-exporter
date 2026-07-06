ui_env <- new.env(parent = globalenv())
sys.source(file.path("..", "..", "R", "domain_choices.R"), envir = ui_env)
sys.source(file.path("..", "..", "R", "app_ui.R"), envir = ui_env)

test_that("main app keeps configuration-only controls out of the UI", {
  ui_html <- paste(as.character(ui_env$be_app_ui()), collapse = "\n")

  expect_match(ui_html, "Years")
  expect_false(grepl("Export preset", ui_html, fixed = TRUE))
  expect_false(grepl(">Logs<", ui_html, fixed = TRUE))
  expect_false(grepl("live_log", ui_html, fixed = TRUE))
  expect_false(grepl("shared_root", ui_html, fixed = TRUE))
  expect_false(grepl("browse_shared_root", ui_html, fixed = TRUE))
  expect_false(grepl("save_shared_root", ui_html, fixed = TRUE))
  expect_false(grepl("subset_file", ui_html, fixed = TRUE))
  expect_false(grepl(">Status<", ui_html, fixed = TRUE))
  expect_false(grepl(">History<", ui_html, fixed = TRUE))
  expect_false(grepl(">Presets<", ui_html, fixed = TRUE))
  expect_false(grepl(">Shared Root<", ui_html, fixed = TRUE))
  expect_false(grepl("refresh_mode", ui_html, fixed = TRUE))
})

test_that("domain choices include DAS and MFI questionnaires", {
  choices <- ui_env$be_domain_choices()

  expect_equal(unname(choices["DAS"]), "das")
  expect_equal(unname(choices["Informant DAS"]), "informant_das")
  expect_equal(unname(choices["MFI"]), "mfi")
})
