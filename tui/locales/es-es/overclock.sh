#!/usr/bin/env bash

OVERCLOCK_CONTENT="
El overclocking aumenta la frecuencia de la CPU/GPU para obtener el máximo rendimiento, pero puede reducir la estabilidad y aumentar el calor.

Requisitos:
- Refrigeración activa (disipador/ventilador) y buen flujo de aire
- Fuente de alimentación estable adecuada a tu modelo de Pi
- Supervisa las temperaturas y detén si hay throttling o fallos

Riesgos:
- Reinicios aleatorios, fallos de audio, corrupción de datos
- Mayor consumo y vida útil más corta

Open Voice OS no se hace responsable de ningún problema relacionado con el overclocking.

¿Quieres habilitar el overclocking?
"
OVERCLOCK_TITLE="Instalación de Open Voice OS - Overclocking"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE
