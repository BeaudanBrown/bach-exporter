# Implementation Plan

This plan is written for a fresh agent starting from the current minimal repository.

The goal is to build the system iteratively, with working end-to-end milestones instead of attempting a full rewrite in one pass.

## 0. Current status

This document was updated after the admin refresh implementation and the first legacy-domain migration slices were completed.

### Completed in the first slice

- Added an R package skeleton:
  - `DESCRIPTION`
  - `NAMESPACE`
  - `R/`
  - `inst/`
  - `scripts/`
- Added a minimal root app entrypoint:
  - `app.R`
- Added a self-contained local launcher script:
  - `launch_bach_exporter.R`
- Added shared-root bootstrap logic with a browse-enabled Shiny selector.
- Added local config persistence for the shared-root path under `tools::R_user_dir("bachExporter", "config")`.
- Added core path helpers for:
  - local config dir
  - local cache dir
  - local data/log dir
  - local `targets` dir
  - local library dir
  - shared release path derivation
- Added a minimal main Shiny shell with:
  - Export tab
  - Presets tab
  - Settings tab
  - Status tab
- Added placeholder export spec and validation helpers.
- Added placeholder `run_export()` that writes:
  - a placeholder CSV
  - a sidecar manifest JSON
- Added a minimal hidden `targets` graph scaffold.
- Added placeholder admin refresh config/script stubs.
- Added one shipped preset and one side-data admin config template.
- Extended `flake.nix` with the packages needed for this slice.
- Added a reusable `bin/in-env` wrapper for running commands inside the flake dev environment.
- Added `scripts/check-dev-env.R` to verify the flake-provided R packages are available.

### Completed in the shared-release launcher slice

- Added release-runtime helpers for:
  - release manifest validation
  - release DESCRIPTION parsing
  - per-release dependency restore
  - per-release local package installation
- Updated `scripts/launch_from_share.R` to:
  - validate the active release metadata
  - use a per-release local library
  - restore dependencies from `renv.lock`
  - install the release locally with `remotes::install_local()`
  - launch the installed package via `bachExporter::run_app()`
- Expanded launcher bootstrap packages to include:
  - `renv`
  - `remotes`
- Added a minimal `manifest.json` for the direct `dev` release root.
- Added initial `testthat` scaffolding and release-runtime tests.

### Completed in the snapshot reader slice

- Added `R/source_snapshots.R` with:
  - canonical snapshot path helpers derived from `shared_root`
  - generic CSV and metadata readers
  - snapshot index reader
  - family-specific wrappers for REDCap, PSG, and biomarker snapshots
- Added explicit missing-file errors for snapshot data, metadata, and sidecars.
- Added test coverage for snapshot path derivation and shared-drive snapshot reads.

### Completed in the minimal participants export slice

- Added minimal normalization helpers for:
  - participant ID cleanup
  - REDCap event-to-year mapping
  - empty-column removal
- Added a first domain builder for `participants` using the REDCap snapshot.
- Added `be_assemble_export()` for the direct non-`targets` export path.
- Updated `run_export()` to:
  - assemble a real participants export from the REDCap snapshot
  - write snapshot metadata into the sidecar manifest
  - record app/platform metadata in the manifest
- Added tests covering participants normalization, export output, and unsupported-domain validation.

### Completed in the cohort subsetting slice

- Added cohort filtering helpers for:
  - direct `participant_ids` in the export spec
  - optional `subset_file` lists
- Wired participant subsetting into the direct export assembly path.
- Added minimal UI controls for:
  - ad hoc participant IDs
  - subset file path
- Added tests covering:
  - spec-based participant filtering
  - subset-file participant filtering
  - missing subset-file validation

### Completed in the admin refresh documentation/scaffold slice

- Added `redcapAPI` to the flake R package set and dev-environment verification.
- Expanded the admin refresh config helper to support:
  - local admin config JSON
  - environment-variable overrides
  - shared-root resolution
- Added a schema-snapshot-oriented admin refresh stub entrypoint in `scripts/refresh_snapshots.R`.
- Switched the admin refresh scaffold to `redcapAPI::unlockREDCap()` keyring-based token handling instead of plain-text token config.
- Updated the admin config template with the fields needed for the schema snapshot path.
- Updated the specs to reflect the `redcapAPI`-based admin schema snapshot path.

