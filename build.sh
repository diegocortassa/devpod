#!/bin/bash
set -e
# Resolve symlinks so SCRIPT_DIR points to the real source directory
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
DEVPOD_VERSION="$(< "$SCRIPT_DIR/VERSION")"

if [[ -z "$DEVPOD_VERSION" ]]; then
  printf 'Error: VERSION file is empty.\n' >&2
  exit 1
fi

if command -v podman >/dev/null 2>&1; then
  CONTAINER_RUNTIME=podman
elif command -v docker >/dev/null 2>&1; then
  CONTAINER_RUNTIME=docker
else
  printf 'Error: neither Podman nor Docker is installed.\n' >&2
  exit 1
fi

"$CONTAINER_RUNTIME" build -t devpod \
  --build-arg DEVPOD_VERSION="$DEVPOD_VERSION" \
  --build-arg USER_NAME=$USER \
  --build-arg USER_ID=$(id -u) \
  --build-arg USER_GROUP=$(id -g) \
  .