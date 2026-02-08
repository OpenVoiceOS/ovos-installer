import sys
import os
import subprocess

def get_process_names():
    """Return a set of running process names."""
    try:
        # pgrep -a . returns full command lines
        output = subprocess.check_output(["pgrep", "-a", "."], text=True).splitlines()
        processes = set()
        for line in output:
            parts = line.split(" ", 1)
            if len(parts) > 1:
                # Get the command name (basename)
                cmd = parts[1].split()[0]
                processes.add(os.path.basename(cmd))
        return processes
    except (subprocess.CalledProcessError, OSError):
        return set()

def detect_sound_server():
    """Detect the active sound server."""
    processes = get_process_names()

    # Check for PipeWire
    has_pipewire = "pipewire" in processes
    has_pipewire_pulse = "pipewire-pulse" in processes
    has_pulseaudio = "pulseaudio" in processes

    # Logic
    if has_pipewire or has_pipewire_pulse:
        return "PipeWire"

    if has_pulseaudio:
        # Standard PulseAudio
        return "PulseAudio"

    return "N/A"

if __name__ == "__main__":
    result = detect_sound_server()
    print(result)
