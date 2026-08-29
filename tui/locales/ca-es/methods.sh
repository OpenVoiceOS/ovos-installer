#!/usr/bin/env bash
CONTENT="
Per a instal·lar l'Open Voice OS, teniu dos mètodes principals:

    - Motor de contenidors com Docker
    - Configurar-lo en un entorn virtual Python

Els contenidors proporcionen aïllament i un desplegament fàcil, mentre que un entorn virtual Python ofereix més flexibilitat i control sobre la instal·lació.

Si se selecciona el mètode de contenidors, Docker s'instal·larà automàticament si no està present al sistema.

Seleccioneu un mètode d'instal·lació:
"
LOCKED_CONTENT="
S'ha detectat una instal·lació existent d'Open Voice OS, per la qual cosa només està disponible el mètode que ja utilitza:

    - Mètode detectat: $INSTANCE_TYPE

Per instal·lar amb un altre mètode, desinstal·leu primer la instància existent i torneu a executar l'instal·lador.

Confirmeu el mètode d'instal·lació:
"
TITLE="Instal·lació de l'Open Voice OS - Mètodes"

export CONTENT LOCKED_CONTENT TITLE
