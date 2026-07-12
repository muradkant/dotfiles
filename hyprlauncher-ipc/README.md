# Hyprlauncher explicit-close compatibility client

The pinned `components/hyprlauncher` submodule is the maintained fork rather
than a loose source patch. Its `--close` command uses Hyprlauncher's existing
IPC protocol and completes a roundtrip before process teardown, preventing the
lost close requests reproduced with upstream 0.1.6.

`build.sh` uses the distribution CMake and pkg-config paths deliberately. It
installs the resulting binary as `~/.local/libexec/hyprlauncher-ipc`; the
packaged `/usr/bin/hyprlauncher` remains the daemon and user interface.

`hyprlauncher-toggle` prefers an official packaged `--close` implementation
after an upgrade and falls back to this client only while it is needed.
