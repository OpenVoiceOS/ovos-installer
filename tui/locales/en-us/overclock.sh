#!/usr/bin/env bash

OVERCLOCK_CONTENT="
Overclocking increases CPU/GPU frequency for maximum performance but can reduce stability and increase heat.

Requirements:
- Active cooling (heatsink/fan) and good airflow
- A stable power supply appropriate for your Pi model
- Monitor temperatures and stop if throttling or crashes

Risks:
- Random reboots, audio glitches, data corruption
- Higher power draw and reduced lifespan

Open Voice OS is not responsible for any issues related to overclocking.

Enable overclocking?
"
OVERCLOCK_TITLE="Open Voice OS Installation - Overclocking"

OVERCLOCK_CURRENT_VALUES_TITLE="Current overclock values:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL
