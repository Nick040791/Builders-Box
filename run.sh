#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Stop any running containers created from this image (they hold 8080/5173).
OLD_CONTAINERS="$(docker ps -q --filter "ancestor=builders-box" 2>/dev/null || true)"
if [ -n "${OLD_CONTAINERS}" ]; then
  echo "Stopping existing builders-box containers..."
  docker stop ${OLD_CONTAINERS} >/dev/null 2>&1 || true
  docker rm ${OLD_CONTAINERS} >/dev/null 2>&1 || true
fi

# Stop any other container publishing the ports we need.
for cid in $(docker ps -q 2>/dev/null); do
  ports="$(docker inspect --format '{{range $p,$conf := .NetworkSettings.Ports}}{{$p}} {{end}}' "$cid" 2>/dev/null || true)"
  if echo "$ports" | grep -qE '(^| )(8080/tcp|5173/tcp)( |$)'; then
    echo "Stopping container $cid (uses port 8080/5173)..."
    docker stop "$cid" >/dev/null 2>&1 || true
    docker rm "$cid" >/dev/null 2>&1 || true
  fi
done

# Give the OS a moment to release the ports.
sleep 1

# Free the host ports if a non-Docker process is still holding them.
for port in 8080 5173; do
  if ss -ltn 2>/dev/null | grep -q ":${port} "; then
    echo "Port ${port} in use on host; attempting to free it..."
    fuser -k "${port}/tcp" >/dev/null 2>&1 || true
    sleep 1
  fi
done

# Final check.
for port in 8080 5173; do
  if ss -ltn 2>/dev/null | grep -q ":${port} "; then
    echo "Error: port ${port} is still in use. Free it and retry." >&2
    exit 1
  fi
done

# Build the image if it isn't present yet.
if ! docker image inspect builders-box:latest >/dev/null 2>&1; then
  docker build --pull --rm -f "${ROOT}/Dockerfile" -t builders-box "${ROOT}"
fi

GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' "${ROOT}/.env")" docker run -it --rm \
  -v "${ROOT}:/workspace" \
  -v "${HOME}/.claude/.credentials.json:/root/.claude/.credentials.json" \
  -v "${ROOT}/.claude/agents:/root/.claude/agents" \
  -e GH_TOKEN \
  -w /workspace \
  -p 8080:8080 -p 5173:5173 \
  builders-box
