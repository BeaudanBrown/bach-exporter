# Export Performance Refactor Context

## Objective

Refactor the current export path so broad researcher exports stop repeating the same expensive preparation work across domains, and so the hidden `targets` backend can later benefit from reusable intermediate/domain targets rather than a single monolithic `export_data` target.

## Why this lane exists

A review on 2026-03-26 found four structural costs in the current export path:

1. Most domain builders call `be_prepare_redcap_snapshot()` and `be_filter_years()` internally, so an all-domain export repeatedly cleans and slices the full REDCap snapshot.
2. `be_assemble_export()` builds one ever-wider output table through a long serial merge chain, so later domains pay to copy and merge the accumulated result again.
3. Several domains rebuild upstream intermediates or reread side-data instead of reusing shared per-export results.
4. The hidden `targets` graph is too coarse to reuse work across similar exports or to benefit much from future `crew` parallelisation.

## Current workstream

- Beads epic: `coordinator-l1n`
- Current claimed slice: `coordinator-l1n.4`
- Branch: `master`
- Repo-local docs for this lane:
  - `.loom/workstreams/export-performance-refactor/context.md`
  - `.loom/workstreams/export-performance-refactor/handoff.md`
  - `.loom/workstreams/export-performance-refactor/prompt.md`

## Refactor direction

1. Introduce one shared export context per run:
   - raw REDCap snapshot
   - prepared/split snapshot
   - year-filtered and participant-filtered views
   - scaffold and other shared per-export data
2. Convert builders to consume prepared input rather than normalizing raw snapshots themselves.
3. Extract reusable intermediates for scaffold, baseline demographics, SES/ARIA lookup data, PSG lookup data, and other repeated inputs.
4. Replace the manual domain `if` chain in `be_assemble_export()` with a registry-driven assembly flow and separate event-level/participant-level merge phases.
5. Split the hidden `targets` graph into reusable prepared/intermediate/domain targets only after the runtime assembly can genuinely reuse them.

## Constraints

- Keep the researcher-facing workflow unchanged: launch app, choose options, write CSV.
- Keep `run_export()` as the stable entrypoint.
- Do not surface `targets` details in the UI.
- Preserve current correctness and test coverage while refactoring the hot path.
- Prefer staged refactors that keep each slice reviewable and verifiable.
