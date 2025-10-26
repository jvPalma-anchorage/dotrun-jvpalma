#!/usr/bin/env bash
### DOC
# Add dotfiles to yadm with comprehensive file selection
### DOC
#
# Stages a comprehensive set of dotfiles and configuration files to yadm,
# including system tools, AI configurations (Claude, Gemini, MCPs), custom
# scripts, and application configs. Removes cached files that shouldn't be
# tracked and displays git status diff.
#
# Usage:
#   dr yadd              # Stage all configured dotfiles to yadm
#
### DOC
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
# loadHelpers global/logging

main() {
  yadm gitconfig advice.addIgnoredFile false

  {

    yadm add -u

    # * ============ system/tools
    yadm add ~/.config/bat/*
    yadm add ~/.config/alacritty/**/*
    yadm add ~/.config/palma/** -f
    yadm add ~/.config/prompts/*.txt

    # * ============ AI Related
    # * ================ CLAUDE
    yadm add ~/.claude/agents/* -f
    yadm add ~/.claude/commands/* -f
    yadm add ~/.claude/scripts/*.sh

    # * ================ GEMINI
    yadm add ~/.gemini/

    # * ================ MCPS
    yadm add ~/.serena/
    yadm add ~/mcps/envs

    # * ================ CUSTOM
    yadm add ~/.config/ai-context -f

    yadm add ~/.config/yadm/*
    yadm add ~/.config/dotrun/**/* -f
    yadm add ~/.config/dotrun/**/*.sh -f
    yadm add ~/.config/dotrun/**/*.aliases -f
    yadm add ~/.config/dotrun/**/*.config -f
    yadm add ~/.nano/*
    yadm add ~/.jsx-migr8/*
    yadm add ~/.cloudflared/*
    yadm add ~/.gitconfig
    yadm add ~/.nanorc
    yadm add ~/.gitignore_global
    yadm add ~/.zshrc
    yadm add ~/.p10k.zsh
    yadm add ~/.prsconfig
    yadm add ~/.tmux.conf
    yadm add ~/.zshrc
    yadm add ~/palma.code-workspace

    yadm add ~/jellyfin/scripts/*.sh -f
    yadm add ~/jellyfin/docs/*.md -f
    yadm add ~/jellyfin/**/*.conf -f
    yadm add ~/jellyfin/**/*.yml -f
    yadm add ~/jellyfin/config/config/* -f
  } >/dev/null 2>&1 || true

  yadm rm --cached ~/.nano/filepos_history >/dev/null 2>&1 || true
  yadm rm --cached ~/.config/dotrun/.gitignore >/dev/null 2>&1 || true
  yadm rm --cached ~/.config/ai-context/prompts/git-prompts/commit-history/*.txt >/dev/null 2>&1 || true
  yadm rm --cached ~/.config/ai-context/prompts/git-prompts/pr-history/*.txt >/dev/null 2>&1 || true
  yadm rm --cached ~/jellyfin/qbittorrent/config/qBittorrent/qBittorrent-data.conf >/dev/null 2>&1 || true
  clear
  dr gitStatus ydiff -h
}

main "$@"
