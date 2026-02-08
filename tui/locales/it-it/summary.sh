#!/usr/bin/env bash
CONTENT="
Abbiamo quasi finito. Qui c'è un riassunto delle opzioni scelte per installare Open Voice OS:

    - Distribuzione: $METHOD
    - Versione: $CHANNEL
    - Profilo: $PROFILE
    - Competenze: $FEATURE_SKILLS
    - Ottimizzazione: $TUNING

Le decisioni prese durante il processo di installazione di Open Voice OS sono state attentamente valutate per personalizzare il nostro sistema in base alle tue esigenze e preferenze individuali.

Le impostazioni sono corrette? In caso contrario, seleziona $BACK_BUTTON (o premi ESC) per tornare indietro e apportare modifiche.
"
TITLE="Installazione di Open Voice OS - Riassunto"

export CONTENT TITLE
