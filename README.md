# CachyOS workstation

Versioned Hyprland desktop, editors, shells, local agent services, and AI tool
profiles. The repository owns configuration; credentials and mutable state stay
in the home directory.

## Restore the workstation

On CachyOS or Arch, clone into a dedicated directory:

```sh
git clone --recurse-submodules --branch CachyOS \
  https://github.com/muradkant/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./install.sh --full
```

The installer links managed configuration, copies mutable templates, preserves
replaced files in `~/.local/state/dotfiles/backups`, installs declared Pacman
packages, provisions pinned Pi/OpenCode/Codex tools, and clones missing projects
at locked commits. Repeating it is safe. Existing project worktrees, credentials,
sessions, and user-edited service files are never reset.

`--full` installs independent local services immediately. Hermes and Signal stay
pending until their credentials exist. Complete that boundary explicitly:

```sh
hermes_revision=$(python3 -c '
import json
d=json.load(open("projects/lock.json"))
print(next(p["revision"] for p in d["projects"] if p["name"] == "hermes-agent"))
')
~/.hermes/hermes-agent/scripts/install.sh \
  --commit "$hermes_revision" --skip-setup
hermes setup
${EDITOR:-nvim} ~/.config/dotfiles/services.env
./install.sh --services
```

`services.env` needs the local Signal account number. The populated file is mode
600 and untracked. Hermes retains its upstream-generated base unit; dotfiles adds
only a systemd drop-in for Signal readiness.

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
| `--services` | Kokoro, SearXNG, Signal, Hermes service integration |
| `--agents` | Pinned Pi, OpenCode, Codex, Browse, and profiles |
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
./pi/tests/fresh-home.sh
```

These tests use disposable homes, validate actual application configs, rebuild
the Hyprlauncher close client, exercise Emacs recovery, inspect generated systemd
units, and prove that project synchronization preserves dirty trees. For a clean
distribution boundary—including Rust tooling—run `./pi/tests/distrobox.sh`.

## Update

```sh
git pull --ff-only
git submodule update --init --recursive
./install.sh --full
./verify.sh
```

Tool and project upgrades are explicit lock changes followed by their relevant
tests. This keeps a fresh install reproducible without freezing credentials or
silently overwriting active work.