### Completed in the admin refresh implementation slice

- Added `.env` loading to `scripts/refresh_snapshots.R`.
- Implemented schema snapshot export for:
  - project info
  - events
  - instruments
  - field-name mappings
  - codebook metadata
- Redacted PI contact fields from saved `project-info.json`.
- Implemented typed REDCap record snapshot export for:
  - `raw.csv`
  - `labels.csv`
  - top-level REDCap snapshot metadata
  - snapshot index sidecar
- Added probe-mode record export with env/config controls for record IDs.
- Switched the record snapshot path to `exportRecordsTyped()`.

### Completed in the first legacy-domain migration slices

- Updated the `participants` domain to derive demographics from baseline rows and carry them onto later-year rows.
- Added a real `participant_screening` domain slice based on the legacy script fields:
  - age
  - sex
  - education
  - highest education
  - highest-education other detail
- Added a real `similarities` domain slice using the legacy corrected scoring rule.
- Added a real `prose_passages` domain slice using the annual-phone prose mapping plus the legacy Passage A/B percent-correct denominators.
- Added a real `cognitive_screening` domain slice mapping `tele_total` to `cogscreen_total`.
- Wired the migrated domains into export validation, direct export assembly, presets, and the Shiny domain selector.

### Completed in the initial final-export pipeline slice

- Replaced the scaffold-only `targets` backend with a real hidden export pipeline for the currently implemented domains.
- Updated `run_export()` to execute through the `targets` pipeline by default and keep the direct assembler as a debugging fallback.
- Added a reusable manifest builder so direct and `targets` execution produce the same sidecar shape.
- Added writable-local-store fallback logic so the `targets` cache can run in sandboxed development and test environments.

### Completed in the medications slice

- Added a real `medications` domain slice based on the legacy repeated-instrument fields.
- Implemented dual medication export behavior:
  - standalone `medications` exports stay long at one row per medication instance
  - merged exports widen medication repeat instances so participant-level outputs do not duplicate rows
- Exposed `medications` in export validation, presets, and the Shiny domain selector.

### Verified in the first slice

- All newly added `.R` files, `app.R`, `launch_bach_exporter.R`, and `_targets.R` were parsed successfully with `Rscript`.
- The Nix dev shell now sets `PRE_COMMIT_HOME=./.pre-commit-cache` so git commits do not fail when sandboxed environments cannot write to `~/.cache/pre-commit`.
- `bash ./bin/in-env Rscript scripts/check-dev-env.R` verifies the flake-defined R package set is available.

### Verified in the shared-release launcher slice

- Parsed the changed launcher/runtime files with `Rscript`.
- Ran `bash ./bin/in-env Rscript -e "testthat::test_dir('tests/testthat')"` and all release-runtime tests passed.

### Verified in the snapshot reader slice

- Parsed `R/source_snapshots.R` and `tests/testthat/test-source-snapshots.R` with `Rscript`.
- Ran `bash ./bin/in-env Rscript -e "testthat::test_dir('tests/testthat')"` and all tests passed, including the new snapshot reader tests.

### Verified in the minimal participants export slice

- Parsed the new normalization/domain/export files plus `R/export_run.R`, `R/export_validate.R`, and `R/app_ui.R` with `Rscript`.
- Ran `bash ./bin/in-env Rscript -e "testthat::test_dir('tests/testthat')"` and all tests passed, including the new export tests.

### Verified in the cohort subsetting slice

- Parsed `R/cohort_filters.R`, updated export/app files, and `tests/testthat/test-export-run.R` with `Rscript`.
- Ran `bash ./bin/in-env Rscript -e "testthat::test_dir('tests/testthat')"` and all tests passed.

### Verified in the admin refresh documentation/scaffold slice

- Parsed `R/source_refresh_admin.R` and `scripts/refresh_snapshots.R` with `Rscript`.
- Verified the dev environment package list includes `redcapAPI` via `scripts/check-dev-env.R`.

### Verified in the admin refresh implementation slice

- Ran `bash ./bin/in-env Rscript -e "testthat::test_file('tests/testthat/test-admin-refresh-config.R')"` and the admin refresh tests passed.
- Ran `bash ./bin/in-env Rscript tests/testthat.R` and the full suite passed after the refresh changes.

### Verified in the first legacy-domain migration slices

- Ran `bash ./bin/in-env Rscript -e "testthat::test_file('tests/testthat/test-export-run.R')"` and the export tests passed.
- Ran `bash ./bin/in-env Rscript tests/testthat.R` and the full suite passed after adding `participant_screening`, `similarities`, `prose_passages`, and `cognitive_screening`.

### Verified in the initial final-export pipeline slice

- Parsed the updated pipeline/runtime files and `tests/testthat/test-export-run.R` with `Rscript`.
- Ran `bash ./bin/in-env Rscript -e "testthat::test_file('tests/testthat/test-export-run.R')"` and the targets-backed export tests passed.

### Verified in the medications slice

- Ran `bash ./bin/in-env Rscript -e "testthat::test_file('tests/testthat/test-export-run.R')"` and the medication export tests passed.
- Ran `bash ./bin/in-env Rscript tests/testthat.R` and the full suite passed after adding medication handling.

### Not completed yet

- More legacy domains remain to be migrated from `old-script.R`.
- No packaged `releases/<release-id>/` bundle is checked into this repo yet, so published-release bootstrap has not been exercised against a real shared release artifact.

### Important current behavior

- The local launcher is intentionally self-contained so a researcher can copy a single file onto their machine.
- The shared release launcher now restores into a per-release local library and launches the installed package instead of sourcing the entire `R/` directory into a runtime environment.
- The app supports a development-style shared root:
  - if `CURRENT_RELEASE.txt` is missing
  - but the selected folder contains `DESCRIPTION` and `scripts/launch_from_share.R`
  - then the folder is treated as a direct release root with release id `dev`
- In `dev` mode, missing `renv.lock` is allowed so local development still works without a packaged release bundle.
- In non-`dev` mode, missing `manifest.json` or `renv.lock` is now treated as a release error.
- Snapshot readers now assume the shared-drive layout documented in the spec for:
  - REDCap
  - PSG
  - biomarkers
  - sidecar metadata
- The targets-backed export pipeline currently supports:
  - `participants`
  - `participant_screening`
  - `similarities`
  - `prose_passages`
  - `cognitive_screening`
  - `medications`
- The direct assembler remains available as a debugging fallback.
- `medications` exports now have two supported shapes:
  - standalone long-table export for repeated medication instances
  - widened participant/year merge when combined with participant-grain domains
- The direct export path now supports participant subsetting through either:
  - explicit IDs in the spec/UI
  - a subset file path
- The admin refresh path is now explicitly configured around `redcapAPI` and can write schema snapshots plus typed REDCap record snapshots.
- Probe mode can limit record export to a small set of IDs using env vars or local admin config.
- Placeholder REDCap settings currently exist only to keep the interface shape stable.
- The placeholder API key is masked in the export manifest and is not written into the CSV output.

### Files added or changed across the first six slices

- `DESCRIPTION`
- `LICENSE`
- `NAMESPACE`
- `app.R`
- `launch_bach_exporter.R`
- `_targets.R`
- `flake.nix`
- `R/zzz.R`
- `R/paths.R`
- `R/config.R`
- `R/bootstrap_root_selector.R`
- `R/presets.R`
- `R/export_spec.R`
- `R/export_validate.R`
- `R/export_run.R`
- `R/app_ui.R`
- `R/app_server.R`
- `R/app_run.R`
- `R/release_runtime.R`
- `R/normalize_redcap.R`
- `R/cohort_filters.R`
- `R/split_events.R`
- `R/domain_participants.R`
- `R/domain_similarities.R`
- `R/domain_prose_passages.R`
- `R/domain_cognitive_screening.R`
- `R/assemble_export.R`
- `R/source_snapshots.R`
- `R/source_refresh_admin.R`
- `R/targets_graph.R`
- `bin/in-env`
- `manifest.json`
- `scripts/local_launcher.R`
- `scripts/check-dev-env.R`
- `scripts/launch_from_share.R`
- `scripts/refresh_snapshots.R`
- `inst/presets/baseline-core.json`
- `inst/side-data/admin-config.template.json`
- `tests/testthat.R`
- `tests/testthat/test-release-runtime.R`
- `tests/testthat/test-source-snapshots.R`
- `tests/testthat/test-export-run.R`
- `tests/testthat/test-admin-refresh-config.R`

### Practical notes for the next agent

- `launch_bach_exporter.R` is the intended researcher-facing file. Keep it self-contained unless there is a strong reason not to.
- When working inside the Nix dev shell, `pre-commit` should now use the repo-local `.pre-commit-cache/` directory automatically.
- Use `bash ./bin/in-env <command>` for future R verification and tests so commands run inside the flake environment even when the caller is outside it.
- The current launcher installs these bootstrap packages from CRAN if needed:
  - `shiny`
  - `shinyFiles`
  - `jsonlite`
  - `bslib`
  - `renv`
  - `remotes`
- The current first-run bootstrap UX should be preserved:
  - choose shared root
  - validate it
  - save locally
  - continue into the shared backend
- The baseline environment verification command is:
  - `bash ./bin/in-env Rscript scripts/check-dev-env.R`
- Future test entrypoints should use the same wrapper pattern, for example:
  - `bash ./bin/in-env Rscript -e "testthat::test_dir('tests/testthat')"`
- The next major product gap is migrating additional legacy domains beyond `participants`, `participant_screening`, `similarities`, `prose_passages`, and `cognitive_screening`, then adding `targets` caching behind them.
- The admin refresh stub now expects local admin configuration, not researcher-facing shared config; keep secrets out of the normal shared-release path.
- The admin refresh stub now expects keyring metadata in config and the API token itself in the admin-local `unlockREDCap()` keyring.
- The current participants export already supports cohort filtering, so future domains should plug into that same spec-driven filter path rather than inventing separate subset semantics.
- The current app already has controls for:
  - shared root
  - output path
  - years
  - domains
  - categorical label mode
  - refresh mode
  - placeholder REDCap URL/key
- Those controls are mostly scaffolding and should now be connected to real backend logic instead of being redesigned.
- Do not remove the `dev` shared-root fallback until shared-release packaging is working; it is useful for local development in this repo.

### Current implementation handoff

- The direct non-`targets` export path currently supports:
  - `participants`
  - `participant_screening`
  - `similarities`
  - `prose_passages`
  - `cognitive_screening`
- `participants` now derives demographics from baseline rows and carries them onto later-year rows.
- `participant_screening` maps the first explicit legacy screening cluster from `old-script.R`:
  - `age`
  - `sex`
  - `education`
  - `highest_education`
  - `highest_education_other`
- `similarities` maps the annual-phone similarities cluster from `old-script.R` and uses the corrected stop-after-three-zeros scoring rule.
- `prose_passages` maps the annual-phone prose cluster from `old-script.R` and derives immediate/delayed percent-correct using the legacy Passage A/B denominators.
- `cognitive_screening` maps the legacy TELE screening field from `old-script.R`:
  - `tele_total -> cogscreen_total`
- The admin refresh path is implemented and can:
  - write schema snapshots
  - write typed REDCap record snapshots
  - run in probe mode for a small list of records
- Probe/full refresh behavior can now be controlled entirely by env vars in `.env`:
  - `BACH_SCHEMA_SNAPSHOT_ONLY`
  - `BACH_RECORD_PROBE_ONLY`
  - `BACH_PROBE_RECORDS`
- The refresh path now uses `redcapAPI::exportRecordsTyped()` rather than `exportRecords()`.
- Current tests are green after the domain and refresh work:
  - `bash ./bin/in-env Rscript -e "testthat::test_file('tests/testthat/test-export-run.R')"`
  - `bash ./bin/in-env Rscript tests/testthat.R`
