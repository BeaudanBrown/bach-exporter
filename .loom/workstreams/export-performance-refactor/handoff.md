# Export Performance Refactor Handoff

## Starting point

- Coordinator epic: `coordinator-l1n`
- Current active slice: `coordinator-l1n.5`
- Baseline branch: `master`
- Latest known local commit before this lane started: `8173862829b5ea8a65387cdec5e7393575d21830`

## Known hotspots

1. `R/assemble_export.R`
   - reads the REDCap snapshot once, but nearly every selected domain then rebuilds prepared/year-filtered forms internally
   - uses a long serial merge chain over one widening table
2. Domain helpers such as:
   - `R/domain_clinical.R`
   - `R/domain_surveys.R`
   - `R/domain_participants.R`
   - `R/domain_sleep.R`
   - `R/domain_annual_phone_aux.R`
   These frequently begin with `be_prepare_redcap_snapshot()` plus `be_filter_years()`.
3. `R/export_pipeline.R` / `R/targets_graph.R`
   - current graph is effectively one reusable data target (`export_data`) plus manifest metadata
   - not worth parallelizing yet without reusable intermediates

## Recommended execution order

1. Add a shared export context and route the first builder helpers through it.
2. Extract reusable scaffold and lookup intermediates.
3. Collapse the manual domain chain into registry-driven assembly.
4. Reshape the hidden `targets` graph to mirror the new reusable runtime structure.
5. Add focused structural/performance regression coverage.

## Verification baseline

- `bash ./bin/in-env Rscript tests/testthat.R`

Add narrower focused verification as the refactor progresses, but keep the full suite green between slices.

## Progress on `coordinator-l1n.1`

- Added `be_build_export_context()` in `R/assemble_export.R`.
  - It now builds one prepared REDCap snapshot per export plus:
    - a participant-filtered prepared frame
    - a participant-and-year-filtered domain frame
    - the core scaffold from that filtered domain frame
- Added prepared/filter bookkeeping helpers in:
  - `R/normalize_redcap.R`
  - `R/split_events.R`
  These make REDCap preparation idempotent and allow repeated year-filter requests on an already-filtered prepared frame to short-circuit.
- Switched the main hot-path builder families to consume `be_redcap_domain_input(...)` instead of directly calling `be_prepare_redcap_snapshot()` plus `be_filter_years()`:
  - `R/domain_participants.R`
  - `R/domain_surveys.R`
  - `R/domain_clinical.R`
  - `R/domain_annual_phone_aux.R`
  - `R/domain_screening_aux.R`
  - `R/domain_imaging.R`
  - `R/domain_neuropsych.R`
  - `R/domain_sleep.R`
  - `R/domain_cognitive_screening.R`
  - `R/domain_medications.R`
  - `R/domain_similarities.R`
  - `R/domain_prose_passages.R`
- Added a regression in `tests/testthat/test-export-run.R` that traces the actual normalization step (`be_filter_supported_participants`) and asserts the hot export path prepares the REDCap snapshot once per export.

## Progress on `coordinator-l1n.2`

- `R/assemble_export.R` now builds export-scoped intermediates for:
  - participant scaffold
  - baseline demographics
  - shared SES/ARIA lookup data
  - shared PSG lookup data
  - PSG powerspec wide data
- The hot assembly path no longer re-applies `be_filter_participants()` on each built domain table. Participant filtering now happens once in the export context and downstream builders consume the already-filtered REDCap input.
- Reused side-data builders now accept injected intermediates instead of always rereading from disk:
  - `R/domain_surveys.R`
  - `R/domain_imaging.R`
  - `R/domain_sleep.R`
  - `R/domain_biomarkers.R`
  - `R/domain_genomics.R`
  - `R/domain_participants.R`
- `aria` no longer forces a second rebuild of `ses` during normal export assembly; the cached SES result and lookup tables are reused when both domains are selected.
- Regression coverage in `tests/testthat/test-export-run.R` now proves:
  - participant filtering happens once per export
  - `ses` + `aria` read `absdf.csv` once
  - `psg_summary` + `psg_full` read `psg_data.csv` once

