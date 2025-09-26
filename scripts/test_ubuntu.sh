#!/usr/bin/env bash
set -euo pipefail

# Quick local test using Docker Ubuntu
# Requires: docker

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

IMAGE="ubuntu:24.04"
CONTAINER_NAME="dotfiles-test-ubuntu"
MODE="normal"  # normal|ssh|ide

usage() {
  echo "Usage: $0 [-m normal|ssh|ide]";
}

while getopts ":m:h" opt; do
  case $opt in
    m) MODE="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2; exit 1
fi

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

echo "Starting container $CONTAINER_NAME ($IMAGE) with mode=$MODE" 

ENV_FLAGS=()
case "$MODE" in
  ssh) ENV_FLAGS+=("-e" "SSH_CONNECTION=1");;
  ide) ENV_FLAGS+=("-e" "TERM_PROGRAM=vscode");;
  normal) : ;;
  *) echo "Invalid mode: $MODE" >&2; exit 1 ;;
esac

docker run -it --name "$CONTAINER_NAME" \
  -v "$REPO_ROOT":/repo \
  "${ENV_FLAGS[@]}" \
  $IMAGE bash -lc "\
    set -euo pipefail; \
    apt-get update -y >/dev/null; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates git >/dev/null; \
    cd /repo; \
    bash ./install.sh && echo 'INSTALL SUCCESS' || (echo 'INSTALL FAILED' && exit 1) \
  "

