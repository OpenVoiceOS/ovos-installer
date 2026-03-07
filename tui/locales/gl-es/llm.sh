#!/usr/bin/env bash
LLM_TITLE_SETUP="Instalación de Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Seleccionaches a funcionalidade LLM para ovos-persona.

Isto permite que OVOS use un asistente de IA cando as habilidades normais non teñen unha boa resposta.

Vas ter que indicar:
  - URL da API: onde OVOS envía as solicitudes de IA
  - Chave da API: a túa chave privada de acceso ao servizo
  - Modelo: que modelo de IA se debe usar
  - Estilo do asistente: como debe soar o asistente
  - Lonxitude da resposta: canto espazo ten o modelo para responder
  - Creatividade: valores baixos son máis seguros, valores altos máis imaxinativos
  - Enfoque: valores baixos manteñen respostas máis axustadas e previsibles

As opcións avanzadas xa veñen con valores seguros por defecto.
"
LLM_TITLE_EXISTING="Instalación de Open Voice OS - Configuración LLM existente"
LLM_CONTENT_EXISTING="
Detectouse unha configuración de persoa LLM existente.

URL da API: __URL__
Modelo: __MODEL__

Queres manter a configuración existente?
"
LLM_TITLE_URL="Instalación de Open Voice OS - URL da API LLM"
LLM_CONTENT_URL="
Introduce a URL da API compatible con OpenAI que usa o teu provedor.

Exemplo: https://llama.smartgic.io/v1

Consello: moitos servidores compatibles precisan a parte /v1.
"
LLM_TITLE_KEY="Instalación de Open Voice OS - Chave da API LLM"
LLM_CONTENT_KEY="
Introduce a chave da API do teu provedor de IA.

Mantense privada e non aparece no resumo do instalador.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Déixao baleiro para manter a chave existente.
"
LLM_TITLE_MODEL="Instalación de Open Voice OS - Modelo LLM"
LLM_CONTENT_MODEL="
Introduce o nome do modelo que OVOS debe usar nas conversas.

Exemplos: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Instalación de Open Voice OS - Estilo do asistente LLM"
LLM_DEFAULT_PERSONA="Responde na lingua da persoa usuaria cun estilo falado e natural para un asistente de voz. Sen emojis. Sen markdown. Sen viñetas. Sen aclaracións entre parénteses. Mantén as respostas breves, normalmente unha ou dúas frases curtas. Comeza directamente coa resposta e fai que soe natural ao dicila en voz alta."
LLM_CONTENT_PERSONA="
Describe como debe falar e comportarse o asistente.

O valor predeterminado está axustado para respostas curtas e axeitadas para voz.
Exemplo: Responde en galego claro para un asistente de voz. Sen emojis. Respostas curtas.
"
LLM_TITLE_MAX_TOKENS="Instalación de Open Voice OS - Lonxitude da resposta LLM"
LLM_CONTENT_MAX_TOKENS="
Escolle canto espazo ten o modelo para cada resposta.

Os valores altos permiten respostas máis completas, pero poden ser máis lentos.
Os valores baixos son máis curtos e máis rápidos.

Recomendado para uso por voz: 300
"
LLM_TITLE_TEMPERATURE="Instalación de Open Voice OS - Creatividade LLM"
LLM_CONTENT_TEMPERATURE="
Escolle o creativas que deben ser as respostas.

Os valores baixos son máis tranquilos e previsibles.
Os valores altos son máis variados e máis libres.

Recomendado para uso por voz: 0.2
"
LLM_TITLE_TOP_P="Instalación de Open Voice OS - Enfoque LLM"
LLM_CONTENT_TOP_P="
Escolle canto debe cinguirse o modelo ás palabras máis probables.

Os valores baixos fan as respostas máis enfocadas e consistentes.
Os valores altos permiten máis variedade.

Recomendado para uso por voz: 0.1
"
LLM_TITLE_INVALID="Instalación de Open Voice OS - Configuración LLM non válida"
LLM_CONTENT_MISSING_INFO="
Falta información LLM requirida.

Fornece URL da API, chave da API, modelo, estilo do asistente e valores de axuste.
"
LLM_CONTENT_INVALID_URL="
URL non válida.

Fornece unha URL de API compatible con OpenAI válida.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Lonxitude de resposta non válida.

Introduce un número enteiro maior ca 0.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Nivel de creatividade non válido.

Introduce un número entre 0 e 2.
"
LLM_CONTENT_INVALID_TOP_P="
Nivel de enfoque non válido.

Introduce un número entre 0 e 1.
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
