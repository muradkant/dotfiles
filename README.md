# Current CachyOS workstation

This branch tracks the configuration actually used on the machine: CachyOS
Hyprland with Noctalia, Kitty launching Herdr, Swash screenshots, Emacs,
Neovim, shell startup, and local search and speech services. Credentials,
logs, sessions, caches, backups, and other mutable state stay in the home
directory.

The previous workstation stack is preserved unchanged on
`archived/CachyOS-legacy`. GitHub only supports archival at repository level,
so the branch name and this notice are the branch-level archive marker.

## Restore the workstation

On CachyOS or Arch, clone into a dedicated directory:

```sh
git clone --recurse-submodules --branch current \
  https://github.com/nottzaid/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./install.sh --full
```

The installer links the live Hyprland/Noctalia/Kitty/Swash/Herdr/editor/shell
configuration, copies mutable templates, preserves replaced files in
`~/.local/state/dotfiles/backups`, installs declared Pacman packages, provisions
local services, and clones missing projects at locked commits.
Repeating it is safe. Existing project worktrees, credentials, sessions, and
user-edited service files are never reset.

The ZhiXu controller's patched DKMS driver is deliberately separate from the
user-space `--controller` setup because it rebuilds kernel modules as root. Follow
the pinned component's [driver procedure](components/linux-zhixu-controller-fix/README.md)
after reviewing the detected kernel and DKMS version. The installer never changes
Wi-Fi configuration.

## Install less

With no option, `install.sh` applies the desktop, shell, and editor links without
installing packages or optional systems.

| Option | Adds |
| --- | --- |
| `--packages` | Desktop Pacman manifest |
| `--streaming` | Wayland streaming workspace |
| `--controller` | Controller mapper and game guard |
| `--services` | Kokoro speech and SearXNG search services |
| `--projects` | Missing standalone repositories from `projects/lock.json` |
| `--full` | Every option above |

Standalone projects remain independent repositories. Directly consumed code is
pinned as a submodule. `projects/sync.sh` checks remote, commit, and cleanliness;
`--materialize` clones missing entries but never fetches or checks out an existing
worktree.

## Verify

```sh
./verify.sh
./tests/install-smoke.sh
./tests/emacs-state.sh
./tests/services-static.sh
./tests/projects-sync.sh
```

These tests use disposable homes, validate actual application configs, rebuild
the Hyprlauncher close client, exercise Emacs recovery, inspect generated systemd
units, and prove that project synchronization preserves dirty trees. For a clean
distribution boundary, run `./tests/distrobox.sh` after installing Distrobox.

## Update

```sh
git pull --ff-only
git submodule update --init --recursive
./install.sh --full
./verify.sh
```

Project upgrades are explicit lock changes followed by their relevant
tests. This keeps a fresh install reproducible without freezing credentials or
silently overwriting active work.