### Current verification

- `bash ./bin/in-env Rscript -e 'testthat::test_file("tests/testthat/test-export-run.R")'`
- `bash ./bin/in-env Rscript tests/testthat.R`

Both passed after the shared-lookup/intermediate refactor landed.

## Progress on `coordinator-l1n.3`

- `R/assemble_export.R` no longer uses the long hand-written `if ("domain" %in% domains)` assembly chain.
- Export assembly now resolves requested domains through `be_export_domain_registry()` and `be_supported_export_domains()`.
- The runtime now composes outputs in two passes:
  - participant-level domains reduce through `be_merge_participant_domain()`
  - event-level domains reduce through `be_merge_event_domain()`
  - participant-level data then joins onto the event result once at the end when both shapes are present
- Added mixed-shape regression coverage in `tests/testthat/test-export-run.R` for participant-level screening data merged onto an event-level export.

### Next slice

- The next substantial step is `coordinator-l1n.4`: reshape the hidden `targets` graph around reusable prepared/intermediate/domain targets so the runtime structure that now exists in `R/assemble_export.R` can be reused by the targets backend and later parallelised cleanly.

## Progress on `coordinator-l1n.4`

- `R/assemble_export.R` now exposes reusable runtime helpers that match the new graph shape:
  - `be_build_export_domain_output()` builds one named domain result from the registry
  - `be_reduce_export_domain_outputs()` merges event-level and participant-level domain outputs without depending on the old inline assembly loop
  - `be_finalize_export_output()` adds scaffold columns onto the reduced result as the final assembly step
- `R/targets_graph.R` no longer routes directly from config targets to one monolithic `export_data` build.
  - The graph now includes explicit reusable targets for:
    - `export_context`
    - `export_prepared_redcap`
    - `export_domain_redcap`
    - `export_scaffold`
    - `export_intermediates`
    - one `export_domain_<domain>` target per requested domain
    - `participant_domain_outputs`
    - `event_domain_outputs`
    - final `export_data` assembled from those reusable results
- `be_target_graph()` now validates unsupported domains before creating per-domain targets, so the graph fails early rather than hiding bad requests inside the final export target.
- Added regression coverage in `tests/testthat/test-export-run.R` for:
  - graph shape and per-domain target presence
  - standalone reduction/finalization of mixed participant/event domain outputs

### Current verification

- `bash ./bin/in-env Rscript -e 'testthat::test_file("tests/testthat/test-export-run.R")'`
- `bash ./bin/in-env Rscript tests/testthat.R`

Both passed after the hidden targets graph refactor.

## Progress on `coordinator-l1n.5`

- Durable repo docs now describe the implemented architecture rather than only the intended direction:
  - `specs/implementation-plan.md` records the shared export context, reusable intermediates, registry-driven domain builders, reduction/finalization flow, and the matching hidden `targets` graph shape.
  - `specs/system-spec.md` states that export execution should reuse one shared per-export context and that the hidden graph should mirror those reusable stages rather than collapse everything into one monolithic target.
- Verification hardening now covers the targets-backed path as well as the direct runtime path.
  - `tests/testthat/test-export-run.R` now proves in `execution_mode = "targets"` that:
    - REDCap preparation happens once per export
    - `ses` + `aria` reuse shared side-data reads
    - `psg_summary` + `psg_full` reuse shared PSG lookup reads

### Current verification

- `bash ./bin/in-env Rscript -e 'testthat::test_file("tests/testthat/test-export-run.R")'`
- `bash ./bin/in-env Rscript tests/testthat.R`

Both passed on 2026-03-27 after the verification-hardening/doc-update slice landed.

### Closure note

- `coordinator-l1n` was closed on 2026-03-27 as complete.
- Follow-on performance work now lives in `.loom/workstreams/export-pipeline-hotspot-reduction/` under coordinator epic `coordinator-jor`.
