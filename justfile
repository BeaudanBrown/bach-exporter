set shell := ["bash", "-cu"]

set-admin-shared-root SHARED_ROOT:
    bash ./bin/in-env Rscript scripts/set_admin_shared_root.R --shared-root "{{SHARED_ROOT}}"

validate-shared-root SHARED_ROOT:
    bash ./bin/in-env Rscript scripts/validate_release.R "{{SHARED_ROOT}}"

init-keyring:
    bash ./bin/in-env Rscript scripts/refresh_snapshots.R --init-keyring

refresh:
    bash ./bin/in-env Rscript scripts/refresh_shared_root.R

refresh-shared-root SHARED_ROOT:
    bash ./bin/in-env Rscript scripts/refresh_shared_root.R --shared-root "{{SHARED_ROOT}}"
