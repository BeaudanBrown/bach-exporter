source(file.path("..", "..", "R", "app_server.R"))

test_that("app server uses exported shinyFiles save helper", {
  server_body <- paste(deparse(body(be_app_server())), collapse = "\n")

  expect_true(is.function(shinyFiles::shinyFileSave))
  expect_match(server_body, "shinyFiles::shinyFileSave")
  expect_false(grepl("shinyFiles::shinySaveFile", server_body, fixed = TRUE))
})
