#!/usr/bin/env bash
# Where speech recognition (STT) and speech synthesis (TTS) run.
#
#   public  the Open Voice OS defaults: both go to the community servers.
#   local   the onnx-asr and phoonnx plugins ovos-config recommends for the
#           locale run on this host, with the public STT server as fallback.
#
# Local speech only gives a usable assistant on a Raspberry Pi 5 with 8 GB or a
# machine at least as capable, so everything below that is kept on public.

# Total memory in MiB, or 0 when it cannot be read.
function total_memory_mb() {
    local memory_bytes=""

    case "$(uname -s 2>/dev/null || true)" in
    Darwin)
        memory_bytes="$(sysctl -n hw.memsize 2>/dev/null || true)"
        if [[ "$memory_bytes" =~ ^[0-9]+$ ]]; then
            printf '%s\n' "$((memory_bytes / 1048576))"
            return 0
        fi
        ;;
    *)
        if [ -r /proc/meminfo ]; then
            awk '/^MemTotal:/ { printf "%d\n", $2 / 1024; found = 1 } END { if (!found) print 0 }' /proc/meminfo
            return 0
        fi
        ;;
    esac

    printf '%s\n' "0"
}

# Whether this host can run local speech at all, whatever the user picks later.
#
# No Raspberry Pi other than the Pi 5 family qualifies, whatever its memory: a
# Pi 4 with 8 GB passes the memory test and still cannot keep up. Any other
# machine needs the SIMD instructions onnxruntime is built for and a 64-bit
# userland, since onnxruntime publishes no 32-bit wheels and none for Intel
# Macs. An 8 GB board reports less than 8192 MiB once firmware and kernel have
# taken their share, which is why the floor sits at 7.5 GiB.
function local_speech_hardware_supported() {
    [ "${CPU_IS_CAPABLE:-false}" == "true" ] || return 1
    [ "$(getconf LONG_BIT 2>/dev/null || echo 0)" == "64" ] || return 1

    case "$(uname -s 2>/dev/null || true)-$(uname -m 2>/dev/null || true)" in
    Linux-x86_64 | Linux-aarch64 | Darwin-arm64) ;;
    *) return 1 ;;
    esac

    if [ "${RASPBERRYPI_MODEL:-N/A}" != "N/A" ] &&
        ! [[ "$RASPBERRYPI_MODEL" =~ $RASPBERRY_PI_5_FAMILY_REGEX ]]; then
        return 1
    fi

    [ "${TOTAL_MEMORY_MB:-0}" -ge "$LOCAL_SPEECH_MIN_MEMORY_MB" ]
}

# Requires detect_cpu_instructions and is_raspberrypi_soc to have run.
function detect_local_speech_support() {
    printf '%s' "➤ Checking local speech support... "
    TOTAL_MEMORY_MB="$(total_memory_mb)"
    export TOTAL_MEMORY_MB

    if local_speech_hardware_supported; then
        export LOCAL_SPEECH_CAPABLE="true"
    else
        export LOCAL_SPEECH_CAPABLE="false"
    fi
    echo -e "[${done_format:-done}]"
}

# Capable hardware is not enough. Local speech is only offered on the alpha
# channel, the container images do not carry its plugins, and a server has no
# audio to process.
function local_speech_available() {
    [ "${LOCAL_SPEECH_CAPABLE:-false}" == "true" ] &&
        [ "${CHANNEL:-}" == "alpha" ] &&
        [ "${METHOD:-}" == "virtualenv" ] &&
        [ "${PROFILE:-}" != "server" ]
}

# Settle SPEECH_ENGINE before the playbook runs. A scenario file, an earlier
# run's state or a choice made before going back and changing the channel can
# all ask for local where it is not available; those runs get public.
function normalize_speech_engine() {
    if [ "${SPEECH_ENGINE:-}" == "local" ] && ! local_speech_available; then
        echo "Local speech needs the alpha channel, a virtualenv install, a profile with audio and a Raspberry Pi 5 with 8 GB or an equivalent machine. Using the public servers instead." | tee -a "$LOG_FILE"
    fi

    if [ "${SPEECH_ENGINE:-}" == "local" ] && local_speech_available; then
        export SPEECH_ENGINE="local"
    else
        export SPEECH_ENGINE="public"
    fi
}
