#!/usr/bin/env bash
# Re-usable logging functions for any dr script

# shellcheck disable=SC1091,SC2088,SC2164,SC2034,SC2154
set -euo pipefail

loadHelpers global/colors

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}
