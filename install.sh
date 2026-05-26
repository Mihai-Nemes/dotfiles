#!/bin/bash
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE="$HOME/.claude"
mkdir -p "$CLAUDE"

ln -sf "$DOTFILES/.claude/settings.json" "$CLAUDE/settings.json"
ln -sf "$DOTFILES/.claude/CLAUDE.md"     "$CLAUDE/CLAUDE.md"
ln -sf "$DOTFILES/.claude/skills"        "$CLAUDE/skills"