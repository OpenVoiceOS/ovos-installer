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

export OVERCLOCK_CONTENT OVERCLOCK_TITLE
