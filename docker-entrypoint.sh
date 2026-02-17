#!/usr/bin/env bash
set -euo pipefail

args=(--work-dir /output --generate-files --clobber)

if [ -n "${COUNTRY:-}" ]; then
  if [[ ! "$COUNTRY" =~ ^[A-Z]{2}$ ]]; then
    echo "Error: COUNTRY must be a 2-letter uppercase code (e.g., US, AD)" >&2
    exit 1
  fi
  args+=(--country "$COUNTRY")
fi

exec bundle exec ruby bin/free_zipcode_data "${args[@]}"
