#!/usr/bin/env bash

: "${LLM_DEFAULT_PERSONA:=Respond in the same language as the user in a plain spoken style for a voice assistant. No emojis. No markdown. No bullet points. No parenthetical asides. Keep replies concise, usually one or two short sentences. Start directly with the answer and sound natural when spoken aloud.}"
: "${LLM_DEFAULT_MAX_TOKENS:=300}"
: "${LLM_DEFAULT_TEMPERATURE:=0.2}"
: "${LLM_DEFAULT_TOP_P:=0.1}"
