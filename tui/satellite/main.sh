#!/bin/env bash

# shellcheck source=../locales/en-us/satellite.sh
source "tui/locales/$LOCALE/satellite.sh"

# shellcheck source=host.sh
source tui/satellite/host.sh

# shellcheck source=port.sh
source tui/satellite/port.sh

# shellcheck source=key.sh
source tui/satellite/key.sh

# shellcheck source=password.sh
source tui/satellite/password.sh
