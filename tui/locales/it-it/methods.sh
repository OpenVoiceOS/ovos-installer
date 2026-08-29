#!/usr/bin/env bash
CONTENT="
Esistono due ambienti per l'installazione di Open Voice OS:

    - Motore di container come Docker
    - Installazione in un ambiente Python virtuale

I container offrono isolamento e facilità di distribuzione, mentre un ambiente Python virtuale offre maggiore flessibilità e controllo sull'installazione.

Se si seleziona il metodo del contenitore, Docker verrà installato automaticamente se non è già presente sul sistema.

Selezionare un ambiente per l'installazione:
"
LOCKED_CONTENT="
È stata rilevata un'installazione esistente di Open Voice OS, quindi è disponibile solo il metodo che utilizza già:

    - Metodo rilevato: ${INSTANCE_TYPE:-}

Per installare con un altro metodo, disinstalla prima l'istanza esistente, quindi esegui di nuovo il programma di installazione.

Conferma il metodo di installazione:
"
TITLE="Installazione di Open Voice OS - Ambienti"

export CONTENT LOCKED_CONTENT TITLE
