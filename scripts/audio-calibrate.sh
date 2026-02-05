#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/audio-calibrate.sh [options]

Options:
  --apply                  Apply recommended capture volume to WirePlumber and wpctl
  --keep-files             Keep the recorded WAV files
  --capture-target <name>  PipeWire source node to use as capture target
  --playback-target <name> PipeWire sink node to use as playback target
  --volume <value>         Starting capture volume (e.g., 1.0)
  -h, --help               Show this help

This tool records silence, normal speech, and wake word samples, then reports
RMS/peak levels, SNR, and suggested capture volume/multiplier settings.
EOF
}

apply_changes=false
keep_files=false
capture_target=""
playback_target=""
volume_override=""

while [ $# -gt 0 ]; do
    case "$1" in
    --apply)
        apply_changes=true
        shift
        ;;
    --keep-files)
        keep_files=true
        shift
        ;;
    --capture-target)
        capture_target="${2:-}"
        shift 2
        ;;
    --playback-target)
        playback_target="${2:-}"
        shift 2
        ;;
    --volume)
        volume_override="${2:-}"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        printf 'Unknown option: %s\n' "$1"
        usage
        exit 1
        ;;
    esac
done

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$1"
        exit 1
    fi
}

workdir="${XDG_STATE_HOME:-$HOME/.local/state}/ovos-installer/audio-calibration"
mkdir -p "$workdir"

use_pipewire=false
if command -v wpctl >/dev/null 2>&1 && command -v pw-record >/dev/null 2>&1; then
    use_pipewire=true
fi

if [ "$use_pipewire" = false ] && ! command -v arecord >/dev/null 2>&1; then
    printf '%s\n' "Neither PipeWire (wpctl/pw-record) nor arecord is available."
    exit 1
fi

if [ "$use_pipewire" = true ]; then
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

    pipewire_status="$(wpctl status 2>/dev/null || true)"
    default_source="$(printf '%s\n' "$pipewire_status" | sed -n 's/.*Audio\/Source[[:space:]]\\+\\([^[:space:]]\\+\\).*/\\1/p' | head -n1)"
    default_sink="$(printf '%s\n' "$pipewire_status" | sed -n 's/.*Audio\/Sink[[:space:]]\\+\\([^[:space:]]\\+\\).*/\\1/p' | head -n1)"
    if [ -n "$default_source" ] && printf '%s' "$default_source" | grep -q '^bluez_input'; then
        printf '%s\n' "Bluetooth source detected ($default_source). Ensure headset profile is HFP/HSP if the mic is weak."
    fi

    if [ -z "$capture_target" ] && [ -n "$default_source" ] && ! printf '%s' "$default_source" | grep -q '^echo-cancel'; then
        capture_target="$default_source"
    fi
    if [ -z "$playback_target" ] && [ -n "$default_sink" ] && ! printf '%s' "$default_sink" | grep -q '^echo-cancel'; then
        playback_target="$default_sink"
    fi

    mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
    {
        printf '%s\n' 'context.modules = ['
        printf '%s\n' '    { name = libpipewire-module-echo-cancel'
        printf '%s\n' '      args = {'
        printf '%s\n' '        aec.method = webrtc'
        printf '%s\n' '        aec.webrtc.noise_suppression = true'
        printf '%s\n' '        aec.webrtc.noise_suppression_level = 1'
        printf '%s\n' '        aec.webrtc.gain_control = true'
        printf '%s\n' '        source.name = "echo-cancel-source"'
        printf '%s\n' '        source.props = {'
        printf '%s\n' '          node.description = "OVOS Noise Suppressed Source"'
        printf '%s\n' '        }'
        printf '%s\n' '        sink.name = "echo-cancel-sink"'
        printf '%s\n' '        sink.props = {'
        printf '%s\n' '          node.description = "OVOS Noise Suppressed Sink"'
        printf '%s\n' '        }'
        if [ -n "$capture_target" ]; then
            printf '%s\n' '        capture.props = {'
            printf '          node.target = "%s"\n' "$capture_target"
            printf '%s\n' '        }'
        fi
        if [ -n "$playback_target" ]; then
            printf '%s\n' '        playback.props = {'
            printf '          node.target = "%s"\n' "$playback_target"
            printf '%s\n' '        }'
        fi
        printf '%s\n' '      }'
        printf '%s\n' '    }'
        printf '%s\n' ']'
    } >"$HOME/.config/pipewire/pipewire.conf.d/99-noise-suppression.conf"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user restart pipewire wireplumber pipewire-pulse >/dev/null 2>&1 || true
    fi

    pipewire_status="$(wpctl status 2>/dev/null || true)"
    echo_cancel_id="$(printf '%s\n' "$pipewire_status" | grep -m1 'echo-cancel-source' | grep -oE '[0-9]+' | head -n1)"
    if [ -n "$echo_cancel_id" ]; then
        wpctl set-default "$echo_cancel_id" >/dev/null 2>&1 || true
    fi

    if command -v amixer >/dev/null 2>&1 && command -v arecord >/dev/null 2>&1; then
        card_index="$(arecord -l 2>/dev/null | sed -n 's/^card[[:space:]]\\+\\([0-9]\\+\\):.*/\\1/p' | head -n1)"
        if [ -n "$card_index" ]; then
            if amixer -c "$card_index" scontrols 2>/dev/null | grep -q 'Auto Gain Control'; then
                amixer -c "$card_index" sset 'Auto Gain Control' on >/dev/null 2>&1 || true
            fi
        fi
    fi

    if [ -z "$volume_override" ]; then
        volume_override="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{print $2}' | head -n1 || true)"
    fi
    if [ -n "$volume_override" ]; then
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$volume_override" >/dev/null 2>&1 || true
    fi