- The next recommended domain slice is one of the remaining annual-phone clusters adjacent to the current work, such as `moca` or `ad8`, because they use the same event/year merge pattern.
- After that, continue broader annual-phone migration before shifting focus to the heavier non-phone domains.

## 1. Implementation principles

- Prefer incremental, testable milestones.
- Keep the researcher UX simple from the first working version.
- Hide `targets` behind stable service functions.
- Keep runtime state local per user.
- Keep the shared drive as the source of truth for releases and snapshots.
- Do not put the REDCap token in the normal researcher runtime path.
- Validate legacy equivalence in slices, not only at the end.

## 2. Recommended development order

Do not start by porting every section of `old-script.R`.

Start with:

1. package/runtime skeleton
2. launcher and shared-root bootstrap
3. main app shell
4. snapshot source readers
5. one small end-to-end export path
6. `targets` integration
7. incremental domain migration

## 3. Milestone map

### Milestone 1

Shared-root bootstrap works and the main Shiny app launches from a shared release.

Status: complete in code for launcher/runtime behavior; release packaging still needs to be exercised with a real bundled release.

Completed:

- local launcher exists
- bootstrap shared-root selector exists
- main Shiny app launches through the shared launcher path
- shared launcher restores to a per-release local library
- shared launcher installs the release locally and calls `bachExporter::run_app()`
- release manifest validation exists

Remaining:

- publish and validate a real `releases/<release-id>/` bundle with `renv.lock` and `manifest.json`

### Milestone 2

An end-to-end export works for a minimal domain set using snapshot files and no `targets` yet.

Status: substantially complete for the first direct-export vertical slice.

Completed:

- direct export path writes CSV plus manifest
- snapshot-backed export works for:
  - `participants`
  - `participant_screening`
  - `similarities`
  - `prose_passages`
  - `cognitive_screening`

Remaining:

- migrate additional legacy domain clusters
- validate the migrated outputs against broader legacy expectations

### Milestone 3

The same minimal export works through the `targets` backend with local caching.

Status: not started beyond skeleton.

Completed:

- `_targets.R` skeleton exists
- `be_target_graph()` exists

Remaining:

- actual source/domain targets
- local `targets` store wiring during export
- `run_export()` integration with `tar_make()`

### Milestone 4

Core domains from `old-script.R` are migrated and validated.

Status: started.

### Milestone 5

Admin refresh tooling for shared snapshots is in place.

Status: partially complete.

## 4. Phase-by-phase plan

## Phase 1: Create the package skeleton

### Objectives

- turn the repo into a normal R package project
- establish file layout for app/backend/tests

### Tasks

1. Create `DESCRIPTION`.
2. Create `NAMESPACE`.
3. Create `R/`, `inst/`, `scripts/`, and `tests/testthat/`.
4. Add a minimal exported `run_app()` function.
5. Add a minimal exported `run_export()` placeholder.
6. Keep `_targets.R` but reduce it to a clean graph skeleton.

### Deliverables

- package can be loaded
- `run_app()` exists
- `run_export()` exists

### Exit criteria

- repository structure matches the spec
- package-level checks can run locally

Status: mostly complete.

Notes:

- structure exists
- `run_app()` and `run_export()` exist
- parse-level checks passed
- package install/check workflow has not been wired yet

## Phase 2: Build path/config infrastructure

### Objectives

- centralize all path handling
- support local config and local cache directories

### Tasks

1. Implement `paths.R` with helpers for:
   - local config dir
   - local cache dir
   - local data dir
   - local log dir
   - local `targets` dir by release id
   - local library dir by release id
2. Implement `config.R` with helpers to:
   - save shared root
   - read shared root
   - validate shared root
   - read current release id from `CURRENT_RELEASE.txt`
3. Define canonical derived shared-drive paths:
   - release root
   - presets dir
   - side-data dir
   - snapshots dir

### Deliverables

- deterministic path derivation from one shared root
- local config read/write helpers

### Exit criteria

- one function can take only `shared_root` and derive all needed paths

Status: complete for the initial slice.

Implemented in:

- `R/paths.R`
- `R/config.R`

## Phase 3: Build the local launcher bootstrap

### Objectives

- make first-run launch possible from a single local script
- satisfy the browse-based shared-root selection requirement

### Tasks

1. Create a local launcher script template, for example `launch_bach_exporter.R`.
2. In the launcher:
   - install bootstrap packages if missing
   - read saved shared-root config
   - if missing/invalid, launch a tiny bootstrap Shiny app
3. Implement bootstrap Shiny app in `R/bootstrap_root_selector.R`.
4. Bootstrap app requirements:
   - text field for shared root
   - `Browse` button
   - validate button or automatic validation
   - continue button
5. Save the selected root locally.
6. Source the shared release launcher from the derived release path.

### Deliverables

- researcher can run one small local script
- first run asks for shared root using a browse-enabled UI

### Exit criteria

- invalid shared root is rejected
- valid shared root launches shared backend control flow

Status: complete for the initial slice.

Implemented in:

- `launch_bach_exporter.R`
- `scripts/local_launcher.R`

Note:

- `launch_bach_exporter.R` duplicates launcher logic intentionally so it can be copied as a single file.

## Phase 4: Implement shared release launcher

### Objectives

- allow code on the shared drive to manage the local runtime

### Tasks

1. Create `scripts/launch_from_share.R` in the release structure.
2. Implement a function such as `launch_from_share(shared_root)`.
3. Steps inside `launch_from_share()`:
   - read current release id
   - derive release root
   - set local library path
   - ensure `renv` is available
   - restore dependencies from `renv.lock`
   - install current package locally from the release source
   - call `bachExporter::run_app(shared_root = shared_root)`
4. Add release manifest validation.

### Deliverables

- stable shared entrypoint script

### Exit criteria

- app can be launched from shared release after dependency bootstrap

Status: complete in code for the launcher implementation slice.

Implemented:

- `scripts/launch_from_share.R`
- `R/release_runtime.R`

Current limitation:

- the repository still relies on the direct `dev` release-root fallback for local development because no packaged release bundle is checked in
- published-release bootstrap still needs to be exercised against a real `releases/<release-id>/` folder with `renv.lock`

## Phase 5: Build the main app shell

### Objectives

- create a usable but initially thin main GUI

### Tasks

1. Create `R/app_ui.R`, `R/app_server.R`, and `R/app_run.R`.
2. Implement tabs or panels for:
   - Export
   - Presets
   - Settings
   - Status/Logs
3. Add placeholder grouped domain controls.
4. Add output path field and `Browse` button.
5. Add shared-root display and settings browse control.
6. Add status panel with progress text.

### Deliverables

- main Shiny app launches with final intended structure

### Exit criteria

- user can navigate app and save settings without exporting data yet

Status: complete for the initial shell.

Implemented in:

- `R/app_ui.R`
- `R/app_server.R`
- `R/app_run.R`

## Phase 6: Define export spec and validation

### Objectives

- replace ad hoc UI state with a validated spec object

### Tasks

1. Implement `export_spec.R` helpers:
   - build spec from UI values
   - serialize spec
   - deserialize spec
2. Implement `export_validate.R`:
   - required field checks
   - path validation
   - domain dependency checks
   - year/domain compatibility checks
3. Implement preset file schema.
4. Add a small set of shipped presets under `inst/presets/`.

### Deliverables

- stable spec object for exports
- early user-friendly validation errors

### Exit criteria

- UI can construct and validate a spec before export

Status: partially complete.

Implemented:

- default spec helper
- basic validation

Remaining:

- richer dependency rules
- preset file schema beyond the current minimal preset structure

## Phase 7: Implement snapshot source readers

### Objectives

- support the chosen shared-snapshot data model

### Tasks

1. Implement `source_snapshots.R` with readers for:
   - REDCap raw export
   - REDCap labels export if still required
   - PSG snapshot
   - biomarker snapshot
   - metadata sidecars
2. Standardize file lookup based on shared root.
3. Add snapshot metadata helpers.
4. Add graceful errors when snapshots are missing.

### Deliverables

- consistent read layer for snapshot-based operation

### Exit criteria

- snapshot readers can load data and report metadata

Status: complete for the initial snapshot reader slice.

Implemented in:

