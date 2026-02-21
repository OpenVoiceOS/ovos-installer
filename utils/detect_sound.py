import os
import platform
import subprocess


def get_process_names():
    """Return a set of running process names."""
    try:
        output = subprocess.check_output(["pgrep", "-a", "."], text=True).splitlines()
        processes = set()
        for line in output:
            parts = line.split(" ", 1)
            if len(parts) > 1:
                cmd = parts[1].split()[0]
                processes.add(os.path.basename(cmd))
        return processes
    except (subprocess.CalledProcessError, OSError):
        return set()


def detect_sound_server():
    """Detect the active sound server."""
    if platform.system() == "Darwin":
        # macOS uses CoreAudio as the native audio stack.
        return "CoreAudio"

    processes = get_process_names()

    has_pipewire = "pipewire" in processes
    has_pipewire_pulse = "pipewire-pulse" in processes
    has_pulseaudio = "pulseaudio" in processes

    if has_pipewire or has_pipewire_pulse:
        return "PipeWire"

    if has_pulseaudio:
        return "PulseAudio"

    return "N/A"


if __name__ == "__main__":
    print(detect_sound_server())
