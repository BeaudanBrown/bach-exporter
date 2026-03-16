env <- new.env(parent = baseenv())
sys.source(file.path("..", "..", "launch_bach_exporter.R"), envir = env)

test_that("launcher status text is always length-one character output", {
  expect_equal(env$be_launcher_status_text(NULL), "")
  expect_equal(env$be_launcher_status_text("ok"), "ok")
  expect_equal(
    env$be_launcher_status_text(c("line one", "line two")),
    "line one\nline two"
  )
  expect_length(env$be_launcher_status_text(c("a", "b", "c")), 1)
})
