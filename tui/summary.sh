#!/bin/env bash

message="You are almost done, here is a summary of choices you made to install Open Voice OS:

    - Method:   $METHOD
    - Version:  $CHANNEL
    - Profile:  $PROFILE
    - GUI:      $FEATURE_GUI
    - Skills    $FEATURE_SKILLS    
    - Tuning:   $TUNING

The choices made during the Open Voice OS installation process have been carefully considered to tailor our system to our unique needs and preferences.

Does is sound correct to you?
"

whiptail --yesno --defaultno --title "Open Voice OS Installation - Summary" "$message" 25 80

exit_status=$?
if [ "$exit_status" = 1 ]; then
  exit 1
fi
