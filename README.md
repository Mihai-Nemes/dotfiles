# Dotfiles

This repository stores personal shell and developer environment configuration files,
plus a setup script to apply them quickly on a new machine.

## Scope

Included in this repository:
- Core dotfiles used across environments (for example `.bashrc`, `.gitconfig`).
- Setup automation in `setup.sh` to symlink dotfiles into `$HOME`.
- Project documentation and maintenance files.

Not included in this repository:
- Secrets, tokens, private keys, or machine-specific credentials.
- Large binaries or unrelated tooling assets.
- Personal local investigation notes and Claude workspace artifacts under `.claude/` (ignored by git).

## Setup

Run the setup script from the repository root:

```bash
./setup.sh
```

The script:
- Detects the repository path.
- Backs up existing files in `$HOME` before replacing.
- Creates symlinks from repository dotfiles to `$HOME`.

## Maintenance

When adding a new dotfile:
1. Add the file to this repository.
2. Add its filename to the `DOTFILES` array in `setup.sh`.
3. Re-run `./setup.sh`.