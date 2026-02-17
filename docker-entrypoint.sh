#!/usr/bin/env bash
set -euo pipefail

args=(--work-dir /output --generate-files --clobber)

if [ -n "${COUNTRY:-}" ]; then
  args+=(--country "$COUNTRY")
fi

exec bundle exec free_zipcode_data "${args[@]}"
