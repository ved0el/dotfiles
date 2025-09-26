#!/usr/bin/env bash
set -euo pipefail

# Globals
DETECTED_OS=""
DETECTED_OS_FAMILY=""
IS_SSH=0
IS_IDE=0

detect_os() {
  local uname_s
  uname_s=$(uname -s)
  case "$uname_s" in
    Linux)
      DETECTED_OS="linux"
      if command -v apt-get >/dev/null 2>&1; then
        DETECTED_OS_FAMILY="debian"
      else
        DETECTED_OS_FAMILY="linux"
      fi
      ;;
    Darwin)
      DETECTED_OS="macos"
      DETECTED_OS_FAMILY="macos"
      ;;
    *)
      echo "Unsupported OS: $uname_s" >&2; exit 1;
      ;;
  esac
}

detect_environment() {
  # SSH detection
  if [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ] || [ -n "${SSH_CLIENT:-}" ]; then
    IS_SSH=1
  fi
  # Detect popular IDE terminals: VS Code, JetBrains
  if [ -n "${VSCODE_GIT_ASKPASS_NODE:-}" ] || [ -n "${TERM_PROGRAM:-}" ] && [[ "${TERM_PROGRAM}" == *"vscode"* ]]; then
    IS_IDE=1
  fi
  if [ -n "${JETBRAINS_IDE:-}" ] || [ -n "${IDE_PROCESS_ID:-}" ]; then
    IS_IDE=1
  fi
}

