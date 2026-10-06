#!/usr/bin/env bash
CONTENT="
Open Voice OS trasforma ciò che dici in testo (riconoscimento vocale) e legge le risposte ad alta voce (sintesi vocale). Questa macchina è abbastanza potente da fare entrambe le cose da sola.

  - local: tutto gira su questa macchina. La tua voce resta qui e nulla dipende da internet o da quanto sono occupati i server. L'installer scarica i modelli vocali per la tua lingua, da qualche centinaio di megabyte a qualche gigabyte, e il riconoscimento tiene occupato il processore mentre parli.
  - public: il lavoro lo fanno i server pubblici di Open Voice OS. Niente da scaricare, ma ogni richiesta viaggia su internet verso server condivisi da tutta la comunità: questo aggiunge ritardo di rete e rallenta quando molte persone li usano contemporaneamente. Le tue registrazioni e le risposte vengono elaborate su quei server.

Se il riconoscimento locale fallisce o non sente nulla, quella registrazione viene inviata ai server pubblici.

Seleziona dove elaborare la voce:
"
TITLE="Installazione di Open Voice OS - Voce"
LOCAL_DESCRIPTION="Elaborare la voce su questa macchina"
PUBLIC_DESCRIPTION="Usare i server pubblici di Open Voice OS"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION
