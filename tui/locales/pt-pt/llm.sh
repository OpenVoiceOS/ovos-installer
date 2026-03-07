#!/usr/bin/env bash
LLM_TITLE_SETUP="Instalação do Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Selecionou a funcionalidade LLM para o ovos-persona.

Isto permite ao OVOS usar um assistente de IA quando as skills normais não têm uma boa resposta.

Ser-lhe-á pedido:
  - URL da API: para onde o OVOS envia os pedidos de IA
  - Chave da API: a sua chave privada de acesso a esse serviço
  - Modelo: qual o modelo de IA a utilizar
  - Estilo do assistente: como o assistente deve soar
  - Tamanho da resposta: quanto espaço o modelo tem para responder
  - Criatividade: valores mais baixos são mais seguros, valores mais altos mais imaginativos
  - Foco: valores mais baixos mantêm respostas mais apertadas e previsíveis

As opções avançadas já incluem valores seguros por defeito.
"
LLM_TITLE_EXISTING="Instalação do Open Voice OS - Configuração LLM existente"
LLM_CONTENT_EXISTING="
Foi detetada uma configuração de persona LLM existente.

URL da API: __URL__
Modelo: __MODEL__

Pretende manter a configuração existente?
"
LLM_TITLE_URL="Instalação do Open Voice OS - URL da API LLM"
LLM_CONTENT_URL="
Introduza o URL da API compatível com OpenAI usado pelo seu fornecedor.

Exemplo: https://llama.smartgic.io/v1

Dica: muitos servidores compatíveis precisam da parte /v1.
"
LLM_TITLE_KEY="Instalação do Open Voice OS - Chave da API LLM"
LLM_CONTENT_KEY="
Introduza a chave da API do seu fornecedor de IA.

É mantida privada e não aparece no resumo do instalador.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Deixe em branco para manter a chave existente.
"
LLM_TITLE_MODEL="Instalação do Open Voice OS - Modelo LLM"
LLM_CONTENT_MODEL="
Introduza o nome do modelo que o OVOS deve usar nas conversas.

Exemplos: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Instalação do Open Voice OS - Estilo do assistente LLM"
LLM_CONTENT_PERSONA="
Descreva como o assistente deve falar e comportar-se.

O valor por defeito está ajustado para respostas curtas e adequadas a voz.
Exemplo: Responda em português simples para um assistente de voz. Sem emojis. Respostas curtas.
"
LLM_TITLE_MAX_TOKENS="Instalação do Open Voice OS - Tamanho da resposta LLM"
LLM_CONTENT_MAX_TOKENS="
Escolha quanto espaço o modelo tem para cada resposta.

Valores mais altos permitem respostas mais completas, mas podem ser mais lentos.
Valores mais baixos tornam as respostas mais curtas e rápidas.

Recomendado para uso por voz: 300
"
LLM_TITLE_TEMPERATURE="Instalação do Open Voice OS - Criatividade LLM"
LLM_CONTENT_TEMPERATURE="
Escolha quão criativas devem ser as respostas.

Valores baixos são mais calmos e previsíveis.
Valores altos são mais variados e mais livres.

Recomendado para uso por voz: 0.2
"
LLM_TITLE_TOP_P="Instalação do Open Voice OS - Foco LLM"
LLM_CONTENT_TOP_P="
Escolha quão próximo o modelo deve ficar das palavras mais prováveis.

Valores baixos tornam as respostas mais focadas e consistentes.
Valores altos permitem maior variedade.

Recomendado para uso por voz: 0.1
"
LLM_TITLE_INVALID="Instalação do Open Voice OS - Configuração LLM inválida"
LLM_CONTENT_MISSING_INFO="
Falta informação LLM obrigatória.

Forneça URL da API, chave da API, modelo, estilo do assistente e valores de ajuste.
"
LLM_CONTENT_INVALID_URL="
URL inválido.

Forneça um URL da API compatível com OpenAI válido.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Tamanho de resposta inválido.

Introduza um número inteiro superior a 0.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Nível de criatividade inválido.

Introduza um número entre 0 e 2.
"
LLM_CONTENT_INVALID_TOP_P="
Nível de foco inválido.

Introduza um número entre 0 e 1.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING
export LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_MAX_TOKENS LLM_CONTENT_MAX_TOKENS
export LLM_TITLE_TEMPERATURE LLM_CONTENT_TEMPERATURE
export LLM_TITLE_TOP_P LLM_CONTENT_TOP_P
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL
export LLM_CONTENT_INVALID_MAX_TOKENS LLM_CONTENT_INVALID_TEMPERATURE LLM_CONTENT_INVALID_TOP_P
