#!/usr/bin/env bash
CONTENT="
आपका काम लगभग पूरा हो चुका है, ओपन वॉयस ओएस (Open Voice OS) स्थापित करने के लिए आपके द्वारा चुने गए विकल्पों का सारांश यहां दिया गया है:
    - विधि:     ${METHOD:-}            
    - संस्करण:  ${CHANNEL:-}            
    - प्रोफाइल:  ${PROFILE:-}           
    - कौशल:   ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - ट्यूनिंग:   ${TUNING_SUMMARY_STATE:-}

ओपन वॉयस ओएस (Open Voice OS) इंस्टॉलेशन प्रक्रिया के दौरान चुने गए विकल्पों पर हमारे सिस्टम (System) को आपकी विशिष्ट आवश्यकताओं और प्राथमिकताओं के अनुरूप बनाने के लिए सावधानीपूर्वक विचार किया गया है।
क्या आपको यह सही लगता है? यदि नहीं, तो वापस जाने और बदलाव करने के लिए ${BACK_BUTTON:-} चुनें (या ESC दबाएँ)।
"
TITLE="Open Voice OS Installation - सारांश"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION
