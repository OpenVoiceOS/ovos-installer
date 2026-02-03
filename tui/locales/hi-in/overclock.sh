#!/usr/bin/env bash

OVERCLOCK_CONTENT="
ओवरक्लॉकिंग CPU/GPU की फ़्रीक्वेंसी बढ़ाकर अधिकतम प्रदर्शन देती है, लेकिन स्थिरता कम कर सकती है और ताप बढ़ाती है।

आवश्यकताएँ:
- सक्रिय कूलिंग (हीटसिंक/फैन) और अच्छा एयरफ्लो
- आपके Pi मॉडल के लिए स्थिर पावर सप्लाई
- तापमान मॉनिटर करें और थ्रॉटलिंग या क्रैश होने पर बंद करें

जोखिम:
- अचानक रीबूट, ऑडियो गड़बड़ियाँ, डेटा करप्शन
- अधिक बिजली खपत और घटा हुआ जीवनकाल

ओपन वॉइस ओएस ओवरक्लॉकिंग से जुड़ी किसी भी समस्या के लिए जिम्मेदार नहीं है।

ओवरक्लॉकिंग सक्षम करें?
"
OVERCLOCK_TITLE="Open Voice OS Installation - ओवरक्लॉकिंग"

OVERCLOCK_CURRENT_VALUES_TITLE="वर्तमान ओवरक्लॉक मान:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL
