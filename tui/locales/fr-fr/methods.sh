#!/usr/bin/env bash
CONTENT="
Il existe deux méthodes pour installer Open Voice OS :

    - Au travers d'un moteur de conteneurisation tel que Docker
    - Au travers d'un environnement virtuel Python

Les conteneurs offrent une isolation et un déploiement facile, tandis qu'un environnement virtuel Python offre plus de flexibilité et de contrôle sur l'installation.

Si la méthode conteneurs est sélectionnée, Docker sera installé automatiquement s'il n'est pas présent sur le système.

Veuillez sélectionner une méthode d'installation :
"
LOCKED_CONTENT="
Une installation existante d'Open Voice OS a été détectée, seule la méthode qu'elle utilise déjà est donc disponible :

    - Méthode détectée : $INSTANCE_TYPE

Pour installer avec une autre méthode, désinstallez d'abord l'instance existante, puis relancez l'installateur.

Veuillez confirmer la méthode d'installation :
"
TITLE="Open Voice OS Installation - Méthodes d'installation"

export CONTENT LOCKED_CONTENT TITLE
