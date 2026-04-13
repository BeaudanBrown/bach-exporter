# Implementation Plan

This document defines the durable implementation direction for the BACH exporter rewrite.

Live backlog tracking now happens in the coordinator Beads graph. The completed rewrite epic was `coordinator-d6f` (`bach-exporter: exporter-rewrite-completion`); the completed first performance lane was `coordinator-l1n` (`bach-exporter: export performance and target-graph refactor`); the current follow-on hotspot-reduction lane is `coordinator-jor` (`bach-exporter: export pipeline hotspot reduction`). Do not use this file as a running status board, checklist, or handoff log.

## Purpose

The exporter should provide a stable researcher-facing CSV export workflow with these properties:

- researchers launch a simple local R script
- the local launcher finds a shared-drive root and loads the shared app bundle
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
- shared-drive app bundle for backend code and non-secret assets
- user-local package library
- user-local `targets` store
- shared-drive snapshots for normal data access

The current export implementation now follows this backend shape:

- `be_build_export_context()` prepares, participant-filters, and year-filters REDCap once per export run
- `be_build_export_intermediates()` computes shared scaffold and lookup data once per export
- `be_export_domain_registry()` plus `be_build_export_domain_output()` build requested domains independently
- `be_reduce_export_domain_outputs()` and `be_finalize_export_output()` assemble the final table in a controlled participant/event reduction rather than a long serial merge chain
- the hidden `targets` graph mirrors that structure with explicit context, intermediate, per-domain, grouped-output, and final `export_data` targets

## Implementation lanes

The rewrite should continue to evolve along these lanes:

1. Runtime and release flow
   - keep the thin launcher model
   - preserve the shared-drive app bootstrap path
   - make app deployment and validation repeatable
2. Export specification and validation
   - keep export requests spec-driven rather than ad hoc UI state
   - preserve early validation with clear user-facing errors
3. Snapshot-backed export assembly
   - keep snapshot readers as the common source layer
   - add domain builders as pure functions with clear inputs and outputs
4. Hidden `targets` orchestration
   - keep caching and orchestration out of the researcher UI
   - use user-local stores keyed by build id
   - prefer reusable intermediate/domain targets over one monolithic export target when performance work touches the graph
5. Domain migration from `old-script.R`
   - port legacy behavior in domain clusters
   - require tests and representative output validation for each cluster
6. Admin refresh
   - preserve the admin-only REDCap refresh boundary
   - write snapshots and provenance back to the shared root
7. Release and support tooling
   - keep manifests, logging, validation, and user documentation aligned with the shared app flow

## Recommended development order

When continuing implementation, prefer this sequence:

1. verify the true current state against the codebase before changing plans
2. finish runtime and release-path gaps before relying on the packaged workflow
   - keep the admin surface simple enough that the normal operation is a one-command shared-root refresh
3. keep export spec validation ahead of UI expansion
4. keep the hidden `targets` export path stable as the only execution backend
5. migrate legacy domains in coherent clusters with tests
6. extract reusable derived-variable modules when repeated calculation patterns appear
7. complete admin refresh provenance and release-management tooling
8. update user and maintainer documentation after workflow changes settle

## Current performance refactor direction

The next implementation lane is not new exporter functionality; it is removal of the main structural inefficiencies in the current export path so broad researcher exports do not repeatedly redo the same work.

The current refactor direction is:

1. Shared export context
   - prepare and year-filter the REDCap snapshot once per export
   - push participant filtering upstream where safe
   - thread prepared inputs through domain builders instead of letting each builder normalize the full snapshot again
2. Reusable per-export intermediates
   - compute scaffold, baseline demographics, and shared lookup tables once per export
   - reuse shared side-data and snapshot reads instead of rebuilding SES/ARIA/PSG-style inputs ad hoc
3. Registry-driven assembly
   - replace the long hand-written `if (...) merge(...)` chain with a domain registry
   - build domain frames independently and merge event-level versus participant-level outputs in separate controlled passes
4. Reusable hidden `targets` graph
   - split the backend graph into prepared data, shared intermediates, domain outputs, and final assembly
   - keep targets-mode execution single-pass for shared REDCap preparation and shared side-data reads
   - keep the researcher-facing `run_export()` contract stable while making later parallel backends worthwhile
5. Performance-oriented verification
   - add focused tests that fail if builders regress to repeated whole-snapshot preparation
   - assert the same reuse guarantees in the hidden targets pipeline, not only in lower-level assembly tests
   - keep representative broad-export verification around the refactored hot path

The intended end state is that future `crew` or other parallel backends, if adopted, operate on genuinely reusable domain/intermediate targets rather than parallelizing duplicated preprocessing work.

## Current hotspot-reduction direction

The next follow-on performance lane is narrower and more data-path specific than the previous refactor. It assumes the shared export context and reusable graph structure already exist, and focuses on the remaining structural costs seen during broad exports.

The current direction is:

1. Shared event-level reductions
   - landed on 2026-03-27 for the simple field-map and participant-year domain families
   - the filtered REDCap export input now carries reusable event, baseline-participant, and participant-year grouped reductions
   - simple domains now read from those grouped reductions instead of each rebuilding their own split/group pass
2. Scaffold-first keyed assembly
   - landed on 2026-03-27 for event, participant, and scaffold assembly
   - final export assembly now uses keyed event and participant accumulators plus keyed scaffold attachment instead of repeated serial wide merges
   - row-order-sensitive exports remain aligned with requested event-key order while avoiding repeated widening-copy costs
3. Targets-only optimization path
   - keep `targets` as the only execution backend so one full export can seed reusable cached domain and intermediate targets
   - optimize cache reuse and later parallel execution on that single backend instead of maintaining a second runtime path
4. Post-generic profiling
   - landed on 2026-03-28 for the first specialized heavy-domain tightening pass
   - biomarkers now reduce and widen once per participant instead of split-building per-participant rows and merging afterward
   - PSG powerspec now reduces and widens once per participant/channel/band/stage and attaches onto the scaffold by keyed match instead of a final merge
   - medications wide export now reuses scaffold, event reductions, and baseline demographics instead of regrouping the full filtered REDCap frame
5. Shared setup and IO profiling
   - once the specialized builders stop dominating, isolate the remaining shared snapshot/context setup cost on the live targets-backed path
   - measure REDCap snapshot read/preparation, shared scaffold construction, and large side-data normalization separately before choosing the next optimization target

This lane should reduce the remaining serial costs first. Parallelisation can be revisited after the sequential hot path stops doing avoidable duplicated work.

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
- integration tests for launcher path resolution, shared app upgrade detection, snapshot reading, and export execution
- regression fixtures for representative legacy output comparisons
- focused export-path regressions for:
  - one-pass REDCap preparation
  - single-pass participant filtering
  - shared lookup reuse for SES/ARIA and PSG families
  - targets-graph structure and targets-mode reuse-sensitive behavior

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
