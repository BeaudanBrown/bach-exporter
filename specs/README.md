# BACH Exporter Specs

This folder defines the target architecture and delivery plan for the new BACH exporter system.

These documents are intended for a fresh implementation agent. They should be treated as the source of truth for what to build in this repository.

## Document index

- [`system-spec.md`](/home/beau/documents/projects/bach-exporter/specs/system-spec.md): full architecture and product specification
- [`implementation-plan.md`](/home/beau/documents/projects/bach-exporter/specs/implementation-plan.md): step-by-step plan for building the system from this blank repository

## Core decisions

- The end-user experience will be a local Shiny app, launched from a thin local R script.
- The thin launcher will locate a shared-drive root and then load the current backend release from that shared drive.
- The first-run experience will include a small bootstrap Shiny window with a `Browse` control to select the shared-drive root path.
- Researchers will not interact with `targets` directly.
- `targets` will be retained as a hidden backend cache/orchestration layer.
- Researchers will normally consume shared data snapshots, not call the REDCap API directly from their own machines.
- The REDCap API token will not be stored in a shared folder readable by all researchers if the goal is to keep it secret from them.
- API refresh will be handled by an admin-only refresh process that writes snapshots to the shared drive.
- The admin refresh path will use `redcapAPI`, with token storage handled through `unlockREDCap()` keyrings rather than plain-text config values.
- The live package library and live `targets` store will be local per user, not shared on the network drive.

## Design intent

The system should preserve the current researcher workflow:

1. Launch a simple tool.
2. Tick desired domains/options.
3. Choose an output file path.
4. Produce a CSV for downstream analysis scripts.

The system should not require researchers to understand R package management, `targets`, or REDCap export details.
