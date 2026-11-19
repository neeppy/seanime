# neeppy/seanime fork notes

A personal fork of [5rahim/seanime](https://github.com/5rahim/seanime), run as
a Docker image on a home NAS and used by the Tenji Android client.

## How the fork is organised

The aim is that upstream merges stay clean.

- Upstream's shared code stays untouched wherever possible.
- Fork features live in fork-only files, packages and prefixed database tables
  (`fork_*`), wired into upstream code with small, clearly marked hooks.
- Upstream screens the fork changes are replaced by fork-owned copies instead
  of edited in place.
- Upstream features are ported by hand when wanted.

Mark every hook in upstream code with a `// fork:` comment (`{/* fork: */}` in
JSX) and list it below, so a merge can re-apply it.

## Fork-owned files

These always keep the fork's version in a merge:

- `fork/**`
- `.github/workflows/fork-*.yml`

Upstream's `.gitignore` ignores `.github/*` and `*.sh`, so add new files there
with `git add -f` (once tracked, the ignore rules no longer apply).

## Hooks into upstream code

None yet.

<!-- One line per hook: `path/to/file.ext` - what it does and why. -->

## Building and shipping

- `fork/scripts/build.sh` builds the web UI and the Go server, like the image does.
- `fork/docker/Dockerfile` (target `hwaccel`) is the server image: Alpine,
  Jellyfin-FFmpeg and the Intel VAAPI/QSV drivers, user `seanime` (uid 1000) with
  its config in `/home/seanime/.config/Seanime`. Keep that user and path: the
  NAS mounts the existing config there.
- `.github/workflows/fork-upstream-sync.yml` merges upstream's latest release
  every Monday. A clean merge that builds goes straight to `main` and is
  released as the next patch version. Otherwise Claude resolves it and opens a
  PR labelled `ai-resolved` for review (merging it releases a patch version),
  or opens an issue labelled `upstream-sync` if it can't. Either way a Telegram
  message follows.

## Versions and releases

The fork has its own semver, starting at v1.0.0; the app itself still reports
upstream's version (`internal/constants`, never edited here).

- patch: upstream syncs and small fixes. minor: fork features. major:
  breaking changes, e.g. one that needs a new Tenji release.
- Release by tagging: `fork/scripts/release.sh patch|minor|major ["note"]`
  tags HEAD with the next `vX.Y.Z` and pushes it. Upstream merges tag
  themselves.
- A `vX.Y.Z` tag makes `.github/workflows/fork-image.yml` push
  `ghcr.io/neeppy/seanime:X.Y.Z` (also `:X.Y`, `:X`, `:latest`) and create a
  GitHub Release. Pushes to `main` only update `:edge`, which nothing deploys.
- Dependabot on the homelab repo opens a PR for each new `X.Y.Z`; merging it
  deploys to the NAS.
- Upstream's own release workflow (`release-draft-new.yml`) also triggers on
  `v*` tags, so it is disabled in this repo (`gh workflow disable`, a setting,
  not a file change). Local clones that fetched upstream hold upstream's
  `v3.x` tags: never `git push --tags` from them.
