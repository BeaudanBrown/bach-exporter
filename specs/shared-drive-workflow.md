# Shared-Drive Workflow

## Admin setup

1. Choose the shared-drive root and persist it locally once:
   - `just set-admin-shared-root /path/to/shared/root`
2. Initialize the REDCap keyring on the admin machine:
   - `just init-keyring`
3. Run the normal shared-root refresh:
   - `just refresh`

After `just refresh`, the shared root should contain:

- `app/` with the current runnable backend bundle
- `app/manifest.json` with the current `build_id`
- `snapshots/` with the latest admin-refreshed data
- `side-data/` with shared lookup tables

## Researcher workflow

1. Download the thin launcher script and open it in RStudio.
2. On first launch, browse to the shared-drive root.
3. The launcher validates `app/`, stores the shared root locally, restores any missing local packages, installs the current app build locally, and opens the Shiny app.
4. In the app, choose export options, choose an output CSV path, and run the export.

Researchers do not need REDCap credentials and do not need to know the current `build_id`.

## Maintainer updates

Use `just refresh` as the default maintenance command.

That command should:

1. stage the current repo into a validated shared app bundle
2. replace `<shared_root>/app`
3. copy shared side-data
4. run the admin snapshot refresh

If the app code changed, the new `build_id` causes researcher machines to install the new build on next launch. If only the data changed, researchers still get the latest shared snapshots without any extra manual step.

## Validation and troubleshooting

- Validate a shared root explicitly with `just validate-shared-root /path/to/shared/root`.
- The maintainer shared root persists in local `admin-refresh.json`.
- The researcher shared root persists in local `shared-root.json`.
- `BACH_SHARED_ROOT` is intentionally not used as a normal config source. Keep `.env` for REDCap connection settings and use `set-admin-shared-root` or `--shared-root` for the shared folder path.
- Local package libraries and `targets` stores stay per-user and are keyed by `build_id`.
