#!/usr/bin/env bash
CONTENT="
Open Voice OS trasforma ciò che dici in testo (riconoscimento vocale) e legge le risposte ad alta voce (sintesi vocale). Questa macchina è abbastanza potente da fare entrambe le cose da sola.

  - local: tutto gira su questa macchina. La tua voce resta qui e nulla dipende da internet o da quanto sono occupati i server. L'installer scarica i modelli vocali per la tua lingua, da qualche centinaio di megabyte a qualche gigabyte, e il riconoscimento tiene occupato il processore mentre parli.
  - public: il lavoro lo fanno server della comunità. Sono offerti per buona volontà, come riserva e come esempio di voce in self-hosting, non come servizio di produzione: le risposte rallentano quando molte persone li usano contemporaneamente, e possono andare offline in qualsiasi momento. Niente da scaricare, ma le tue registrazioni e le risposte viaggiano su internet e vengono elaborate su quei server.

Se il riconoscimento locale fallisce o non sente nulla, quella registrazione viene inviata ai server pubblici.

Seleziona dove elaborare la voce:
"
TITLE="Installazione di Open Voice OS - Voce"
LOCAL_DESCRIPTION="Elaborare la voce su questa macchina"
PUBLIC_DESCRIPTION="Server pubblici (so che possono andare offline)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION
