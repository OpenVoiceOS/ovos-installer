#!/usr/bin/env bash
LLM_TITLE_SETUP="Instalación de Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Has seleccionado la función LLM para ovos-persona.

Esto permite que OVOS use un asistente de IA cuando las habilidades normales no tienen una buena respuesta.

Se te pedirá:
  - URL de la API: dónde OVOS envía las solicitudes de IA
  - Clave API: tu clave privada de acceso a ese servicio
  - Modelo: qué modelo de IA usar
  - Estilo del asistente: cómo debe sonar el asistente
  - Longitud de la respuesta: cuánto margen tiene el modelo para responder
  - Creatividad: valores bajos son más seguros, valores altos más imaginativos
  - Enfoque: valores bajos mantienen respuestas más ajustadas y previsibles

Las opciones avanzadas ya incluyen valores seguros por defecto.
"
LLM_TITLE_EXISTING="Instalación de Open Voice OS - Configuración LLM existente"
LLM_CONTENT_EXISTING="
Se detectó una configuración de persona LLM existente.

URL de la API: __URL__
Modelo: __MODEL__

¿Quieres conservar la configuración existente?
"
LLM_TITLE_URL="Instalación de Open Voice OS - URL de la API LLM"
LLM_CONTENT_URL="
Introduce la URL de API compatible con OpenAI que usa tu proveedor.

Ejemplo: https://llama.smartgic.io/v1

Consejo: muchos servidores compatibles necesitan la parte /v1.
"
LLM_TITLE_KEY="Instalación de Open Voice OS - Clave API LLM"
LLM_CONTENT_KEY="
Introduce la clave API de tu proveedor de IA.

Se mantiene privada y no aparece en el resumen del instalador.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Déjalo vacío para conservar tu clave actual.
"
LLM_TITLE_MODEL="Instalación de Open Voice OS - Modelo LLM"
LLM_CONTENT_MODEL="
Introduce el nombre del modelo que OVOS debe usar para conversar.

Ejemplos: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Instalación de Open Voice OS - Estilo del asistente LLM"
LLM_DEFAULT_PERSONA="Responde en el idioma del usuario con un estilo hablado y natural para un asistente de voz. Sin emojis. Sin markdown. Sin viñetas. Sin aclaraciones entre paréntesis. Mantén las respuestas breves, normalmente una o dos frases cortas. Empieza directamente con la respuesta y haz que suene natural al decirla en voz alta."
LLM_CONTENT_PERSONA="
Describe cómo debe hablar y comportarse el asistente.

El valor predeterminado está ajustado para respuestas cortas y adecuadas para voz.
Ejemplo: Responde en español claro para un asistente de voz. Sin emojis. Respuestas breves.
"
LLM_TITLE_MAX_TOKENS="Instalación de Open Voice OS - Longitud de la respuesta LLM"
LLM_CONTENT_MAX_TOKENS="
Elige cuánto margen tiene el modelo para cada respuesta.

Los valores altos permiten respuestas más completas, pero pueden ser más lentos.
Los valores bajos son más cortos y rápidos.

Recomendado para uso por voz: 300
"
LLM_TITLE_TEMPERATURE="Instalación de Open Voice OS - Creatividad LLM"
LLM_CONTENT_TEMPERATURE="
Elige lo creativas que deben ser las respuestas.

Los valores bajos son más tranquilos y previsibles.
Los valores altos son más variados y juguetones.

Recomendado para uso por voz: 0.2
"
LLM_TITLE_TOP_P="Instalación de Open Voice OS - Enfoque LLM"
LLM_CONTENT_TOP_P="
Elige cuánto debe ceñirse el modelo a las palabras más probables.

Los valores bajos hacen que las respuestas sean más consistentes y centradas.
Los valores altos permiten más variedad.

Recomendado para uso por voz: 0.1
"
LLM_TITLE_INVALID="Instalación de Open Voice OS - Configuración LLM no válida"
LLM_CONTENT_MISSING_INFO="
Falta información requerida de LLM.

Proporciona URL de la API, clave API, modelo, estilo del asistente y valores de ajuste.
"
LLM_CONTENT_INVALID_URL="
URL no válida.

Proporciona una URL de API compatible con OpenAI válida.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Longitud de respuesta no válida.

Introduce un número entero mayor que 0.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Nivel de creatividad no válido.

Introduce un número entre 0 y 2.
"
LLM_CONTENT_INVALID_TOP_P="
Nivel de enfoque no válido.

Introduce un número entre 0 y 1.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING
export LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_DEFAULT_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_MAX_TOKENS LLM_CONTENT_MAX_TOKENS
export LLM_TITLE_TEMPERATURE LLM_CONTENT_TEMPERATURE
export LLM_TITLE_TOP_P LLM_CONTENT_TOP_P
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL
export LLM_CONTENT_INVALID_MAX_TOKENS LLM_CONTENT_INVALID_TEMPERATURE LLM_CONTENT_INVALID_TOP_P
