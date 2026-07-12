# Portable Pi profile

One canonical profile set for Pi, OpenCode, and Codex. It enables Pi's complete
registered tool surface by default, pins Pi Lens, Pi Web Access, and Browse CLI,
and generates three named agents from tracked Markdown:

- **Rust Analyst** searches the locally installed Rust corpus before answering.
- **Systems Analyst** grounds Linux and DevOps guidance in the local systems
  corpus and extends that corpus from primary sources when necessary.
- **Brainstormer** exposes reasoning and challenges assumptions without stealing
  the user's judgment.

## Install

Install the pinned toolchain and profiles:

```sh
./pi/install.sh --with-opencode --with-codex
```

The installer:

- installs Pi 0.80.6, OpenCode 1.17.18, and Codex 0.144.1 under `~/.local`;
- copies portable Pi settings and Pi's bundled preset extension;
- generates `presets.json` from `pi/profiles/*.md`;
- installs `pi-lens@3.8.69` and `pi-web-access@0.13.0`;
- installs Browse CLI 0.9.5 in an isolated prefix, its official bundled skill
  under `~/.agents/skills/browse`, and links both into the expected locations;
- optionally generates matching OpenCode agents and Codex profiles;
- creates a secret-free Exa configuration only when none exists; and
- backs up changed managed files while preserving credentials, sessions, web
  keys, and every unmanaged path.

Run a profile as the main Codex session:

```sh
codex --profile rust-analyst
codex --profile brainstormer
codex --profile systems-analyst
```

Generated Codex TOML embeds the canonical Markdown as developer instructions
while inheriting normal Codex configuration and authentication.

## Credentials and optional tools

Authenticate Pi through `/login` or provider environment variables. Exa uses
`EXA_API_KEY`; Browserbase-hosted sessions use `BROWSERBASE_API_KEY`. Local
Browse sessions need Chrome or Chromium. No secret belongs in this repository.

Rust Analyst benefits from:

```sh
rustup component add rust-analyzer rust-docs clippy rustfmt
```

## Edit and synchronize

`pi/profiles/*.md` is authoritative. Never edit generated `presets.json` or
Codex profile TOML directly. After changing a profile:

```sh
./pi/sync-live.sh
```

That command synchronizes Pi, OpenCode, Codex, and the historical copies under
`~/Philosophical/outputs`.

## Verify

```sh
./pi/tests/fresh-home.sh
./pi/tests/distrobox.sh
```

The first uses a temporary home; the second builds a disposable distribution
environment. Together they verify package pins, Browse and its official skill,
all 22 Pi tools, preset loading, portable paths, explicit tool restrictions,
the three Codex profiles, and instruction visibility at the model boundary.
