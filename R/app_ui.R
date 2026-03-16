be_app_ui <- function() {
  shiny::fluidPage(
    theme = bslib::bs_theme(version = 5, bootswatch = "minty"),
    shiny::tags$head(
      shiny::tags$style(
        shiny::HTML(
          ".app-shell { max-width: 1200px; margin: 24px auto; }
           .app-note { color: #495057; }"
        )
      )
    ),
    shiny::div(
      class = "app-shell",
      shiny::titlePanel("BACH Exporter"),
      shiny::p(
        class = "app-note",
        "Shared-drive launched export tool. This build supports participants plus the first migrated screening and annual-phone slices from shared REDCap snapshots."
      ),
      shiny::tabsetPanel(
        shiny::tabPanel(
          "Export",
          shiny::fluidRow(
            shiny::column(
              width = 6,
              shiny::selectInput(
                "years",
                "Years",
                choices = c("baseline", "year2", "year3"),
                multiple = TRUE,
                selected = "baseline"
              ),
              shiny::checkboxGroupInput(
                "domains",
                "Domains",
                choices = c(
                  "Participants" = "participants",
                  "Participant Screening" = "participant_screening",
                  "MRI Screening" = "mri_screening",
                  "LP Screening" = "lp_screening",
                  "MoCA" = "moca",
                  "AD8" = "ad8",
                  "UCLA Loneliness" = "ucla",
                  "Demographics" = "demographics",
                  "CES-D" = "cesd",
                  "STAI" = "stai",
                  "PSS" = "pss",
                  "CD-RISC" = "cdrisc",
                  "SES" = "ses",
                  "ARIA" = "aria",
                  "IPAQ" = "ipaq",
                  "RHHI" = "rhhi",
                  "MIND Diet" = "minddiet",
                  "Alcohol Questionnaire" = "alcohol",
                  "CFI" = "cfi",
                  "Global Health" = "global_health",
                  "Bloods / Pathology" = "bloods",
                  "Vitals" = "vitals",
                  "24h Blood Pressure" = "bp24h",
                  "Similarities" = "similarities",
                  "Prose Passages" = "prose_passages",
                  "Cognitive Screening" = "cognitive_screening",
                  "Medications" = "medications"
                ),
                selected = "participants"
              ),
              shiny::radioButtons(
                "cat_labels",
                "Categorical labels",
                choices = c("named", "numbered"),
                selected = "named"
              ),
              shiny::textAreaInput(
                "participant_ids",
                "Participant IDs",
                value = "",
                placeholder = "Optional. Enter BACH001, 002, etc. separated by commas or new lines.",
                rows = 4
              ),
              shiny::textInput(
                "subset_file",
                "Subset file path",
                value = "",
                placeholder = "Optional text file with one participant ID per line."
              )
            ),
            shiny::column(
              width = 6,
              shiny::textInput("output_path", "Output CSV path", value = ""),
              shinyFiles::shinySaveButton(
                "browse_output",
                "Browse",
                "Choose output file",
                filetype = list(csv = "csv")
              ),
              shiny::selectInput(
                "refresh_mode",
                "Refresh mode",
                choices = c("auto", "use_cache", "force"),
                selected = "auto"
              ),
              shiny::actionButton("run_export_btn", "Run export")
            )
          )
        ),
        shiny::tabPanel(
          "Presets",
          shiny::selectInput(
            "preset",
            "Preset",
            choices = names(be_default_presets())
          ),
          shiny::verbatimTextOutput("preset_detail")
        ),
        shiny::tabPanel(
          "Settings",
          shiny::textInput("shared_root", "Shared folder root", value = ""),
          shinyFiles::shinyDirButton(
            "browse_shared_root",
            "Browse",
            "Choose shared folder"
          ),
          shiny::actionButton("save_shared_root", "Save shared root"),
          shiny::hr(),
          shiny::p(
            class = "app-note",
            "Researcher sessions use shared snapshots only. REDCap refresh configuration stays in the admin workflow."
          )
        ),
        shiny::tabPanel(
          "Status",
          shiny::verbatimTextOutput("status_log")
        )
      )
    )
  )
}
