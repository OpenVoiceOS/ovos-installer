import sys
import os
import subprocess
import glob

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
    except Exception:
        return set()

def detect_sound_server(uid, home):
    """Detect the active sound server."""
    processes = get_process_names()

    # Check for PipeWire
    has_pipewire = "pipewire" in processes
    has_pulseaudio = "pulseaudio" in processes

    # Socket paths
    pulse_native = f"/run/user/{uid}/pulse/native"
    # WSL2 pulse socket is typically in /mnt/wslg/, passed via env but we can verify logic

    # Logic
    if has_pipewire:
        # Check if pipewire-pulse is also running or if pulseaudio is actually handling it
        # Usually pipewire acts as pulse server
        return "PipeWire"

    if has_pulseaudio:
        # Standard PulseAudio
        return "PulseAudio"

    return "N/A"

if __name__ == "__main__":
    if len(sys.argv) < 3:
        # Fallback or error
        sys.exit(1)

    uid = sys.argv[1]
    user_home = sys.argv[2]

    result = detect_sound_server(uid, user_home)
    print(result)
