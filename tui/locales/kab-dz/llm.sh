#!/usr/bin/env bash
LLM_TITLE_SETUP="Asbeddi n Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Tferneḍ tamahilt LLM i ovos-persona.

Aya ad yeǧǧ OVOS ad yesseqdec amyager n AI ticki timahilin timezwura ur nesɛi ara tiririt yelhan.

Ad ak-d-nessuter:
  - URL n API: anda ara d-yazen OVOS isuturen-is ɣer AI
  - Tasarut n API: tasarut tusligt-ik i useqdec-a
  - Amudil: anwa amudil n AI ara yettwaseqdec
  - Udem n umyager: amek ara yemmeslay umyager
  - Teɣzi n tririt: acḥal n wemkan i yettunefk i umudil akken ad d-yerr
  - Asnulfu: azal amecṭuḥ yelha ugar, azal ameqqran yesnulfu ugar
  - Tuzzugt: azal amecṭuḥ yeǧǧa tiririyin ugar n telqey

Lxetyarat ifazen ttusekcamen s wazal amezwaru i tɣawsiwin yerkiden.
"
LLM_TITLE_EXISTING="Asbeddi n Open Voice OS - Iɣewwaren n LLM yellan"
LLM_CONTENT_EXISTING="
Tettwaf-d twila n LLM persona yellan yakan.

URL n API: __URL__
Amudil: __MODEL__

Tebɣiḍ ad teṭṭfeḍ tawila-nni yellan?
"
LLM_TITLE_URL="Asbeddi n Open Voice OS - URL n API n LLM"
LLM_CONTENT_URL="
Sekcem URL n API i icban ta n OpenAI, i d-ittunefken sɣur useqdac-ik.

Amedya: https://llama.smartgic.io/v1

Talɣut: aṭas n iqeddacen i icban wa ḥwaǧen tikci n /v1.
"
LLM_TITLE_KEY="Asbeddi n Open Voice OS - Tasarut n API n LLM"
LLM_CONTENT_KEY="
Sekcem tasarut n API n useqdac-ik n AI.

Tasarut-a tettwaḍfer d tusligt yerna ur d-ttbanent ara deg ugzul n usbeddi.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Eǧǧ-it d ilem akken ad teṭṭfeḍ tasarut-ik yellan.
"
LLM_TITLE_MODEL="Asbeddi n Open Voice OS - Amudil n LLM"
LLM_CONTENT_MODEL="
Sekcem isem n umudil ara yesseqdec OVOS i tmeslayin.

Imedyaten: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Asbeddi n Open Voice OS - Udem n umyager n LLM"
LLM_DEFAULT_PERSONA="Err-ed s tutlayt i deg d-yemmeslay useqdac s udem sslamu i umyager s taɣect. Ulac imujis. Ulac markdown. Ulac tibdarin. Ulac awalen ger tirni. Eǧǧ tiririyin d timecṭuḥin, s umata yiwet neɣ snat n tefyar. Bdu srid s tririt yerna eǧǧ-itt d tanaturt ticki tettwaɛqel s uwal."
LLM_CONTENT_PERSONA="
Glem amek ara yemmeslay yerna amek ara yili wamyager.

Azal amezwaru yettwaheggi i tririyin timecṭuḥin i icban ameslaw.
Amedya: Err-ed s tutlayt taglizit sslamant i umyager s taɣect. Ulac imujis. Eǧǧ tiririyin d timecṭuḥin.
"
LLM_TITLE_MAX_TOKENS="Asbeddi n Open Voice OS - Teɣzi n tririt n LLM"
LLM_CONTENT_MAX_TOKENS="
Fren acḥal n wemkan i yettunefk i umudil i yal tiririt.

Iṭṭuqan imeqqranen ttaǧǧan tiririyin ččuṛen maca zemren ad ilint sluɣent.
Iṭṭuqan imecṭuḥen d timecṭuḥin yerna d timɣaren.

Yettwamagr i useqdec s taɣect: 300
"
LLM_TITLE_TEMPERATURE="Asbeddi n Open Voice OS - Asnulfu n LLM"
LLM_CONTENT_TEMPERATURE="
Fren acḥal ara yili wesnulfu deg tiririyin.

Azalen imecṭuḥen d irkiden yerna ttusnen sya ɣer da.
Azalen imeqqranen d imecṭaḥ ugar yerna mgaraden ugar.

Yettwamagr i useqdec s taɣect: 0.2
"
LLM_TITLE_TOP_P="Asbeddi n Open Voice OS - Tuzzugt n LLM"
LLM_CONTENT_TOP_P="
Fren acḥal ara yeṭṭef umudil ɣer wawalen ittuɣalen s waṭas.

Azalen imecṭuḥen ṭṭfen tiririyin ugar n telqey d urkid.
Azalen imeqqranen ttaǧǧan ugar n tmegga.

Yettwamagr i useqdec s taɣect: 0.1
"
LLM_TITLE_INVALID="Asbeddi n Open Voice OS - Twila n LLM d tarameɣtut"
LLM_CONTENT_MISSING_INFO="
Kra n telɣut n LLM ilaqen ur telli ara.

Ttxil-k efk URL n API, tasarut n API, amudil, udem n umyager, akked wazalen n usellek.
"
LLM_CONTENT_INVALID_URL="
URL d arameɣtu.

Ttxil-k efk URL n API d ameɣtu i icban ta n OpenAI.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Teɣzi n tririt d tarameɣtut.

Ttxil-k sekcem uṭṭun ummid yugaren 0.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Aswir n usnulfu d arameɣtu.

Ttxil-k sekcem uṭṭun gar 0 d 2.
"
LLM_CONTENT_INVALID_TOP_P="
Aswir n tuzzugt d arameɣtu.

Ttxil-k sekcem uṭṭun gar 0 d 1.
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
