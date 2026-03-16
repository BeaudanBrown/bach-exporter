# BACH Exporter Repo Instructions

This repository contains the BACH exporter rewrite: a local Shiny app plus hidden backend/export pipeline for producing researcher-facing CSV exports from shared snapshots.

## Working rules

- Use the Nix dev environment for repo commands.
- Prefer `bash ./bin/in-env <command>` for R, test, and formatting tasks.
- Treat `specs/system-spec.md` and `specs/implementation-plan.md` as the primary product and implementation references.
- Treat the coordinator Beads epic `coordinator-d6f` as the live work tracker for this repo; do not add backlog/status tracking to repo markdown.
- Keep researcher-facing workflow simple: launch app, choose export options, write CSV output.
- Do not commit or hardcode REDCap secrets, shared-drive credentials, or researcher-specific local paths.

## Key entrypoints

- `app.R`: top-level app entrypoint
- `launch_bach_exporter.R`: thin local launcher
- `R/`: package code for app, export domains, runtime/bootstrap, and snapshot readers
- `_targets.R`: hidden backend pipeline
- `scripts/refresh_snapshots.R`: admin snapshot refresh entrypoint

## Verification

- `bash ./bin/in-env Rscript scripts/check-dev-env.R`
- `bash ./bin/in-env Rscript tests/testthat.R`

## Formatting

- Format R files with `bash ./bin/in-env air format <path>`.
