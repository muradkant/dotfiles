#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-startup.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

mkdir -p "$TMP/bin"
cat >"$TMP/bin/starship" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == 'init bash' ]]
printf '%s\n' 'PROMPT_COMMAND=dotfiles_starship_precmd'
EOF
chmod +x "$TMP/bin/starship"

# The tested child shell expands this expression.
# shellcheck disable=SC2016
env -u DOTFILES_STARSHIP \
    PATH="$TMP/bin:/usr/bin" \
    bash --noprofile --rcfile "$ROOT/.bashrc" -ic \
    '[[ ${PROMPT_COMMAND-} == dotfiles_starship_precmd ]]'

printf '%s\n' 'PASS fresh interactive Bash initializes Starship without an opt-in variable'
