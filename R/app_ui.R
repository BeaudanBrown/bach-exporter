be_app_ui <- function() {
  shiny::fluidPage(
    theme = bslib::bs_theme(version = 5, bootswatch = "minty"),
    shiny::tags$head(
      shiny::tags$style(
        shiny::HTML(
          ".app-shell { max-width: 1200px; margin: 24px auto; }
           .app-note { color: #495057; }
           .busy-banner {
             margin-top: 12px;
             padding: 12px 14px;
             border-radius: 10px;
             background: #e3f6ea;
             border: 1px solid #9fd5b3;
             color: #184b2e;
             display: flex;
             align-items: center;
             gap: 10px;
             font-weight: 600;
           }
           .busy-banner__spinner {
             width: 14px;
             height: 14px;
             border-radius: 999px;
             border: 2px solid rgba(24, 75, 46, 0.25);
             border-top-color: #184b2e;
             animation: be-spin 0.8s linear infinite;
             flex: 0 0 auto;
           }
           @keyframes be-spin {
             from { transform: rotate(0deg); }
             to { transform: rotate(360deg); }
           }"
        )
      ),
      shiny::tags$script(
        shiny::HTML(
          "Shiny.addCustomMessageHandler('be-set-button-state', function(message) {
             var el = document.getElementById(message.id);
             if (!el) return;
             el.disabled = !!message.disabled;
             if (message.label) {
               el.textContent = message.label;
             }
           });"
        )
      )
    ),
    shiny::div(
      class = "app-shell",
      shiny::titlePanel("BACH Exporter"),
      shiny::p(
        class = "app-note",
        "Shared-drive launched export tool. This build supports screening, annual-phone, clinical, neuropsych, sleep, and the first imaging slices from shared REDCap snapshots."
      ),
      shiny::p(
        class = "app-note",
        "Researcher exports read shared snapshots only. REDCap connection and refresh settings stay in the admin workflow."
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
                  "MRI" = "mri",
                  "LP Screening" = "lp_screening",
                  "Lumbar Puncture" = "lp",
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
                  "Medical History" = "medical_history",
                  "CDR" = "cdr",
                  "MMSE" = "mmse",
                  "SYDBAT" = "sydbat",
                  "Logical Memory" = "logical_memory",
                  "Visual Reproduction" = "visual_reproduction",
                  "Trail Making Test" = "tmt",
                  "Frontal Assessment Battery" = "fab",
                  "COWAT" = "cowat",
                  "HVOT" = "hvot",
                  "TASIT" = "tasit",
                  "TOPF" = "topf",
                  "Dementia Status" = "dementia_status",
                  "PSQI" = "psqi",
                  "ESS" = "ess",
                  "ISI" = "isi",
                  "PSG Screening" = "psg_screening",
                  "PSG Sleep Health" = "psg_sleephealth",
                  "PSG Sleep Medications" = "psg_sleepmed",
                  "PSG Morning Questionnaire" = "psg_morningquest",
                  "Actigraphy Full" = "actigraphy_full",
                  "Actigraphy Summary" = "actigraphy_summary",
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
              shiny::actionButton("run_export_btn", "Run export"),
              shiny::uiOutput("export_busy_banner")
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
          "Shared Root",
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
            "This screen only stores the shared-drive root for researcher exports. Admin-only REDCap refresh configuration is intentionally kept out of the researcher app."
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
