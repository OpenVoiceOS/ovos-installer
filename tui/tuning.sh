#!/usr/bin/env bash

# shellcheck source=locales/en-us/tuning.sh
source "tui/locales/$LOCALE/tuning.sh"

if [ -f "tui/locales/$LOCALE/overclock.sh" ]; then
  # shellcheck source=locales/en-us/overclock.sh
  source "tui/locales/$LOCALE/overclock.sh"
fi

if [ -z "${OVERCLOCK_TITLE:-}" ]; then
  OVERCLOCK_TITLE="Open Voice OS Installation - Overclocking"
fi

if [ -z "${OVERCLOCK_CONTENT:-}" ]; then
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
fi

if [ -z "${OVERCLOCK_ARM_FREQ:-}" ]; then
  if [[ "${RASPBERRYPI_MODEL:-}" == *"Raspberry Pi 5"* ]]; then
    OVERCLOCK_ARM_FREQ="2400"
  else
    OVERCLOCK_ARM_FREQ="2000"
  fi
fi

if [ -z "${OVERCLOCK_GPU_FREQ:-}" ]; then
  OVERCLOCK_GPU_FREQ="750"
fi

if [ -z "${OVERCLOCK_OVER_VOLTAGE:-}" ]; then
  OVERCLOCK_OVER_VOLTAGE="6"
fi

if [ -z "${OVERCLOCK_INITIAL_TURBO:-}" ]; then
  OVERCLOCK_INITIAL_TURBO="60"
fi

if [ -z "${OVERCLOCK_ARM_BOOST:-}" ]; then
  OVERCLOCK_ARM_BOOST="1"
fi

export OVERCLOCK_ARM_FREQ OVERCLOCK_GPU_FREQ OVERCLOCK_OVER_VOLTAGE OVERCLOCK_INITIAL_TURBO OVERCLOCK_ARM_BOOST

OVERCLOCK_CONTENT="${OVERCLOCK_CONTENT}

Current overclock values:
  - arm_freq: ${OVERCLOCK_ARM_FREQ}
  - gpu_freq: ${OVERCLOCK_GPU_FREQ}
  - over_voltage: ${OVERCLOCK_OVER_VOLTAGE}
  - initial_turbo: ${OVERCLOCK_INITIAL_TURBO}
  - arm_boost: ${OVERCLOCK_ARM_BOOST}"

active_option="yes"
available_options=(yes no)

whiptail_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  --yes-button "$OK_BUTTON"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "${#available_options[@]}"
)

for option in "${available_options[@]}"; do
  whiptail_args+=("$option" "")
  if [[ $option = "$active_option" ]]; then
    whiptail_args+=("on")
  else
    whiptail_args+=("off")
  fi
done

while true; do
  TUNING=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
  exit_status=$?

  if [ "$exit_status" -eq 0 ]; then
    export TUNING
    if [ "$TUNING" == "yes" ]; then
      overclock_option="yes"
      overclock_options=(yes no)
      overclock_args=(
        --title "$OVERCLOCK_TITLE"
        --radiolist "$OVERCLOCK_CONTENT"
        --cancel-button "$BACK_BUTTON"
        --ok-button "$OK_BUTTON"
        --yes-button "$OK_BUTTON"
        "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "${#overclock_options[@]}"
      )

      for option in "${overclock_options[@]}"; do
        overclock_args+=("$option" "")
        if [[ $option = "$overclock_option" ]]; then
          overclock_args+=("on")
        else
          overclock_args+=("off")
        fi
      done

      TUNING_OVERCLOCK=$(whiptail "${overclock_args[@]}" 3>&1 1>&2 2>&3)
      overclock_exit_status=$?
      if [ "$overclock_exit_status" -eq 0 ]; then
        export TUNING_OVERCLOCK
        break
      else
        continue
      fi
    else
      export TUNING_OVERCLOCK="no"
      break
    fi
  else
    source tui/features.sh
    break
  fi
done
