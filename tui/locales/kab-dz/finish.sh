#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Agensa-a mazal ilaq ad as-yettwasireg ad immeslay, ɣef tmacint anida yettazzal umseflid n HiveMind deg ${HIVEMIND_HOST-}:${HIVEMIND_PORT-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Seqdec list-clients akken ad d-tafeḍ Node ID i yesɛan tasarut n unekcum i yebdan s ${HIVEMIND_KEY_PREFIX-} - wagi d agensa-a. Skud mazal ur tefkiḍ ara tasiregt-a, ad yeqqen yerna ad yesentem timagit-is akken iwata, maca ayen akk ara d-yini ad yettwagi.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
Asbeddi-nni yekfa akken iwata! 🎉

Amalal-inek n taɣect yewjed ad yelḥi. Nefṛeḥ imi ay d-tesnirmeḍ tiɣawsiwin akked tzemmar n umalal-a n taɣect.

Ma yella tremdeḍ tamahilt n tmusniwin timezwura, tzemreḍ ad tebduḍ ad temmeslayeḍ akked umalal-ik s taɣect.

- Azul a Mycroft, acḥal ssaɛa?
- A Mycroft, anda i tewweḍ teẓɣelt?
- A Mycroft, anwa i k-id-isnulfan?
- A Mycroft, menhu i d Ada Lovelace?
- A Mycroft, d acu ara d-yini Duke Nukem?

Iɣewwaren n umalal-ik zemren ad ttwabeddlen deg ufaylu n tawila n ${CONFIG_FILE:-}.

Ma teḥwajeḍ tallalt neɣ ileqman sya d asawen, ḥulfu i yiman-ik tzemreḍ ad ten-id-tnermseḍ. Faṛes tarmit-ik n Open Voice OS!
$HIVEMIND_SATELLITE_HINT
"
TITLE="Asbeddi n Open Voice OS - Tagara"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT
