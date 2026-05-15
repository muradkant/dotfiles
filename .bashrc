#
# ~/.bashrc
#

# Shared PATH setup for interactive and non-interactive Bash shells.
export PATH="$HOME/.local/bin:$PATH"
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
fi

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export EDITOR=nvim
eval "$(starship init bash)"

# strix
[[ -d "$HOME/.strix/bin" ]] && export PATH="$HOME/.strix/bin:$PATH"

localrec() {
    local outdir="$HOME/Videos/recordings"
    local stamp
    local outfile

    stamp="$(date +%Y-%m-%d_%H-%M-%S)"
    mkdir -p "$outdir"
    outfile="${1:-$outdir/recording-$stamp.mkv}"

    _stream_capture_with_desktop_sink wf-recorder --audio=Combined.monitor -f "$outfile"
}

_stream_capture_with_desktop_sink() {
    local desktop_sink="DesktopStream"
    local original_sink
    local input_id
    local loopback_pid=""
    local original_sink_id

    if ! command -v pactl >/dev/null 2>&1; then
        printf 'Missing pactl; cannot prepare desktop audio routing.\n' >&2
        return 1
    fi
    if ! command -v pw-loopback >/dev/null 2>&1; then
        printf 'Missing pw-loopback; cannot mirror desktop audio to speakers.\n' >&2
        return 1
    fi

    if ! pactl list short sinks | awk '{print $2}' | grep -Fxq "$desktop_sink"; then
        printf 'Missing PipeWire sink: %s\n' "$desktop_sink" >&2
        return 1
    fi

    original_sink="$(pactl get-default-sink)"
    if [[ -z "$original_sink" ]]; then
        printf 'Unable to detect current default sink.\n' >&2
        return 1
    fi
    if [[ "$original_sink" == "$desktop_sink" ]]; then
        printf 'Default sink is already %s; refusing to create a feedback loop.\n' "$desktop_sink" >&2
        return 1
    fi
    original_sink_id="$(pactl list short sinks | awk -v name="$original_sink" '$2 == name { print $1; exit }')"
    if [[ -z "$original_sink_id" ]]; then
        printf 'Unable to resolve sink id for %s\n' "$original_sink" >&2
        return 1
    fi

    _restore_stream_audio_routing() {
        local restore_sink="$1"
        local restore_loopback_pid="$2"
        local active_input

        if [[ -n "$restore_loopback_pid" ]]; then
            kill "$restore_loopback_pid" >/dev/null 2>&1 || true
            wait "$restore_loopback_pid" 2>/dev/null || true
        fi
        pactl set-default-sink "$restore_sink" >/dev/null 2>&1 || true
        while read -r active_input; do
            [[ -n "$active_input" ]] || continue
            pactl move-sink-input "$active_input" "$restore_sink" >/dev/null 2>&1 || true
        done < <(pactl list short sink-inputs | awk -v sink="$desktop_sink" '$2 == sink { print $1 }')
    }

    if ! pactl set-default-sink "$desktop_sink"; then
        return 1
    fi
    while read -r input_id; do
        [[ -n "$input_id" ]] || continue
        pactl move-sink-input "$input_id" "$desktop_sink" >/dev/null 2>&1 || true
    done < <(pactl list short sink-inputs | awk -v sink_id="$original_sink_id" '$2 == sink_id { print $1 }')

    pw-loopback \
        --name ytlive-speaker-mirror \
        --capture "$desktop_sink" \
        --capture-props '{"stream.capture.sink":true,"stream.dont-remix":true,"node.passive":true}' \
        --playback "$original_sink" \
        --playback-props '{"stream.dont-remix":true,"node.passive":true}' \
        >/dev/null 2>&1 &
    loopback_pid=$!

    trap '_restore_stream_audio_routing "$original_sink" "$loopback_pid"' EXIT INT TERM

    "$@"
    local status=$?

    trap - EXIT INT TERM
    _restore_stream_audio_routing "$original_sink" "$loopback_pid"
    unset -f _restore_stream_audio_routing
    return "$status"
}

ytlive() {
    local key_file="$HOME/.config/youtube/rtmp_key"
    local stream_key

    if [[ ! -f "$key_file" ]]; then
        printf 'Missing YouTube key file: %s\n' "$key_file" >&2
        return 1
    fi

    stream_key="$(grep -v '^[[:space:]]*#' "$key_file" | sed '/^[[:space:]]*$/d' | head -n 1)"
    if [[ -z "$stream_key" ]]; then
        printf 'Paste your YouTube RTMP key into %s\n' "$key_file" >&2
        return 1
    fi

    _stream_capture_with_desktop_sink \
    wf-recorder \
        --audio=Combined.monitor \
        -m flv \
        -c libx264 \
        -C aac \
        -r 30 \
        -x yuv420p \
        -p preset=veryfast \
        -p tune=zerolatency \
        -p b=6000k \
        -p maxrate=6000k \
        -p bufsize=12000k \
        -p g=60 \
        -p keyint_min=60 \
        -P b=160k \
        -f "rtmps://a.rtmp.youtube.com/live2/$stream_key"
}
