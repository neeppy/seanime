#!/usr/bin/env bash
# Tags the next fork release at HEAD and pushes the tag, which makes
# fork-image.yml build ghcr.io/neeppy/seanime:<version> and a GitHub Release.
#
#   fork/scripts/release.sh ["release note"]
#   fork/scripts/release.sh --dry-run          # print the tag, change nothing
#
# Versions are calendar-based: vYEAR.MONTH.N, the Nth release of that month
# in UTC (v2026.11.1, v2026.11.2, v2026.12.1). No leading zeros, so they are
# also valid semver and sort correctly; Dependabot compares the image tags as
# semver. They never share a name with upstream's tags (v0.x to v3.x so far).
#
# Existing versions are read from the remote, never from local tags: a clone
# that fetched upstream also holds upstream's tags. Never `git push --tags`
# from such a clone. PUSH_URL overrides the remote (CI passes a token URL).
set -euo pipefail

dry_run=false
[[ "${1:-}" == --dry-run ]] && { dry_run=true; shift; }
[[ "${1:-}" =~ ^(-h|--help)$ ]] && { sed -n '2,15p' "$0"; exit 0; }
note="${1:-}"

cd "$(git rev-parse --show-toplevel)"
remote="${PUSH_URL:-origin}"

ours=$(git ls-remote --tags --refs "$remote" 'v*' \
  | sed -nE 's#.*refs/tags/(v[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*)$#\1#p' | sort -V)
latest=$(tail -1 <<< "$ours")

year=$(date -u +%Y)
month=$(date -u +%-m)
n=$(sed -nE "s/^v${year}\.${month}\.([0-9]+)$/\1/p" <<< "$ours" | sort -n | tail -1)
next="v${year}.${month}.$(( ${n:-0} + 1 ))"

# A clock that is wrong, or a hand-made tag from the future, must not make
# versions go backwards.
if [[ -n "$latest" && "$(printf '%s\n' "$latest" "$next" | sort -V | tail -1)" != "$next" ]]; then
  echo "Next tag ${next} would not sort after the latest, ${latest}." >&2; exit 1
fi

echo "Latest: ${latest:-none}  ->  ${next} at $(git rev-parse --short HEAD)"
$dry_run && exit 0

git tag -a "$next" -m "${note:-Release ${next}}"
git push "$remote" "refs/tags/${next}"
echo "Pushed ${next}."
