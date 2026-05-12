set shell := ["bash", "-cu"]

set-admin-shared-root SHARED_ROOT:
    Rscript scripts/set_admin_shared_root.R --shared-root "{{SHARED_ROOT}}"

validate-shared-root SHARED_ROOT:
    Rscript scripts/validate_release.R "{{SHARED_ROOT}}"

init-keyring:
    Rscript scripts/refresh_snapshots.R --init-keyring

refresh-app:
    Rscript scripts/refresh_shared_root.R --skip-refresh

refresh-data:
    Rscript scripts/refresh_snapshots.R --execute

refresh:
    just refresh-app
    just refresh-data

refresh-shared-root SHARED_ROOT:
    Rscript scripts/refresh_shared_root.R --shared-root "{{SHARED_ROOT}}"

launch:
    tmp_root="${BACH_EXPORTER_LOCAL_CACHE_DIR:-$HOME/.cache/R/bachExporter}/tmp"; \
    mkdir -p "$tmp_root"; \
    TMPDIR="$tmp_root" TMP="$tmp_root" TEMP="$tmp_root" Rscript -e 'source("R/paths.R"); source("R/config.R"); source("launch_bach_exporter.R"); launch_bach_exporter(be_load_shared_root())'
