# BACH Exporter Specs

This folder defines the target architecture and durable implementation guidance for the BACH exporter system.

Live work tracking now happens in the coordinator Beads graph under epic `coordinator-d6f` (`bach-exporter: exporter-rewrite-completion`). These markdown files should stay focused on stable project guidance rather than open-task tracking.

## Document index

- [`system-spec.md`](/home/beau/documents/projects/bach-exporter/specs/system-spec.md): full architecture and product specification
- [`implementation-plan.md`](/home/beau/documents/projects/bach-exporter/specs/implementation-plan.md): durable implementation direction, migration strategy, and testing guidance
- [`shared-drive-workflow.md`](/home/beau/documents/projects/coordinator/repos/bach-exporter/specs/shared-drive-workflow.md): researcher and maintainer workflow for the simplified shared-root deployment

## Core decisions

- The end-user experience will be a local Shiny app, launched from a thin local R script.
- The thin launcher will locate a shared-drive root and then load the current shared app bundle from that shared drive.
- The first-run experience will include a small bootstrap Shiny window with a `Browse` control to select the shared-drive root path.
- Researchers will not interact with `targets` directly.
- `targets` will be retained as a hidden backend cache/orchestration layer.
- Researchers will normally consume shared data snapshots, not call the REDCap API directly from their own machines.
- The REDCap API token will not be stored in a shared folder readable by all researchers if the goal is to keep it secret from them.
- API refresh will be handled by an admin-only refresh process that writes snapshots to the shared drive.
- The normal maintainer operation should be a one-command shared-root refresh rather than a dated release ceremony.
- The admin refresh path will use `redcapAPI`, with token storage handled through `unlockREDCap()` keyrings rather than plain-text config values.
- The live package library and live `targets` store will be local per user, not shared on the network drive.

## Current baseline

- The repo already has the intended package-style layout, launcher entrypoints, and hidden backend pipeline structure.
- Shared snapshot readers exist for the named snapshot families in the spec.
- The exporter currently includes multiple implemented domains, including `participants`, `participant_screening`, `similarities`, `prose_passages`, `cognitive_screening`, and `medications`.
- The admin refresh path is built around `redcapAPI` with keyring-backed auth.
- The direct export path and the hidden `targets` path should continue to be treated as implementation details, not user-facing workflow concepts.

## Design intent

The system should preserve the current researcher workflow:

1. Launch a simple tool.
2. Tick desired domains/options.
3. Choose an output file path.
4. Produce a CSV for downstream analysis scripts.

The system should not require researchers to understand R package management, `targets`, or REDCap export details.