- `R/source_snapshots.R`
- `tests/testthat/test-source-snapshots.R`

Notes:

- Readers currently cover the shared snapshot families already named in the spec:
  - REDCap
  - PSG
  - biomarkers
- Missing snapshot files fail with explicit path-bearing errors so the next export slice can surface clear validation.

## Phase 8: Build a minimal non-targets export path

### Objectives

- establish a working end-to-end export before adding orchestration complexity

### Tasks

1. Implement minimal normalization helpers:
   - ID cleanup
   - event split
   - empty-column removal
2. Implement initial domain builders for a small slice:
   - participants
   - annual phone similarities or another small, high-value domain
3. Implement `assemble_export()` for selected domain joins.
4. Implement `run_export()` in direct mode first.
5. Wire the main app export button to `run_export()`.
6. Write output CSV plus manifest.

### Deliverables

- first usable end-to-end export

### Exit criteria

- researcher can select a small domain set and receive a CSV from the app

Status: partially complete.

Implemented:

- placeholder export writes output and manifest
- direct non-`targets` export now works for the `participants` domain from the REDCap snapshot

Remaining:

- extend the direct export path beyond `participants`

## Phase 9: Add `targets` backend

### Objectives

- introduce caching only after an end-to-end path already works

### Tasks

1. Implement `_targets.R` around pure functions already created.
2. Add target families:
   - source readers
   - standardized data
   - event splits
   - domain tables
3. Add helpers to run a subset of targets for requested domains.
4. Point `run_export()` at `targets` outputs instead of recomputing inline.
5. Set the `targets` store to the user-local cache path for the active release.

### Deliverables

- local cached backend

### Exit criteria

- repeated export runs avoid unnecessary recomputation

Status: not started beyond skeleton.

## Phase 10: Migrate legacy logic in domain clusters

### Objectives

- port `old-script.R` behavior in manageable chunks

### Migration order

1. Core:
   - participant screening
   - event/session fields
   - subset handling
2. Annual phone:
   - prose
   - similarities
   - MoCA
   - AD8
3. Survey/demographics:
   - demographics
   - SES
   - ARIA
   - CES-D
   - STAI
   - PSS
4. Clinical:
   - bloods
   - vitals
   - med history
   - medications
5. Neuropsych:
   - CDR
   - MMSE
   - test batteries
6. Sleep questionnaires and actigraphy
7. Imaging / MRI / LP / PSG
8. Biomarkers and genomics

### Tasks for each cluster

1. create source-to-output mapping inventory
2. implement domain builder
3. implement derived variables
4. add tests
5. validate against legacy output
6. expose UI controls

### Deliverables

- cluster-by-cluster parity with legacy logic

### Exit criteria

- each migrated cluster has at least one validation fixture against legacy output

Status: not started.

## Phase 11: Implement derived-variable modules

### Objectives

- move late-stage calculations out of monolithic assembly code

### Tasks

1. Create separate derivation modules for:
   - blood pressure outcomes
   - medication categories
   - cognition summaries
   - biomarker ratios
   - genotype labels
2. Ensure they operate on normalized domain inputs.
3. Add unit tests for formulas and edge cases.

### Deliverables

- independent derivation logic with tests

### Exit criteria

- derived variables no longer live inside one giant post-merge block

Status: not started.

## Phase 12: Implement admin refresh tooling

### Objectives

- support secure REDCap refresh without giving researchers the token

### Tasks

1. Create `scripts/refresh_snapshots.R`.
2. Implement admin-only source mode using the REDCap package/API.
3. Read token from admin-controlled environment, not researcher-readable config.
4. Write refreshed snapshots and metadata to the shared root.
5. Record refresh timestamps and provenance.
6. Optionally add a dry-run validation mode.

### Deliverables

- admin refresh path for shared snapshots

### Exit criteria

- snapshots can be refreshed without researcher machines needing the token

Status: partially complete for config/docs/scaffold; execution is still not implemented.

Current scaffold:

- `R/source_refresh_admin.R`
- `scripts/refresh_snapshots.R`
- `inst/side-data/admin-config.template.json`

Notes:

- The selected admin REDCap library is `redcapAPI`.
- The current stub is intentionally schema-snapshot-oriented first so downstream development can use structural metadata before record export is implemented.
- Use `scripts/refresh_snapshots.R --init-keyring` to populate or unlock the admin keyring interactively.

## Phase 13: Logging, manifests, and history

### Objectives

- make runs inspectable and auditable

### Tasks

1. Write one log file per run.
2. Write one manifest file per export.
3. Add an export history view in the UI.
4. Include snapshot metadata in manifests.

### Deliverables

- traceable export history

### Exit criteria

- a researcher can tell what data and settings produced a file

Status: partially complete.

Implemented:

- export manifest sidecar

Remaining:

- run logs
- history view
- snapshot metadata integration

## Phase 14: Release management

### Objectives

- make shared-drive releases safe and repeatable

### Tasks

1. Define release manifest schema.
2. Define `CURRENT_RELEASE.txt` update process.
3. Add `scripts/validate_release.R`.
4. Add release checklist:
   - package checks pass
   - app launches
   - one export succeeds
   - validation fixtures pass
5. Document rollback procedure.

### Deliverables

- versioned release workflow

### Exit criteria

- maintainers can publish and roll back shared releases safely

Status: not started.

## Phase 15: User documentation

### Objectives

- make the system usable by researchers without oral handover

### Tasks

1. Write short researcher instructions:
   - how to run launcher
   - how to pick shared root
   - how to generate an export
2. Write maintainer instructions:
   - how to publish release
   - how to refresh snapshots
   - how to add presets
3. Write troubleshooting guide.

### Deliverables

- concise user and maintainer docs

### Exit criteria

- a new researcher can launch and export without direct maintainer intervention

Status: not started.

## 5. Testing strategy

### Unit tests

Add unit tests for:

- path derivation
- config persistence
- spec validation
- normalization helpers
- derivation functions

### Integration tests

Add integration tests for:

- launcher path resolution
- snapshot reading
- one minimal export run
- one `targets`-backed export run

### Regression tests

Create fixture-based comparisons against legacy outputs for representative configurations.

## 6. Explicit anti-patterns to avoid

- Do not port `old-script.R` into one new giant function.
- Do not expose `targets` objects or commands in the researcher UI.
- Do not use a shared network `targets` store.
- Do not rely on a researcher-readable shared token file for secrecy.
- Do not make the UI a flat wall of dozens of unchecked boxes with no grouping.
- Do not attempt all domain migrations before first end-to-end success.

## 7. First concrete build target

The first fully working vertical slice should support:

- local launcher script
- bootstrap shared-root selector with browse control
- launch of main app from shared release
- one small preset
- one small end-to-end export
- local output CSV plus manifest

Suggested minimal domain set:

- participant screening
- event/session fields
- one annual phone domain such as similarities

This is the fastest credible slice that proves the architecture.

## 8. Recommended next actions

The next agent should work on the following in order:

1. Implement real shared-release bootstrap in `scripts/launch_from_share.R`:
   - create local library path
   - restore dependencies locally
   - install the package locally from the selected release root
   - switch from direct `sys.source()` runtime loading to `bachExporter::run_app()`
2. Add the first real source-reading layer for shared snapshots.
3. Replace placeholder export generation with a real minimal vertical slice:
   - normalize IDs/events
   - participant screening
   - one annual phone domain
4. Wire that minimal vertical slice into `targets`.
5. Add a small number of tests around:
   - shared-root validation
   - export spec validation
   - minimal export generation

## 9. Known intentional shortcuts in the current code

- `R/zzz.R` only sets placeholder options and is not otherwise relied upon.
- `scripts/local_launcher.R` exists, but the canonical researcher-facing entrypoint is still `launch_bach_exporter.R`.
- `scripts/local_launcher.R` and `launch_bach_exporter.R` currently duplicate logic on purpose.
- `CURRENT_RELEASE.txt` handling is optional during development because the repo root can be treated as a `dev` release root.
- Placeholder REDCap controls are currently exposed in the Settings tab to keep the UI shape stable. They should become admin-only or hidden in the researcher path once snapshot refresh is implemented.
