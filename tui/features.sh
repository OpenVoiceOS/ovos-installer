#!/bin/env bash

message="
When choosing between GUI (Graphical User Interface) and skills in Open Voice OS, consider your preference and needs.

The GUI is an open source visual and display framework for OVOS running on top of KDE Plasma and built using Kirigami empowered by Qt.

Skills enable interaction through speech, making it efficient for tasks like home automation, information retrieval, and controlling smart devices using natural language commands.

Please choose the features to enable:
"

export FEATURE_GUI="false"
export FEATURE_SKILLS="false"

features=("skills" "Load default OVOS skills" ON)
if [[ "$RASPBERRYPI_MODEL" != *"Raspberry Pi 3"* ]] && [[ "$X_SERVER" != "N/A" ]]; then
  features+=("gui" "Enable graphical user interface" OFF)
fi

OVOS_FEATURES=$(whiptail --separate-output --title "Open Voice OS Installation - Features" \
  --checklist "$message" --cancel-button "Exit" 25 80 "${#features[@]}" "${features[@]}" 3>&1 1>&2 2>&3)

for FEATURE in $OVOS_FEATURES; do
  case "$FEATURE" in
    "gui")
      export FEATURE_GUI="true"
      ;;
    "skills")
      export FEATURE_SKILLS="true"
      ;;
  esac
done

exit_status=$?
if [ "$exit_status" = 1 ]; then
  exit 1
fi
