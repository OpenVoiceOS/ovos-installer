#!/bin/env bash

CONTENT="
Existen dos entornos para la instalación de Open Voice OS:

    - Motor de contenedores como Docker
    - Instalación en un entorno virtual Python

Los contenedores proporcionan aislamiento y facilidad de despliegue, mientras que un entorno virtual Python proporciona más flexibilidad y control sobre la instalación.

Si se selecciona el método de contenedor, Docker se instalará automáticamente si no está presente en el sistema.

Seleccione un entorno de instalación:
"
TITLE="Open Voice OS Installation - Entorno de instalación"

export CONTENT TITLE
