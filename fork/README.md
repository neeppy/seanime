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
- `.github/workflows/fork-image.yml` pushes
  `ghcr.io/neeppy/seanime:<version>-fork.<run>` on every push to `main`.
  Renovate on the homelab repo opens a PR bumping that tag; merging it deploys.
- `.github/workflows/fork-upstream-sync.yml` merges upstream's latest release
  every Monday. A clean merge that builds goes straight to `main`. Otherwise
  Claude resolves it and opens a PR labelled `ai-resolved` for review, or opens
  an issue labelled `upstream-sync` if it can't. Either way a Telegram message
  follows.
