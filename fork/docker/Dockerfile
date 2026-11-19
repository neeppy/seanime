# syntax=docker/dockerfile:1.7
#
# The fork's server image: the web UI embedded in the Go binary, on Alpine with
# Jellyfin-FFmpeg and the Intel VAAPI/QSV drivers for the NAS's iGPU. Same
# layout as the `hwaccel` target of umag/seanime-docker, which the NAS ran
# before, so it drops in for umagistr/seanime:latest-hwaccel:
#
#   - user `seanime`, uid/gid 1000, home /home/seanime
#   - binary at /app/seanime, port 43211
#   - no SEANIME_DATA_DIR: Seanime keeps its config in $HOME/.config/Seanime,
#     which is where the NAS bind-mounts the existing config folder. Changing
#     the user, the home folder or setting SEANIME_DATA_DIR would start with
#     an empty config.
#
# Build from the repo root:
#   docker build -f fork/docker/Dockerfile -t seanime:dev .

# Web UI. Node 22 and `npm ci` as in upstream's CI.
FROM --platform=$BUILDPLATFORM node:22-bookworm AS web
WORKDIR /src/seanime-web
COPY seanime-web/package.json seanime-web/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --no-audit --no-fund
COPY seanime-web/ ./
RUN npm run build

# Server. `go build` embeds ./web (main.go: //go:embed all:web). The image's Go
# fetches the exact toolchain go.mod asks for.
FROM --platform=$BUILDPLATFORM golang:1-bookworm AS server
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . ./
COPY --from=web /src/seanime-web/out ./web
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/seanime .

FROM alpine:edge AS hwaccel
ARG TARGETARCH

RUN apk add --no-cache ca-certificates tzdata curl && \
    addgroup -S seanime -g 1000 && \
    adduser -S seanime -G seanime -u 1000

# Jellyfin-FFmpeg from Jellyfin's Alpine repo; Intel media drivers on amd64.
RUN PACKAGES="jellyfin-ffmpeg mesa-va-gallium opencl-icd-loader" && \
    if [ "$TARGETARCH" = "amd64" ]; then \
      PACKAGES="$PACKAGES libva-intel-driver intel-media-driver libvpl" && \
      apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing onevpl-intel-gpu; \
    fi && \
    apk add --no-cache --repository=https://repo.jellyfin.org/releases/alpine/ $PACKAGES && \
    chmod +x /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/lib/jellyfin-ffmpeg/ffprobe && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffprobe /usr/bin/ffprobe

COPY --from=server --chown=1000:1000 /out/seanime /app/seanime

USER 1000
WORKDIR /app
EXPOSE 43211

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:43211 || exit 1

CMD ["/app/seanime"]
