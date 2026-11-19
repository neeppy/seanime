#!/usr/bin/env bash
# Builds what the fork's Docker image builds, without Docker: the web UI, then
# the Go server with the UI embedded. Used by the upstream sync workflow (and
# the AI resolving its conflicts) to prove a merge still compiles.
#
#   fork/scripts/build.sh            # web + server
#   fork/scripts/build.sh server     # server only (reuses the last web build)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
out="${BUILD_OUT:-${TMPDIR:-/tmp}/seanime-fork-build}"

if [[ "${1:-all}" != server ]]; then
  # npm ci never rewrites package-lock.json, so a build leaves the tree clean;
  # it fails if the lockfile is out of sync (fix with npm install, commit).
  echo "::group::web: npm ci"
  (cd seanime-web && npm ci --no-audit --no-fund)
  echo "::endgroup::"
  echo "::group::web: build (typecheck + rsbuild)"
  (cd seanime-web && npm run build)
  echo "::endgroup::"
  rm -rf web
  cp -r seanime-web/out web
fi

[[ -d web ]] || { echo "No ./web yet: run without 'server' first." >&2; exit 1; }

echo "::group::server: go build"
CGO_ENABLED=0 go build -trimpath -o "$out" .
echo "::endgroup::"
echo "Build OK: $out"
