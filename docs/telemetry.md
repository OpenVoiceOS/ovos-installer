# Open Voice OS installer telemetry

Usage data helps improve software. To get this data, some information passes from the user to the developers.

**The installer asks you separately about each of the two options below. Both are off unless you accept them.**

## Installer telemetry

The installer sends one payload to `https://telemetry.smartgic.io/ovos-installer/metrics/` while it runs. It collects nothing after the installation ends.

To fill the `country` field, the installer asks `http://ip-api.com/json` to look up the location of the host. That request tells a third-party service your IP address. Decline installer telemetry if you do not want that lookup to happen.

The table below lists the collected data. See the [Ansible task](https://github.com/OpenVoiceOS/ovos-installer/blob/main/ansible/roles/ovos_telemetry/tasks/main.yml) that builds and sends the telemetry payload.

| Data                    | Description                                             |
| ----------------------- | -------------------------------------------------------- |
| `architecture`          | CPU architecture where OVOS was installed                |
| `channel`               | `testing` or `alpha` version of OVOS                     |
| `container`             | OVOS installed into containers                           |
| `country`               | Country where OVOS was installed                          |
| `cpu_capable`           | Whether the CPU supports AVX2 or SIMD instructions        |
| `display_server`        | Whether X or Wayland is used as the display server         |
| `extra_skills_feature`  | Extra OVOS skills enabled during the installation         |
| `gui_feature`           | GUI enabled during the installation                       |
| `hardware`              | Whether the device is a Mark 1, Mark II, or DevKit          |
| `homeassistant_feature` | Home Assistant feature enabled during the installation    |
| `llm_feature`           | LLM feature enabled during the installation                |
| `installed_at`          | Date when OVOS was installed                              |
| `os_kernel`             | Kernel version of the host running OVOS                   |
| `os_name`               | OS name of the host running OVOS                          |
| `os_type`               | OS type of the host running OVOS                           |
| `os_version`            | OS version of the host running OVOS                        |
| `profile`               | Profile used during the OVOS installation                 |
| `python_version`        | Python version running on the host                        |
| `raspberry_pi`          | Whether OVOS was installed on a Raspberry Pi                |
| `skills_feature`        | Default OVOS skills enabled during the installation        |
| `sound_server`          | Whether PulseAudio or PipeWire is used                     |
| `tuning_enabled`        | Whether the Raspberry Pi tuning feature was used            |
| `venv`                  | OVOS installed into a Python virtual environment           |

No Home Assistant URL or API key value is collected, only whether the Home Assistant feature was enabled.

No LLM API URL, API key, model, or persona value is collected, only whether the LLM feature was enabled.

## Usage metrics

Usage metrics are a different option, and they do not stop when the installation ends.

If you accept them, the installer writes this into your `mycroft.conf`:

```json
"open_data": {
  "intent_urls": [
    "https://metrics.tigregotico.pt/intents"
  ]
}
```

Your assistant then reports the intents it matches to that address, for as long as the setting stays in the configuration file. To stop it later, remove the `open_data` block from `~/.config/mycroft/mycroft.conf` and restart the OVOS services.

The collected data is published on the [Open Data portal](https://opendata.tigregotico.pt), where it can be viewed and downloaded.

Both endpoints are run by the Open Voice OS community rather than by this repository, so their retention and their use of the data are documented where each service is, not here.
