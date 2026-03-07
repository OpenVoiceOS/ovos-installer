#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS Installation - LLM"
LLM_CONTENT_HAVE_DETAILS="
आपने ovos-persona के लिए LLM फीचर चुना है।

कृपया यह जानकारी दें:
  - OpenAI-संगत API URL
  - API key
  - मॉडल
  - Persona prompt
"
LLM_TITLE_EXISTING="Open Voice OS Installation - मौजूदा LLM सेटिंग्स"
LLM_CONTENT_EXISTING="
मौजूदा LLM persona कॉन्फ़िगरेशन मिला।

API URL: __URL__

क्या आप मौजूदा कॉन्फ़िगरेशन रखना चाहते हैं?
"
LLM_TITLE_URL="Open Voice OS Installation - LLM API URL"
LLM_CONTENT_URL="
कृपया अपना OpenAI-संगत API URL दर्ज करें।

उदाहरण: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Open Voice OS Installation - LLM API Key"
LLM_CONTENT_KEY="
कृपया अपनी LLM API key दर्ज करें।
"
LLM_CONTENT_KEY_KEEP_EXISTING="
मौजूदा key रखने के लिए इसे खाली छोड़ दें।
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM मॉडल"
LLM_CONTENT_MODEL="
कृपया उपयोग करने के लिए LLM मॉडल का नाम दर्ज करें।

उदाहरण: gpt-4o-mini
"
LLM_TITLE_PERSONA="Open Voice OS Installation - LLM Persona"
LLM_CONTENT_PERSONA="
कृपया ovos-persona द्वारा उपयोग किया जाने वाला persona prompt दर्ज करें।

उदाहरण: helpful, creative, clever, and very friendly.
"
LLM_TITLE_INVALID="Open Voice OS Installation - अमान्य LLM कॉन्फ़िगरेशन"
LLM_CONTENT_MISSING_INFO="
कुछ आवश्यक LLM जानकारी गायब है।

कृपया API URL, API key, मॉडल और persona text प्रदान करें।
"
LLM_CONTENT_INVALID_URL="
अमान्य URL।

कृपया वैध OpenAI-संगत API URL दें।
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL
