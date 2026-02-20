import sys
import subprocess
import platform

def detect_display_server(username):
    """Detect display server (wayland/x11) for the user."""
    if platform.system() == "Darwin":
        try:
            # Aqua sessions run WindowServer on macOS.
            result = subprocess.run(
                ["pgrep", "-x", "WindowServer"],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            if result.returncode == 0:
                return "aqua"
        except Exception:
            pass
        return "N/A"

    try:
        # Get list of sessions for the user
        # loginctl list-sessions --no-legend | grep username
        # Easier to just list all and filter
        output = subprocess.check_output(["loginctl", "list-sessions", "--no-legend"], text=True).splitlines()

        user_sessions = []
        for line in output:
            parts = line.split()
            if len(parts) >= 3 and parts[2] == username:
                user_sessions.append(parts[0])

        for session_id in user_sessions:
            try:
                # Check Type
                sess_type = subprocess.check_output(
                    ["loginctl", "show-session", session_id, "-p", "Type", "--value"],
                    text=True
                ).strip()

                if sess_type == "wayland":
                    return "wayland"
                elif sess_type == "x11":
                    return "x11"
            except subprocess.CalledProcessError:
                continue

        return "N/A"

    except Exception:
        return "N/A"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)

    username = sys.argv[1]
    print(detect_display_server(username))
