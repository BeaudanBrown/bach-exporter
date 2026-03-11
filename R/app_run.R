run_app <- function(shared_root = NULL) {
  shiny::shinyApp(
    ui = be_app_ui(),
    server = be_app_server(shared_root = shared_root)
  )
}
