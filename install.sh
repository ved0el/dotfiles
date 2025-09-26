#!/usr/bin/env bash
set -euo pipefail

# bootstrap paths
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$REPO_ROOT/scripts"
LIB_DIR="$SCRIPTS_DIR/lib"
STEPS_DIR="$SCRIPTS_DIR/steps"

# shellcheck disable=SC1091
source "$LIB_DIR/utils.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/os.sh"

ensure_running_bash
require_tools "bash" "curl" "ln" "mkdir"

log_info "Detecting OS and environment..."
detect_os
detect_environment

log_info "OS: $DETECTED_OS ($DETECTED_OS_FAMILY), Environment: SSH=$IS_SSH, IDE=$IS_IDE"

# Steps
"$STEPS_DIR/install_packages.sh"
"$STEPS_DIR/link_dotfiles.sh"

log_success "Done. You can re-run this script safely."

