#!/usr/bin/env bash

set -euo pipefail

# Dotfiles setup script:
# - creates symlinks from repo files to $HOME
# - backs up existing files that would be overwritten

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Add or remove entries based on your repo contents.
DOTFILES=(
    ".bashrc"
    ".gitconfig"
)

mkdir -p "$BACKUP_DIR"

link_file() {
    local src="$1"
    local dest="$2"

    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        echo "Already linked: $dest -> $src"
        return
    fi

    if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
        local backup_path="$BACKUP_DIR/$(basename "$dest")"
        echo "Backing up $dest to $backup_path"
        mv "$dest" "$backup_path"
    fi

    ln -s "$src" "$dest"
    echo "Linked: $dest -> $src"
}

echo "Setting up dotfiles from: $DOTFILES_DIR"

for file in "${DOTFILES[@]}"; do
    src="$DOTFILES_DIR/$file"
    dest="$HOME/$file"

    if [[ -e "$src" ]] || [[ -L "$src" ]]; then
        link_file "$src" "$dest"
    else
        echo "Skipping missing file: $src"
    fi
done

# Optional package installs (uncomment if needed):
# sudo apt-get update
# sudo apt-get install -y htop

echo "Done. Backup directory: $BACKUP_DIR"
