#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Questo satellite deve ancora essere autorizzato a parlare, sulla macchina che esegue l'ascoltatore di HiveMind all'indirizzo ${HIVEMIND_HOST-}:${HIVEMIND_PORT:-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Usa list-clients per trovare il Node ID la cui chiave di accesso inizia ${HIVEMIND_KEY_PREFIX-} - si tratta di questo satellite. Finché l'autorizzazione non viene concessa, il satellite si collegherà e si autenticherà correttamente, ma tutto ciò che dice verrà rifiutato.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
L'installazione è stata completata con successo! 🎉

Il vostro assistente vocale è ora pronto per l'uso. Non vediamo l'ora di farvi esplorare l'ampia gamma di funzioni e possibilità di questo assistente vocale.

Se avete attivato la funzione Competenze, potete interagire con il vostro assistente dicendo:

  - Hey Mycroft, che ore sono?
  - Hey Mycroft, che temperatura c'è?
  - Hey Mycroft, chi ti ha fatto?
  - Hey Mycroft, chi è Ada Lovelace?
  - Hey Mycroft, cosa direbbe Duke Nukem?

Le impostazioni della procedura guidata possono essere modificate nel file di configurazione ${CONFIG_FILE:-}.

Se in futuro avrete bisogno di assistenza o di aggiornamenti, non esitate a contattarci. Buon divertimento con Open Voice OS!
$HIVEMIND_SATELLITE_HINT
"
TITLE="Installazione di Open Voice OS - Conclusione"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT
