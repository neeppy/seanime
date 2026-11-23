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
- `seanime-web/src/fork/**` (fork UI code; it has to live under the web app's `src`)
- `.github/workflows/fork-*.yml`

Upstream's `.gitignore` ignores `.github/*` and `*.sh`, so add new files there
with `git add -f` (once tracked, the ignore rules no longer apply).

## Hooks into upstream code

<!-- One line per hook: `path/to/file.ext` - what it does and why. -->

### Built-in player in the browser

`seanime-web/src/fork/browser-native-player.tsx` lets a plain browser play
torrent and debrid streams in the built-in player (VideoCore, the
`nativeplayer` playback type), which upstream offers only in Seanime Denshi.
It's a per-device setting (localStorage `fork-browser-native-player`), off by
default; Denshi keeps its own setting. No server change.

- `seanime-web/src/app/(main)/entry/_containers/torrent-stream/_lib/handle-torrent-stream.ts`
  and `.../debrid-stream/_lib/handle-debrid-stream.ts` - `getPlaybackType`
  asks `useForkStreamsUseNativePlayer()` instead of `__isElectronDesktop__ &&
  electronPlaybackMethod === NativePlayer` (import, hook call, condition, deps).
- `seanime-web/src/app/(main)/_features/layout/main-layout.tsx` - mounts
  `<ForkBrowserNativePlayer />`, which loads the player in a browser when enabled.
- `seanime-web/src/app/(main)/settings/_components/playback-settings.tsx` -
  shows `<ForkBrowserNativePlayerSettings />` above "Downloaded Media".
- `seanime-web/src/app/(main)/_features/playlists/_containers/global-playlist-manager.tsx` -
  tells the server the playlist's streams use the native player, so it doesn't
  tear the player down between episodes.

`isUsingNativePlayer` (the "play externally" menu items) is left as upstream
has it: in a browser those would launch the player on the server machine.

### Premiere year on later-season files

Sonarr/Plex-style names carry the series' premiere year on every season
(`Show (2022) - S02E01`), while AniList lists the sequel with its own, later
start date, so the right entry took the -10 year-mismatch penalty and fell
under the match threshold. Server-only.

- `internal/library/scanner/matcher.go` - `calculateYearScore` takes the
  file's season and returns 0 (neutral) when the season is 2+ and the file's
  year is older than the entry's start year. Every other case is unchanged.
  Tests: `internal/library/scanner/fork_year_score_test.go`.

## Building and shipping

- `fork/scripts/build.sh` builds the web UI and the Go server, like the image does.
- `fork/docker/Dockerfile` (target `hwaccel`) is the server image: Alpine,
  Jellyfin-FFmpeg and the Intel VAAPI/QSV drivers, user `seanime` (uid 1000) with
  its config in `/home/seanime/.config/Seanime`. Keep that user and path: the
  NAS mounts the existing config there.
- `.github/workflows/fork-upstream-sync.yml` merges upstream's latest release
  every Monday. A clean merge that builds goes straight to `main` and is
  released. Otherwise Claude resolves it and opens a PR labelled
  `ai-resolved` for review (merging it releases),
  or opens an issue labelled `upstream-sync` if it can't. Either way a Telegram
  message follows.

## Versions and releases

The fork's versions are its own and calendar-based: `vYEAR.MONTH.N`, the Nth
release of that month in UTC (`v2026.11.1`, `v2026.11.2`, `v2026.12.1`). No
leading zeros, so they are valid semver and sort correctly, and they never
share a name with upstream's tags (`v0.x` to `v3.x`). The app itself still
reports upstream's version (`internal/constants`, never edited here). A
version says nothing about what changed; breaking changes (e.g. one that
needs a new Tenji release) go in the release note.

- Release with `fork/scripts/release.sh ["note"]`: it tags HEAD with the next
  version and pushes it. Upstream merges release themselves.
- A version tag makes `.github/workflows/fork-image.yml` push
  `ghcr.io/neeppy/seanime:<version>` and `:latest` and create a GitHub
  Release. Pushes to `main` only update `:edge`, which nothing deploys.
- Dependabot on the homelab repo opens a PR for each new version; merging it
  deploys to the NAS.
- Upstream's own release workflow (`release-draft-new.yml`) triggers on `v*`
  tags, so it is disabled in this repo (`gh workflow disable`, a setting, not
  a file change). Local clones that fetched upstream hold upstream's tags:
  never `git push --tags` from them.
