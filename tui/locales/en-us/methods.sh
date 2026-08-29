#!/usr/bin/env bash
CONTENT="
To install Open Voice OS, you have two primary methods:

    - Containers engine such as Docker
    - Setting it up in a Python virtual environment

Containers provide isolation and easy deployment, while a Python virtual environment offers more flexibility and control over the installation.

If the containers method is selected, Docker will be installed automatically if not present on the system.

Please select an installation method:
"
LOCKED_CONTENT="
An existing installation of Open Voice OS was detected, so only the method it already uses is available:

    - Detected method: $INSTANCE_TYPE

To install with another method, uninstall the existing instance first, then run the installer again.

Please confirm the installation method:
"
TITLE="Open Voice OS Installation - Methods"

export CONTENT LOCKED_CONTENT TITLE
