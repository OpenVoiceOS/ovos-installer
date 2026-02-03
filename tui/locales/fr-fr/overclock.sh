#!/usr/bin/env bash

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

OVERCLOCK_CURRENT_VALUES_TITLE="Valeurs d’overclocking actuelles :"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL
