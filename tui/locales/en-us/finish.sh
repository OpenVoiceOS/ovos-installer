#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
This satellite still has to be allowed to speak, on the machine running the HiveMind listener at ${HIVEMIND_HOST}:${HIVEMIND_PORT:-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Use list-clients to find the Node ID whose access key begins ${HIVEMIND_KEY_PREFIX} - that is this satellite. Until the grant is made it will connect and authenticate, and everything it says will be refused.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
The installation has been successfully completed! 🎉

Your voice assistant is ready to go. We're excited for you to explore the wide array of features and capabilities this voice assistant has to offer.

${OVOS_SERVICE_SCOPE_HINT:-}

If you enabled the default skills feature then you can start to interact with your assistant by saying:

  - Hey Mycroft, what time is it?
  - Hey Mycroft, what is the temperature?
  - Hey Mycroft, who made you?
  - Hey Mycroft, who is Ada Lovelace?
  - Hey Mycroft, what would Duke Nukem say?

The settings of your assistant could be changed in the ${CONFIG_FILE:-} configuration file.

Should you need any assistance or updates in the future, feel free to reach out. Enjoy your Open Voice OS experience!

Press OK to exit the installer.
$HIVEMIND_SATELLITE_HINT
"
TITLE="Open Voice OS Installation - Finish"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT
