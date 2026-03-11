# System Specification

## 1. Purpose

Build a researcher-facing BACH export tool with the following properties:

- Simple enough for non-technical researchers to run from RStudio via a small local script.
- Centrally maintained from a shared-drive release folder.
- Backed by reusable, testable R code.
- Uses `targets` internally to cache reusable cleaned data products and avoid unnecessary recomputation.
- Produces export tables as CSV files for downstream project-specific analysis.
- Can consume the latest REDCap data without exposing the REDCap API token to all researchers.

## 2. Primary users

### 2.1 Researchers

Researchers should be able to:

- Launch the app from a small local script.
- Choose the shared-drive root if not already configured.
- Select domains and options using a GUI.
- Choose an output path with a browse control.
- Generate a CSV without needing to understand `targets`, package installation, or API mechanics.

### 2.2 Maintainers / admins

Maintainers should be able to:

- Publish new backend releases to the shared drive.
- Update presets and side-data.
- Run or schedule REDCap refresh jobs.
- Validate new releases before switching researchers to them.

## 3. Core architectural decisions

### 3.1 Frontend

The frontend will be a local Shiny app written in R.

Rationale:

- The backend is in R.
- A Shiny UI is a better fit than terminal prompts for many options and dependency rules.
- Keeping frontend and backend in one language reduces maintenance burden.

### 3.2 Backend

The backend will be an R package-like codebase with:

- Pure transformation functions under `R/`
- A hidden `targets` graph
- A stable service function `run_export()`
- A stable service function `run_app()`

### 3.3 Deployment model

The deployed runtime model will be:

- Thin local launcher script on each researcher machine
- Shared-drive release bundle containing the current backend code and non-secret assets
- User-local package library
- User-local `targets` store
- Shared-drive data snapshots

### 3.4 REDCap access model

Normal researcher sessions will not call REDCap directly.

Instead:

- An admin-only refresh process will use the REDCap API token.
- That process will write refreshed snapshots to the shared drive.
- Researcher launches will read those snapshots from the shared drive.
- The admin refresh implementation will use `redcapAPI`, with token management through `unlockREDCap()` keyrings.

This is the chosen design because a token that a researcher's R session can read is not meaningfully secret from that researcher.

## 4. API key decision

### 4.1 Decision

Do not store the REDCap API key in a shared folder that all researchers can read if the intent is to keep the key secret from them.

### 4.2 Reasoning

If the researcher's own R session can read the token from the shared drive, then that researcher can usually also read the token directly from the file, the mounted drive, or the in-memory R session. That is not a real security boundary.

### 4.3 Approved token model

The final system will use this model:

- The REDCap API token is stored only in an admin-controlled environment.
- Acceptable locations are:
  - OS keyring on an admin machine
  - restricted environment file on an admin machine
  - ACL-restricted admin-only folder on the shared drive, not readable by researchers
- When using `redcapAPI`, the preferred implementation is an admin-local encrypted keyring created via `unlockREDCap()`.
- Only the admin refresh process uses the token.
- Researcher-facing code reads shared snapshots, not the token.

### 4.4 Optional future mode

The codebase may retain an admin-only API mode for maintainers, but the default deployed researcher workflow must remain snapshot-based.

### 4.5 Initial admin refresh slice

Before full record refresh is implemented, the first admin refresh path may capture schema-only REDCap artifacts with `redcapAPI`, for example:

- project information
- metadata / data dictionary
- events
- instruments
- field names

This is intended to unblock downstream domain implementation without exposing participant data during development.

The admin scaffold should store the REDCap URL, keyring name, and project alias in local admin configuration. The API token itself should be entered interactively into the keyring and not written into project JSON templates.

## 5. Shared-drive layout

The user selects a single shared-drive root. All other paths are derived from it.

Recommended layout:

```text
<shared_root>/
  CURRENT_RELEASE.txt
  releases/
    2026-03-11/
      DESCRIPTION
      NAMESPACE
      renv.lock
      _targets.R
      R/
      inst/
        presets/
        side-data/
      scripts/
        launch_from_share.R
        refresh_snapshots.R
      manifest.json
  snapshots/
    redcap/
      raw.csv
      labels.csv
      metadata.json
      schema/
        metadata.json
        project-info.json
        events.json
        instruments.json
        field-names.json
    psg/
      raw.csv
      metadata.json
    biomarkers/
      raw.csv
      metadata.json
    sidecars/
      snapshot-index.json
  admin/
    README.md
```

Notes:

- `CURRENT_RELEASE.txt` contains the active release identifier, for example `2026-03-11`.
- Avoid relying on symlinks for release switching because they are awkward on Windows shared drives.
- Shared-drive snapshots are the data source for normal researcher sessions.
- Schema-only REDCap snapshots are admin artifacts used to understand project structure and should not be confused with researcher-facing record snapshots.

## 6. Local machine layout

Each user will have local state under `tools::R_user_dir("bachExporter", ...)`.

Recommended local directories:

- config: `R_user_dir("bachExporter", "config")`
- cache: `R_user_dir("bachExporter", "cache")`
- data: `R_user_dir("bachExporter", "data")`

Recommended contents:

```text
<user-config>/
  shared-root.json
  launcher-settings.json

<user-cache>/
  renv-library/
    <release-id>/
      <platform-r-version>/
  targets/
    <release-id>/
  tmp/

<user-data>/
  logs/
  export-history/
```

Rules:

- Package libraries are local per user.
- `targets` stores are local per user.
- Logs and export manifests are local per user.
- The app must never try to use a shared network `targets` store.

## 7. Launch flow

## 7.1 Local launcher responsibilities

The local launcher script is copied to the researcher's machine and opened in RStudio.

It is responsible for:

- Installing a very small bootstrap dependency set if missing
- Reading local saved config for the shared root
- Launching a small bootstrap Shiny app if no valid shared root is configured
- Sourcing the shared release launcher from the shared drive

Bootstrap dependencies may include:

- `shiny`
- `shinyFiles`
- `jsonlite`
- `renv`
- `remotes`

### 7.2 Bootstrap shared-root selector

Because the backend lives on the shared drive, the user must identify that shared root before the main app can run.

The local launcher will therefore include a tiny bootstrap Shiny app whose only job is to:

- show a text field for the shared root path
- show a `Browse` button
- validate that the chosen folder contains `CURRENT_RELEASE.txt` and the expected release structure
- save the selected root locally
- hand control to the shared backend launcher

This bootstrap app satisfies the requirement that the initial app experience include a browse-driven selection of the shared folder root.

### 7.3 Shared release launcher responsibilities

The shared release launcher, stored at:

- `releases/<release-id>/scripts/launch_from_share.R`

is responsible for:

- reading the active release manifest
- setting or confirming local library/cache paths
- restoring package dependencies locally
- installing the current package locally from the release source
- launching the main app via `bachExporter::run_app(shared_root = ...)`

## 8. Dependency management

### 8.1 Chosen model

The primary dependency model will be:

- shared release includes `renv.lock`
- local launcher restores dependencies into a user-local library
- current release package is installed locally from the shared release source

Implementation details:

- use `renv::restore()` for dependency restoration
- use `remotes::install_local()` to install the shared release package into the same local library

### 8.2 Why not use a shared live library

Do not place the active R package library on the shared drive.

Reasons:

- compiled packages differ by OS and often by R version
- network performance is worse
- concurrent use is brittle
- updates are hard to coordinate safely

### 8.3 Optional future enhancement

If first-run package installs are too slow or internet access is constrained, a later enhancement may add a shared offline package repository per OS/R version. This is explicitly out of scope for the first implementation.

## 9. Main app requirements

## 9.1 Primary screens

The main Shiny app will contain at least:

- Export screen
- Presets screen or preset controls
- Settings screen
- Run log / status panel

### 9.2 Export screen controls

The export screen must include:

- output file path text input
- `Browse` button for output location
- grouped domain checkboxes
- year selection controls
- categorical label mode selector
- subset controls
- export format selector
- run/export button

### 9.3 Shared-root settings

The app must also contain a Settings control to view and update the saved shared-root path using a `Browse` button.

This is separate from the bootstrap selector and allows path correction later.

### 9.4 Domain grouping

The UI must not present one long unstructured wall of flags.

Domains should be grouped at minimum into:

- Core / participant
- Follow-up years
- Annual phone / cognition
- Survey / demographics
- Clinical
- Neuropsych
- Sleep questionnaires / actigraphy
- PSG / sleep external
- Imaging / biomarkers / genomics

### 9.5 Presets

The app must support:

- loading predefined presets from the shared release
- saving user presets locally
- re-running prior export specs

## 10. Export backend requirements

### 10.1 Public functions

The package must expose at least:

- `run_app(shared_root = NULL)`
- `run_export(spec, output_path, shared_root, refresh_mode = "auto")`
- `validate_export_spec(spec, shared_root)`

### 10.2 Export spec

All user choices must be represented as a structured export spec object.

Required fields:

- shared root
- release id
- source mode
- selected years
- selected domains
- subset settings
- categorical label mode
- output format
- output path

Recommended shape:

```r
list(
  shared = list(root = "...", release_id = "..."),
  source = list(mode = "snapshot"),
  cohort = list(years = c("baseline"), subset_file = NULL, participant_ids = NULL),
  domains = c("participants", "similarities"),
  options = list(cat_labels = "named"),
  output = list(format = "csv", path = "/path/to/output.csv")
)
```

### 10.3 Export manifest

Every export must write a sidecar manifest next to the output file.

Suggested contents:

- export timestamp
- app version / release id
- snapshot metadata used
- full export spec
- local machine platform info

## 11. Data source model

### 11.1 Normal researcher source mode

Normal researcher runs use shared snapshots under `<shared_root>/snapshots/`.

### 11.2 Admin refresh mode

Admin refresh updates those snapshots from REDCap and any other source systems.

### 11.3 Snapshot requirements

Each snapshot family must have:

- raw data file(s)
- metadata file
- refresh timestamp
- source provenance

## 12. Targets backend requirements

### 12.1 Purpose of `targets`

`targets` is used to cache reusable cleaned and standardized data products.

It is not exposed directly to researchers.

### 12.2 What should be cached

Cache at these layers:

- standardized source tables
- event-split tables
- domain tables
- derived variable tables

Do not generate a dedicated target for every possible final export spec.

### 12.3 Cache location

The `targets` store must be located under the user's local cache directory, partitioned by release id.

### 12.4 Expected target groups

Minimum target families:

- `src_*`: shared snapshot readers
- `std_*`: normalized tables
- `evt_*`: event/year split tables
- `dom_*`: domain tables
- `drv_*`: derived variable tables
- `meta_*`: source metadata

### 12.5 On-demand rebuilds

`run_export()` may call `tar_make(names = ...)` for only the targets required by the requested domains.

Admin tools may use `tar_invalidate()` or refresh-specific cues when snapshots change.

## 13. Source-code structure

Target repository structure:

```text
DESCRIPTION
NAMESPACE
_targets.R
R/
  app_run.R
  app_ui.R
  app_server.R
  bootstrap_root_selector.R
  config.R
  paths.R
  export_spec.R
  export_validate.R
  export_run.R
  targets_graph.R
  targets_helpers.R
  source_snapshots.R
  source_refresh_admin.R
  normalize_redcap.R
  split_events.R
  domain_participants.R
  domain_phone.R
  domain_demographics.R
  domain_bloods.R
  domain_vitals.R
  domain_medhx.R
  domain_medications.R
  domain_neuropsych.R
  domain_sleep.R
  domain_psg.R
  domain_mri.R
  domain_biomarkers.R
  derive_bp.R
  derive_meds.R
  derive_genetics.R
  derive_biomarkers.R
  assemble_export.R
  presets.R
inst/
  presets/
  side-data/
scripts/
  launch_from_share.R
  refresh_snapshots.R
  validate_release.R
tests/testthat/
```

## 14. Migration strategy from `old-script.R`

The old script must be treated as the behavioral reference, not as architecture to preserve.

Migration rules:

- extract logic into pure functions
- avoid global mutable `do_*` variables
- avoid late-stage monolithic `merge()` branches
- validate outputs incrementally against legacy outputs

Domain migration should happen in clusters, not all at once.

## 15. Validation requirements

The new system must be validated against representative outputs from `old-script.R`.

At minimum, validate:

- row counts
- selected column names
- key derived variables
- repeated-instrument handling
- baseline and year-specific outputs

## 16. Logging and error handling

The system must provide:

- clear startup failures when shared root is invalid
- clear dependency/bootstrap failures
- clear snapshot freshness info
- clear export success/failure messages
- per-run log files in the local user data directory

Errors must be written in user-readable terms, not only raw stack traces.

## 17. Non-goals

The following are out of scope for the first implementation:

- bundled standalone desktop executables
- a shared network `targets` cache
- storing the REDCap token in a researcher-readable shared folder
- perfect parity for every domain in the first milestone
- offline package distribution from the shared drive

## 18. Acceptance criteria

The system is considered complete when:

1. A researcher can run one local R script in RStudio.
2. On first run, they can pick the shared root via a browse-enabled bootstrap app.
3. The main Shiny app launches successfully from the shared release.
4. They can choose an output path and requested domains.
5. The app generates a CSV and sidecar manifest.
6. The export is assembled from cached backend components.
7. Researcher machines do not need direct REDCap tokens.
8. At least one admin-only refresh path exists for updating shared snapshots.
