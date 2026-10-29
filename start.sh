#!/usr/bin/env bash
# Build the static site inside the project and serve it in the foreground.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

PORT="${PORT:-3000}"
[[ "$PORT" =~ ^[1-9][0-9]*$ ]] || { echo 'PORT must be a positive integer.' >&2; exit 1; }
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
BUILD_DIR="$PROJECT_DIR/dist"

/usr/bin/time -p rm -rf "$BUILD_DIR"
/usr/bin/time -p mkdir -p "$BUILD_DIR"

# Install and build a package project when one is present.
if [[ -f "$PROJECT_DIR/package.json" ]]; then
  if [[ -f "$PROJECT_DIR/package-lock.json" ]]; then
    /usr/bin/time -p npm ci --no-audit --no-fund
  else
    /usr/bin/time -p npm install --no-audit --no-fund
  fi
  /usr/bin/time -p npm run build --if-present
fi

# The static build is the project's HTML entry point plus any asset folders.
if [[ ! -f "$BUILD_DIR/index.html" ]]; then
  /usr/bin/time -p cp "$PROJECT_DIR/index.html" "$BUILD_DIR/index.html"
  for asset_dir in assets public static; do
    if [[ -d "$PROJECT_DIR/$asset_dir" ]]; then
      /usr/bin/time -p cp -R "$PROJECT_DIR/$asset_dir/." "$BUILD_DIR/"
    fi
  done
fi
[[ -f "$BUILD_DIR/index.html" ]] || { echo "Build did not produce $BUILD_DIR/index.html" >&2; exit 1; }

/usr/bin/time -p mkdir -p "$WEB_DIR"
/usr/bin/time -p printf '{"project":"%s","directory":"%s"}\n' "$PROJECT_DIR" "$BUILD_DIR" > "$WEB_DIR/deployment-output.json"

# Serve the built directory in the foreground so the controller can reuse it.
exec /usr/bin/time -p python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$BUILD_DIR"
