# Open Voice OS installer telemetry

Usage data helps improve software. To get this data, some information passes from the user to the developers.

The installer collects anonymous data and sends it to Open Voice OS servers to help improve Open Voice OS. None of it is used for commercial purposes.

Data collection happens only during the installation process. Nothing else is collected once the installation ends.

**The installer asks you whether you want to share the data.**

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
