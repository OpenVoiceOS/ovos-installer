# Open Voice OS installer telemetry

One of the many ways to improve software is to know how users utilize it; to get this information, some data must be shared from the user to the developers.

The installer collects anonymous data and sends it to Open Voice OS servers to help improve Open Voice OS, none of them be used for commercial purpose.

The data collection only happens during the installation process, nothing else will be collected once the installation is over.

**The installer will ask you if you want to share or not the data.**

Below is a list of the collected data _(please have a look to the [Ansible template](https://github.com/OpenVoiceOS/ovos-installer/blob/main/ansible/roles/ovos_telemetry/templates/telemetry.json.j2) used to publish the data)_.

| Data                   | Description                                              |
| ---------------------- | -------------------------------------------------------- |
| `architecture`         | CPU architecture where OVOS was installed                |
| `channel`              | `stable`, `testing` or `alpha` version of OVOS           |
| `container`            | OVOS installed into containers                           |
| `country`              | Country where OVOS has been installed                    |
| `cpu_capable`          | Is the CPU supports AVX2 or SIMD instructions            |
| `display_server`       | Is X or Wayland are used as display server               |
| `extra_skills_feature` | Extra OVOS's skills enabled during the installation      |
| `gui_feature`          | GUI enabled during the installation                      |
| `hardware`             | Is the device a Mark 1, Mark II or DevKit                |
| `installed_at`         | Date when OVOS has been installed                        |
| `os_kernel`            | Kernel version of the host where OVOS is running         |
| `os_name`              | OS name of the host where OVOS is running                |
| `os_type`              | OS type of the host where OVOS is running                |
| `os_version`           | OS version of the host where OVOS is running             |
| `profile`              | Which profile has been used during the OVOS installation |
| `python_version`       | What Python version was running on the host              |
| `raspberry_pi`         | Does OVOS has been installed on Raspberry Pi             |
| `skills_feature`       | Default OVOS's skills enabled during the installation    |
| `sound_server`         | What PulseAudio or PipeWire used                         |
| `tuning_enabled`       | Did the Raspberry Pi tuning feature was used             |
| `venv`                 | OVOS installed into a Python virtual environment         |
