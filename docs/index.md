Last Edit: Codex (GPT-6) - 2026-10-08 - Motive: Index installer guides and local-speech maintenance evidence.

# Installer documentation

The installer selects a supported installation method, writes configuration and
manages OVOS services. Start with the [README](../README.md).

| Guide | Scope |
| --- | --- |
| [Supported systems](supported-systems.md) | Hardware, operating systems and installation methods |
| [Automation](automation.md) | Scenarios, environment variables and public speech fallback |
| [macOS](macos.md) | Native macOS prerequisites and operation |
| [Services](services.md) | Starting, stopping and checking OVOS |
| [Terminal client](terminal-client.md) | Using OVOS without a microphone |
| [Troubleshooting](troubleshooting.md) | Diagnosing installation and runtime problems |
| [Telemetry](telemetry.md) | Optional data sharing |
| [Architecture](architecture.md) | Installer orchestration and roles |

Local speech is selected by `first_working()` in
[speech_setup.py](../ansible/roles/ovos_config/files/speech_setup.py).
`forget_model()` removes rejected recognizer downloads only when they did not
exist before this run. `with_public_fallback()` retains the public server
settings; [speech.yml](../ansible/roles/ovos_config/tasks/speech.yml) applies them.
[`SpeechSetupTest`](../scripts/test_speech_setup.py) exercises these paths using
stub plugins and real child processes, without downloading models.

Maintenance evidence: [audit](../AUDIT.md), [change log](../MAINTENANCE_REPORT.md),
[quick facts](../QUICK_FACTS.md), [FAQ](../FAQ.md) and [suggestions](../SUGGESTIONS.md).
