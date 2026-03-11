launch_bach_exporter <- function() {
  ensure_bootstrap_package <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }
  }

  bootstrap_packages <- c(
    "shiny",
    "shinyFiles",
    "jsonlite",
    "bslib",
    "renv",
    "remotes"
  )
  invisible(lapply(bootstrap_packages, ensure_bootstrap_package))

  config_dir <- tools::R_user_dir("bachExporter", which = "config")
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  config_path <- file.path(config_dir, "shared-root.json")

  `%||%` <- function(x, y) {
    if (is.null(x)) y else x
  }

  load_shared_root <- function() {
    if (!file.exists(config_path)) {
      return(NULL)
    }
    config <- jsonlite::read_json(config_path, simplifyVector = TRUE)
    root <- config$shared_root %||% NULL
    if (is.null(root) || !nzchar(root)) {
      return(NULL)
    }
    root
  }

  save_shared_root <- function(shared_root) {
    jsonlite::write_json(
      list(
        shared_root = normalizePath(
          shared_root,
          winslash = "/",
          mustWork = FALSE
        )
      ),
      path = config_path,
      auto_unbox = TRUE,
      pretty = TRUE
    )
  }

  validate_shared_root <- function(shared_root) {
    if (is.null(shared_root) || !nzchar(shared_root)) {
      return(list(ok = FALSE, message = "Shared root path is empty."))
    }
    if (!dir.exists(shared_root)) {
      return(list(
        ok = FALSE,
        message = "Shared root directory does not exist."
      ))
    }

    release_file <- file.path(shared_root, "CURRENT_RELEASE.txt")
    if (file.exists(release_file)) {
      release_id <- trimws(readLines(release_file, warn = FALSE, n = 1))
      if (!nzchar(release_id)) {
        return(list(ok = FALSE, message = "CURRENT_RELEASE.txt is empty."))
      }
      launcher <- file.path(
        shared_root,
        "releases",
        release_id,
        "scripts",
        "launch_from_share.R"
      )
    } else if (
      file.exists(file.path(shared_root, "DESCRIPTION")) &&
        file.exists(file.path(shared_root, "scripts", "launch_from_share.R"))
    ) {
      release_id <- "dev"
      launcher <- file.path(shared_root, "scripts", "launch_from_share.R")
    } else {
      return(list(
        ok = FALSE,
        message = "Shared root is missing CURRENT_RELEASE.txt and does not look like a direct release root."
      ))
    }

    if (!file.exists(launcher)) {
      return(list(ok = FALSE, message = "Shared release launcher is missing."))
    }

    list(
      ok = TRUE,
      shared_root = shared_root,
      release_id = release_id,
      launcher = launcher
    )
  }

  launch_bootstrap <- function(initial_root = NULL) {
    ui <- shiny::fluidPage(
      bslib::bs_theme(version = 5, bootswatch = "flatly"),
      shiny::div(
        style = "max-width: 840px; margin: 40px auto;",
        shiny::h2("Locate Shared BACH Exporter Folder"),
        shiny::textInput(
          "shared_root",
          "Shared folder root",
          value = initial_root %||% ""
        ),
        shinyFiles::shinyDirButton(
          "browse_root",
          "Browse",
          "Choose shared folder"
        ),
        shiny::br(),
        shiny::br(),
        shiny::actionButton("validate_root", "Validate"),
        shiny::actionButton("continue_root", "Continue"),
        shiny::hr(),
        shiny::verbatimTextOutput("status")
      )
    )

    server <- function(input, output, session) {
      roots <- if (.Platform$OS.type == "windows") {
        shinyFiles::getVolumes()()
      } else {
        c(
          Home = normalizePath("~", winslash = "/", mustWork = FALSE),
          Root = "/"
        )
      }
      shinyFiles::shinyDirChoose(
        input,
        "browse_root",
        roots = roots,
        session = session
      )

      shiny::observeEvent(input$browse_root, {
        selected <- shinyFiles::parseDirPath(roots, input$browse_root)
        if (length(selected) == 1 && nzchar(selected)) {
          shiny::updateTextInput(session, "shared_root", value = selected)
        }
      })

      current_status <- shiny::reactiveVal(
        "Choose the shared root and validate it."
      )

      shiny::observeEvent(input$validate_root, {
        result <- validate_shared_root(input$shared_root)
        current_status(result$message)
        if (isTRUE(result$ok)) {
          save_shared_root(result$shared_root)
        }
      })

      shiny::observeEvent(input$continue_root, {
        result <- validate_shared_root(input$shared_root)
        if (!isTRUE(result$ok)) {
          current_status(result$message)
          return()
        }
        save_shared_root(result$shared_root)
        shiny::stopApp(result)
      })

      output$status <- shiny::renderText(current_status())
    }

    shiny::runApp(shiny::shinyApp(ui, server))
  }

  shared_root <- load_shared_root()
  validation <- validate_shared_root(shared_root %||% "")
  if (!isTRUE(validation$ok)) {
    validation <- launch_bootstrap(shared_root)
  }
  if (is.null(validation) || !isTRUE(validation$ok)) {
    stop("No valid shared root was selected.", call. = FALSE)
  }

  source(validation$launcher, local = TRUE)
  launch_from_share(validation$shared_root)
}

launch_bach_exporter()
