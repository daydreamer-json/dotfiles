#!/usr/bin/env bash
set -euo pipefail

BOLD=$'\033[1m'
DIM=$'\033[2m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
WHITE=$'\033[37m'
RESET=$'\033[0m'

info()  { printf "  ${BLUE}ℹ${RESET}  %s\n" "$*"; }
dry()   { printf "  ${MAGENTA}⚡${RESET}  %s\n" "$*"; }
header(){ printf "\n${BOLD}${CYAN}━━━ %s ━━━${RESET}\n" "$*"; }

usage() {
  echo "Usage: $0 [--dry-run]"
  exit 0
}

DRY_RUN=false
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --help|-h) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
  shift
done

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

run() {
  if $DRY_RUN; then
    dry "(dry-run) $*"
  else
    "$@"
  fi
}

link_file() {
  local src="$DOTFILES_DIR/$1" dest="${2:+$HOME/$2}"
  dest="${dest:-$HOME/$1}"
  echo "    📄 file:      ${CYAN}$1${RESET}"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest" 2>/dev/null || echo "")"
    if [ "$current" = "$src" ]; then
      echo "       ${BOLD}${GREEN}file stat:${RESET} ${GREEN}✓${RESET}  ${DIM}already linked correctly, skipping${RESET}"
      return
    fi
    echo "       ${BOLD}${YELLOW}file stat:${RESET} exists, backing up ${YELLOW}→${RESET} ${WHITE}$dest.bak${RESET}"
    run mv "$dest" "$dest.bak"
  else
    echo "       ${BOLD}${GREEN}file stat:${RESET} not found, will create"
  fi
  run ln -s "$src" "$dest"
  echo "       ${BOLD}${BLUE}file link:${RESET} ${WHITE}$dest${RESET} ${YELLOW}→${RESET} ${WHITE}$src${RESET}"
}

link_dir() {
  local src="$DOTFILES_DIR/$1" dest="${2:+$HOME/$2}"
  dest="${dest:-$HOME/$1}"
  echo "    📁 dir:       ${CYAN}$1${RESET}"
  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest" 2>/dev/null || echo "")"
    if [ "$current" = "$src" ]; then
      echo "       ${BOLD}${GREEN}dir  stat:${RESET} ${GREEN}✓${RESET}  ${DIM}already linked correctly, skipping${RESET}"
      return
    fi
    echo "       ${BOLD}${YELLOW}dir  stat:${RESET} existing symlink points elsewhere, removing"
    run rm "$dest"
  elif [ -d "$dest" ]; then
    echo "       ${BOLD}${YELLOW}dir  stat:${RESET} real directory exists, backing up ${YELLOW}→${RESET} ${WHITE}$dest.bak${RESET}"
    run mv "$dest" "$dest.bak"
  else
    echo "       ${BOLD}${GREEN}dir  stat:${RESET} not found, will create"
  fi
  run ln -s "$src" "$dest"
  echo "       ${BOLD}${BLUE}dir  link:${RESET} ${WHITE}$dest${RESET} ${YELLOW}→${RESET} ${WHITE}$src${RESET}"
}

header "🔗 Linking dotfiles ..."
echo ""
info  "dotfiles dir: ${BOLD}$DOTFILES_DIR${RESET}"
info  "home dir:     ${BOLD}$HOME${RESET}"
echo ""

link_file .bashrc
link_file .gitconfig

link_dir .config/fontconfig
link_dir .config/mpv
link_dir .config/pipewire
link_dir .config/wireplumber

link_file .config/starship.toml

header "✅ All done!"
