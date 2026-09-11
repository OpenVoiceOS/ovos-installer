#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Ten satelita musi jeszcze otrzymać pozwolenie na mówienie - na maszynie, na której działa nasłuch HiveMind, pod adresem ${HIVEMIND_HOST-}:${HIVEMIND_PORT-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Użyj list-clients, aby znaleźć Node ID, którego klucz dostępu zaczyna się od ${HIVEMIND_KEY_PREFIX-} - to właśnie ten satelita. Dopóki uprawnienie nie zostanie nadane, satelita będzie się łączyć i uwierzytelniać, ale wszystko, co powie, zostanie odrzucone.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
Instalacja została pomyślnie ukończona! 🎉

Twój asystent głosowy jest gotowy do użycia. Cieszymy się, że możesz odkryć szeroką gamę funkcji i możliwości, jakie oferuje ten asystent głosowy.

Jeśli włączyłeś funkcję domyślnych umiejętności, możesz zacząć interakcję ze swoim asystentem, mówiąc:

- Hej Mycroft, która godzina?
- Hej Mycroft, jaka jest temperatura?
- Hej Mycroft, kto cię stworzył?
- Hej Mycroft, kim jest Ada Lovelace?
- Hej Mycroft, co powiedziałby Duke Nukem?

Ustawienia asystenta można zmienić w pliku konfiguracyjnym ${CONFIG_FILE:-}.

Jeśli w przyszłości będziesz potrzebować pomocy lub aktualizacji, skontaktuj się z nami. Ciesz się korzystaniem z Open Voice OS!
$HIVEMIND_SATELLITE_HINT
"
TITLE="Instalacja Open Voice OS – Zakończ"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT
