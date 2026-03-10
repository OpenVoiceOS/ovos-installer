#!/usr/bin/env bash
CONTENT="
कृपया पता लगाई गई जानकारी को सत्यापित करें:

    - OS:       $DISTRO_LABEL
    - Kernel:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardware: $HARDWARE_DETECTED
    - Venv:     $VENV_PATH
    - Sound:    $SOUND_SERVER
    - Display:  ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Open Voice OS Installation - सिस्टम जानकारी की पहचान"

HARDWARE_CONFIRMATION_TITLE="Open Voice OS Installation - हार्डवेयर जाँच"
HARDWARE_CONFIRMATION_MARK2_CONTENT="TAS5806 ऑडियो डिवाइस वाला Raspberry Pi 4 मिला है।\n\nयह Mycroft Mark II हो सकता है, लेकिन कुछ सामान्य HAT वही सिग्नल दिखाते हैं।\n\nक्या यह डिवाइस वास्तव में Mycroft Mark II है?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="TAS5806 और attiny1614 डिवाइस वाला Raspberry Pi 4 मिला है।\n\nयह Mycroft DevKit हो सकता है, लेकिन कुछ सामान्य HAT वही सिग्नल दिखाते हैं।\n\nक्या यह डिवाइस वास्तव में Mycroft DevKit है?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="सामान्य Raspberry Pi प्रवाह के साथ आगे बढ़ने के लिए नहीं चुनें।"

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE
