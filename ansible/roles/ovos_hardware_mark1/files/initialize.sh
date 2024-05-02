#!/bin/env bash
#
# This script initialiaze the atmega328p chip from the Mark 1
# device.
# Once initialized the eyes color will be changed to yellow and
# the mouth text will display "booting".

# Variables
eyes_color="16760576"
mouth_text="booting"
tty_device=/dev/ttyAMA0

# Initialiaze the firmware and wait two seconds
avrdude -p atmega328p -c linuxgpio -U signature:r:-:i -F
sleep 2

# Set eyes color
echo "eyes.color=$eyes_color" > "$tty_device"

# Set mouth text
echo "mouth.text=$mouth_text" > "$tty_device"