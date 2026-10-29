#!/usr/bin/env bash
# Capture desktop and mobile screenshots of the running preview.
# Exit 75 for temporary browser/navigation failures, 1 for script defects.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

: "${CAPTURE_URL:?Set CAPTURE_URL to the preview URL.}"
: "${CAPTURE_DIR:?Set CAPTURE_DIR to an output directory outside the project.}"

CAPTURE_REAL="$(realpath -m "$CAPTURE_DIR")"
case "$CAPTURE_REAL" in
  "$PROJECT_DIR"|"$PROJECT_DIR"/*)
    echo "CAPTURE_DIR must be outside the project directory." >&2
    exit 1
    ;;
esac

/usr/bin/time -p mkdir -p "$CAPTURE_REAL"

# Wait for actual rendered content, not just the document body.
export CAPTURE_READY_SELECTOR="${CAPTURE_READY_SELECTOR:-canvas}"
export CAPTURE_URL CAPTURE_DIR="$CAPTURE_REAL"

/usr/bin/time -p node "${RUNTIME_DIR:?}/scripts/default-capture.mjs" || status=$?
status="${status:-0}"
if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi

for view in desktop mobile; do
  /usr/bin/time -p test -s "$CAPTURE_REAL/final-$view.png"
done

/usr/bin/time -p printf 'Captured %s\n' "$CAPTURE_REAL/final-desktop.png $CAPTURE_REAL/final-mobile.png"
