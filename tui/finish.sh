#!/bin/env bash

config_file="${RUN_AS_HOME}/.config/mycroft/mycroft.conf"
if [[ "$METHOD" == "containers" ]]; then
    config_file="${RUN_AS_HOME}/ovos/config/mycroft.conf"
fi

message="The installation has been successfully completed! 🎉

Your voice assistant is ready to go. We're excited for you to explore the wide array of features and capabilities this voice assistant has to offer.

If you enabled the default skills feature then you can start to interact with your assistant by saying:

  - Hey Mycroft, what time is it?
  - Hey Mycroft, what is the temperature?
  - Hey Mycroft, who made you?
  - Hey Mycroft, who is Ada Lovelace?
  - Hey Mycroft, what would Duke Nukem say?

The settings of your assistant could be changed in the $config_file configuration file.

Should you need any assistance or updates in the future, feel free to reach out. Enjoy your Open Voice OS experience!"

whiptail --msgbox --title "Open Voice OS Installation - Finish" "$message" 25 80
