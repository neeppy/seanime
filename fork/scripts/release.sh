#!/usr/bin/env bash
# Tags the next fork release (vX.Y.Z) at HEAD and pushes the tag, which makes
# fork-image.yml build ghcr.io/neeppy/seanime:X.Y.Z and a GitHub Release.
#
#   fork/scripts/release.sh patch|minor|major ["release note"]
#   fork/scripts/release.sh --dry-run minor       # print the tag, change nothing
#
# patch: upstream syncs and small fixes. minor: fork features. major: breaking
# changes, e.g. one that needs a new Tenji release.
#
# The fork's versions are its own (they started at v1.0.0) and are read from
# origin, never from local tags: a clone that fetched upstream also holds
# upstream's v3.x tags. Never `git push --tags` from such a clone.
#
# PUSH_URL overrides where the tag goes (CI passes a URL with a token).
set -euo pipefail

dry_run=false
[[ "${1:-}" == --dry-run ]] && { dry_run=true; shift; }
bump="${1:-}"
note="${2:-}"
[[ "$bump" =~ ^(patch|minor|major)$ ]] || { sed -n '2,15p' "$0" >&2; exit 2; }

cd "$(git rev-parse --show-toplevel)"
remote="${PUSH_URL:-origin}"

latest=$(git ls-remote --tags --refs "$remote" 'v*' \
  | sed -nE 's#.*refs/tags/(v[0-9]+\.[0-9]+\.[0-9]+)$#\1#p' \
  | sort -V | tail -1)

if [[ -z "$latest" ]]; then
  next=v1.0.0
else
  IFS=. read -r major minor patch <<< "${latest#v}"
  case "$bump" in
    patch) patch=$((patch + 1)) ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    major) major=$((major + 1)); minor=0; patch=0 ;;
  esac
  next="v${major}.${minor}.${patch}"
fi

if git ls-remote --exit-code --tags "$remote" "refs/tags/${next}" >/dev/null; then
  echo "${next} already exists on the remote." >&2; exit 1
fi

echo "Latest: ${latest:-none}  ->  ${next} at $(git rev-parse --short HEAD)"
$dry_run && exit 0

git tag -a "$next" -m "${note:-Release ${next}}"
git push "$remote" "refs/tags/${next}"
echo "Pushed ${next}."
