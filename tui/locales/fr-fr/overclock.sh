#!/bin/env bash

OVERCLOCK_CONTENT="
L’overclocking augmente la fréquence CPU/GPU pour des performances maximales, mais peut réduire la stabilité et augmenter la chaleur.

Prérequis :
- Refroidissement actif (radiateur/ventilateur) et bon flux d’air
- Alimentation stable adaptée à votre modèle de Pi
- Surveillez les températures et arrêtez en cas de throttling ou de crash

Risques :
- Redémarrages aléatoires, problèmes audio, corruption de données
- Consommation plus élevée et durée de vie réduite

Open Voice OS n’est pas responsable des problèmes liés à l’overclocking.

Activer l’overclocking ?
"
OVERCLOCK_TITLE="Installation d'Open Voice OS - Overclocking"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE
