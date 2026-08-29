#!/usr/bin/env bash
CONTENT="
Existen dos entornos para la instalación de Open Voice OS:

    - Motor de contenedores como Docker
    - Instalación en un entorno virtual Python

Los contenedores proporcionan aislamiento y facilidad de despliegue, mientras que un entorno virtual Python proporciona más flexibilidad y control sobre la instalación.

Si se selecciona el método de contenedor, Docker se instalará automáticamente si no está presente en el sistema.

Selecciona un entorno de instalación:
"
LOCKED_CONTENT="
Se ha detectado una instalación existente de Open Voice OS, por lo que solo está disponible el método que ya utiliza:

    - Método detectado: ${INSTANCE_TYPE:-}

Para instalar con otro método, desinstale primero la instancia existente y vuelva a ejecutar el instalador.

Confirme el método de instalación:
"
TITLE="Instalación de Open Voice OS - Entorno de instalación"

export CONTENT LOCKED_CONTENT TITLE
