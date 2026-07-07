# Pi profile

Portable source for the global Pi configuration. It enables every registered
tool by default, installs pinned releases of Pi Lens and Pi Web Access, and
provides the `Rust Analyst`, `Brainstormer`, and `Systems Analyst` profiles
for Pi, OpenCode, and Codex. It also installs the official Browse CLI skill
used by the live profile.

## Prerequisite

Install Pi first. This profile is tested with Pi `0.80.2`:

```sh
npm install --global --ignore-scripts @earendil-works/pi-coding-agent@0.80.2
```

## Install

```sh
./pi/install.sh
```

The installer:

- copies portable settings into `~/.pi/agent`;
- copies Pi's bundled preset extension from the installed Pi release;
- generates `presets.json` from `pi/profiles/*.md`;
- installs `pi-lens@3.8.62` and `pi-web-access@0.13.0`;
- installs Browse CLI `0.8.0` under an isolated profile-owned npm prefix,
  links its executable into `~/.local/bin`, copies its bundled official skill
  into `~/.agents/skills/browse`, and links that skill into Pi;
- creates a secret-free Exa configuration only when no web configuration
  already exists;
- preserves `auth.json`, sessions, existing web credentials, and all other
  unmanaged state.

To install matching OpenCode agent files:

```sh
./pi/install.sh --with-opencode
```

To install matching named Codex profiles:

```sh
./pi/install.sh --with-codex
```

Launch them as main Codex sessions:

```sh
codex --profile rust-analyst
codex --profile brainstormer
codex --profile systems-analyst
```

The generated `~/.codex/*.config.toml` files add the canonical Markdown as
`developer_instructions`. They inherit Codex's normal base instructions and
the rest of `~/.codex/config.toml`; the installer does not copy authentication,
sessions, or other Codex state.

For this dotfiles checkout, synchronize Pi, OpenCode, Codex, and the historical
files under `~/Philosophical/outputs` with:

```sh
./pi/sync-live.sh
```

## Credentials

Credentials are deliberately absent. Authenticate Pi with `/login` or provider
environment variables. Pi Web Access defaults to Exa; provide its credential
through `EXA_API_KEY`. Never commit `~/.pi/agent/auth.json`,
`~/.pi/web-search.json`, or session files.

Local Browse sessions require Chrome or Chromium. Browserbase-hosted sessions
require `BROWSERBASE_API_KEY`.

## Rust support

Pi Lens loads without Rust tooling, but the Rust Analyst profile expects the
local Rust documentation and benefits from the standard Rust components:

```sh
rustup component add rust-analyzer rust-docs clippy rustfmt
```

## Editing profiles

The tracked Markdown files under `pi/profiles/` are canonical. After editing
them, run `./pi/sync-live.sh`. Do not edit generated `presets.json` or Codex
profile TOML files directly.

## Verification

Run the repeatable fresh-home test:

```sh
./pi/tests/fresh-home.sh
```

Run the stronger disposable Distrobox test:

```sh
./pi/tests/distrobox.sh
```

Both tests verify package and Browse CLI versions, the official Browse skill,
generated profile contents, portable paths, the complete 21-tool set, Pi
preset loading, and preservation of explicit CLI tool restrictions. They also
select all three named Codex profiles and verify that their canonical instructions
reach Codex's model-visible prompt input. The Distrobox test installs the pinned
official Codex CLI in the disposable home before running that check.
