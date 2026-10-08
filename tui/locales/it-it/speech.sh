#!/usr/bin/env bash
CONTENT="
Open Voice OS trasforma la voce in testo (riconoscimento) e legge le risposte ad alta voce (sintesi).

  - local: questa macchina con server pubblici di riserva. Scarica modelli vocali (da centinaia di megabyte a pochi gigabyte). Se il riconoscimento locale fallisce o non restituisce testo, quella registrazione viene inviata ai server pubblici. Se non è possibile configurare il riconoscimento o la sintesi locale, quella parte usa i server pubblici; l'installer lo segnala.
  - public: i server della comunità elaborano le tue registrazioni e le risposte vocali tramite internet. Questi server di riserva, gestiti da volontari, non sono un servizio di produzione: possono rallentare o andare offline in qualsiasi momento.

Seleziona dove elaborare la voce:
"
TITLE="Installazione di Open Voice OS - Voce"
LOCAL_DESCRIPTION="Questa macchina con server pubblici di riserva"
PUBLIC_DESCRIPTION="Server pubblici (so che possono andare offline)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION
