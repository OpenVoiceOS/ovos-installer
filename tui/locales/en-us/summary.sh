#!/bin/env bash

CONTENT="
You are almost done, here is a summary of choices you made to install Open Voice OS:

    - Method:   $METHOD
    - Version:  $CHANNEL
    - Profile:  $PROFILE
    - GUI:      $FEATURE_GUI
    - Skills:   $FEATURE_SKILLS
    - Tuning:   $TUNING

The choices made during the Open Voice OS installation process have been carefully considered to tailor our system to your unique needs and preferences.

Does this summary look correct to you? If not, you can go back and make changes.
"
TITLE="Open Voice OS Installation - Summary"

export CONTENT TITLE
