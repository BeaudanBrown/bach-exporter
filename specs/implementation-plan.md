# Implementation Plan

This document defines the durable implementation direction for the BACH exporter rewrite.

Live backlog tracking now happens in the coordinator Beads graph under epic `coordinator-d6f` (`bach-exporter: exporter-rewrite-completion`). Do not use this file as a running status board, checklist, or handoff log.

## Purpose

The exporter should provide a stable researcher-facing CSV export workflow with these properties:

- researchers launch a simple local R script
- the local launcher finds a shared-drive root and loads the active backend release
- export logic lives in testable R code rather than a monolithic script
- `targets` remains a hidden backend orchestration and caching layer
- REDCap refresh is handled by an admin-only path that writes snapshots for researcher use

## Durable implementation principles

- Prefer incremental, testable milestones over large rewrites.
- Keep the researcher workflow simple: launch app, choose options, write CSV output.
- Keep `targets` behind stable service functions such as `run_export()`.
- Keep user runtime state local rather than shared on the network drive.
- Treat shared-drive snapshots as the normal data source for researcher sessions.
- Keep REDCap credentials out of the researcher runtime path.
- Validate legacy equivalence in slices instead of waiting for a final big-bang comparison.

## Current architecture baseline

The repository already uses the intended package-style layout:

- `app.R` for the top-level app entrypoint
- `launch_bach_exporter.R` for the thin researcher-facing launcher
- `R/` for app, export, runtime, and snapshot code
- `_targets.R` for the hidden backend pipeline
- `scripts/refresh_snapshots.R` for the admin refresh entrypoint
- `tests/testthat/` for automated verification

The intended runtime model remains:

- thin local launcher on each researcher machine
- shared-drive release bundle for backend code and non-secret assets
- user-local package library
- user-local `targets` store
- shared-drive snapshots for normal data access

## Implementation lanes

The rewrite should continue to evolve along these lanes:

1. Runtime and release flow
   - keep the thin launcher model
   - preserve the shared-drive release bootstrap path
   - make release publication and validation repeatable
2. Export specification and validation
   - keep export requests spec-driven rather than ad hoc UI state
   - preserve early validation with clear user-facing errors
3. Snapshot-backed export assembly
   - keep snapshot readers as the common source layer
   - add domain builders as pure functions with clear inputs and outputs
4. Hidden `targets` orchestration
   - keep caching and orchestration out of the researcher UI
   - use user-local stores keyed by release
5. Domain migration from `old-script.R`
   - port legacy behavior in domain clusters
   - require tests and representative output validation for each cluster
6. Admin refresh
   - preserve the admin-only REDCap refresh boundary
   - write snapshots and provenance back to the shared root
7. Release and support tooling
   - keep manifests, logging, validation, and user documentation aligned with the release flow

## Recommended development order

When continuing implementation, prefer this sequence:

1. verify the true current state against the codebase before changing plans
2. finish runtime and release-path gaps before relying on the packaged workflow
3. keep export spec validation ahead of UI expansion
4. keep `targets` parity aligned with the direct export path
5. migrate legacy domains in coherent clusters with tests
6. extract reusable derived-variable modules when repeated calculation patterns appear
7. complete admin refresh provenance and release-management tooling
8. update user and maintainer documentation after workflow changes settle

## Domain migration strategy

Continue domain migration in explicit clusters so review and validation stay tractable:

1. Core
   - event/session fields
   - remaining subset-handling behavior
2. Annual phone
   - adjacent annual-phone clusters such as MoCA and AD8
3. Survey and demographics
   - SES
   - ARIA
   - CES-D
   - STAI
   - PSS
4. Clinical
   - bloods
   - vitals
   - medical history
   - remaining medication-related logic
5. Neuropsych
   - CDR
   - MMSE
   - test batteries
6. Sleep questionnaires and actigraphy
7. Imaging, MRI, LP, and PSG
8. Biomarkers and genomics

For each cluster:

1. create the source-to-output mapping inventory
2. implement pure domain builders and derived-variable helpers
3. add tests
4. compare with representative legacy output
5. wire the domain into validation, assembly, and UI only after tests pass

## Testing strategy

Keep verification layered:

- unit tests for path derivation, config persistence, validation, normalization, and derivations
- integration tests for launcher path resolution, snapshot reading, and export execution
- regression fixtures for representative legacy output comparisons

Preferred commands:

- `bash ./bin/in-env Rscript scripts/check-dev-env.R`
- `bash ./bin/in-env Rscript tests/testthat.R`

## Documentation boundary

Keep durable architecture and workflow guidance in the repo:

- `specs/system-spec.md` for product and architecture decisions
- `specs/implementation-plan.md` for durable implementation direction
- `AGENTS.md` for execution conventions inside this repo

Keep live task tracking out of repo markdown:

- use coordinator Beads for blockers, priorities, sequencing, and open work
- do not add `Status:`, `Remaining:`, checklist, or handoff-style tracking sections here
- record only repo-wide conventions or stable design decisions in markdown

## Anti-patterns to avoid

- Do not recreate `old-script.R` as one large replacement function.
- Do not expose `targets` objects or commands in the researcher UI.
- Do not use a shared network `targets` store.
- Do not store REDCap secrets in researcher-readable config or shared files.
- Do not let the launcher or UI drift away from the simple researcher workflow.
- Do not turn repo markdown back into a live issue tracker after migrating to Beads.