fi

record_clip() {
    local label="$1"
    local path="$2"

    printf '%s\n' "$label"
    sleep 1
    if [ "$use_pipewire" = true ]; then
        timeout 6s pw-record --rate 16000 --channels 1 --format s16 "$path" || true
    else
        arecord -q -f S16_LE -r 16000 -c 1 -t wav -d 5 "$path"
    fi
}

silence_path="${workdir}/silence.wav"
speech_path="${workdir}/speech.wav"
wakeword_path="${workdir}/wakeword.wav"
rm -f "$silence_path" "$speech_path" "$wakeword_path"

record_clip "Step 1/3: 5s silence (no speech)." "$silence_path"
record_clip "Step 2/3: 5s normal speech at your usual distance." "$speech_path"
record_clip "Step 3/3: say the wake word twice at normal volume." "$wakeword_path"

analysis_output="$(SILENCE_PATH="$silence_path" SPEECH_PATH="$speech_path" WAKEWORD_PATH="$wakeword_path" CURRENT_VOLUME="${volume_override:-}" python3 - <<'PY'
import math
import os
import struct
import wave

def analyze(path):
    if not os.path.exists(path) or os.path.getsize(path) < 44:
        return None
    with wave.open(path, 'rb') as wf:
        nchan = wf.getnchannels()
        rate = wf.getframerate()
        nframes = wf.getnframes()
        data = wf.readframes(nframes)
    samples = struct.unpack('<' + 'h' * (len(data) // 2), data)
    if nchan > 1:
        samples = samples[::nchan]
    if not samples:
        return None
    s2 = sum(s * s for s in samples)
    rms = math.sqrt(s2 / len(samples))
    peak = max(abs(s) for s in samples)

    def dbfs(x):
        return float('-inf') if x <= 0 else 20.0 * math.log10(x / 32768.0)

    rms_db = dbfs(rms)
    peak_db = dbfs(peak)
    clip = sum(1 for s in samples if abs(s) >= 32760)
    clip_pct = (clip / len(samples)) * 100.0
    dur = len(samples) / rate
    return rate, dur, rms_db, peak_db, clip_pct

silence = analyze(os.environ.get('SILENCE_PATH', 'silence.wav'))
speech = analyze(os.environ.get('SPEECH_PATH', 'speech.wav'))
wake = analyze(os.environ.get('WAKEWORD_PATH', 'wakeword.wav'))

def emit(prefix, res):
    if not res:
        print(f"{prefix}_OK=false")
        return
    rate, dur, rms_db, peak_db, clip_pct = res
    print(f"{prefix}_OK=true")
    print(f"{prefix}_RATE={rate}")
    print(f"{prefix}_DUR={dur:.2f}")
    print(f"{prefix}_RMS_DB={rms_db:.1f}")
    print(f"{prefix}_PEAK_DB={peak_db:.1f}")
    print(f"{prefix}_CLIP_PCT={clip_pct:.2f}")

emit("SILENCE", silence)
emit("SPEECH", speech)
emit("WAKE", wake)

if silence and speech:
    snr = speech[2] - silence[2]
    print(f"SNR_DB={snr:.1f}")

current_volume = os.environ.get("CURRENT_VOLUME", "")
try:
    current_volume = float(current_volume)
except (TypeError, ValueError):
    current_volume = None

recommended_volume = None
if current_volume is not None and speech:
    target_rms = -26.0
    gain_db = target_rms - speech[2]
    gain = 10 ** (gain_db / 20.0)
    recommended_volume = max(0.5, min(1.2, current_volume * gain))

if recommended_volume is not None:
    print(f"RECOMMENDED_VOLUME={recommended_volume:.2f}")

recommended_multiplier = None
if speech:
    if speech[2] < -35:
        recommended_multiplier = 1.7
    elif speech[2] < -30:
        recommended_multiplier = 1.5
    elif speech[2] < -24:
        recommended_multiplier = 1.3
    else:
        recommended_multiplier = 1.1

if recommended_multiplier is not None:
    print(f"RECOMMENDED_MULTIPLIER={recommended_multiplier:.1f}")
PY
)"

printf '%s\n' "$analysis_output"

recommended_volume="$(printf '%s\n' "$analysis_output" | awk -F= '/RECOMMENDED_VOLUME=/ {print $2; exit}')"
recommended_multiplier="$(printf '%s\n' "$analysis_output" | awk -F= '/RECOMMENDED_MULTIPLIER=/ {print $2; exit}')"

if [ "$apply_changes" = true ] && [ -n "$recommended_volume" ]; then
    if [ "$use_pipewire" = true ]; then
        mkdir -p "$HOME/.config/wireplumber/wireplumber.conf.d"
        cat >"$HOME/.config/wireplumber/wireplumber.conf.d/99-ovos-capture-volume.conf" <<EOF
wireplumber.settings = {
  device.routes.default-source-volume = ${recommended_volume}
  node.stream.default-capture-volume = ${recommended_volume}
}
EOF
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$recommended_volume" >/dev/null 2>&1 || true
        printf 'Applied capture volume: %s\n' "$recommended_volume"
    fi
fi

if [ -n "$recommended_multiplier" ]; then
    printf 'Suggested listener multiplier: %s\n' "$recommended_multiplier"
fi

if [ "$keep_files" = false ]; then
    rm -f "$silence_path" "$speech_path" "$wakeword_path"
fi
