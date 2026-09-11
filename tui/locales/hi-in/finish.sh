#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
इस सैटेलाइट को बोलने की अनुमति अभी दी जानी बाकी है। यह अनुमति उस मशीन पर दी जाती है जिस पर HiveMind listener चल रहा है, पते ${HIVEMIND_HOST}:${HIVEMIND_PORT:-5678} पर:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

list-clients चलाकर वह Node ID ढूँढें जिसकी एक्सेस कुंजी ${HIVEMIND_KEY_PREFIX} से शुरू होती है - वही यह सैटेलाइट है। जब तक यह अनुमति नहीं दी जाती, यह जुड़ भी जाएगा और प्रमाणीकरण भी पूरा कर लेगा, लेकिन यह जो कुछ भी कहेगा वह अस्वीकार कर दिया जाएगा।
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
स्थापना सफलतापूर्वक पूर्ण हो गई है! 🎉

आपका voice assistant वॉयस असिस्टेंट (voice assistant) कार्य करने के लिए तैयार है। हम इस वॉयस असिस्टेंट (voice assistant) द्वारा पेश की जाने वाली सुविधाओं और क्षमताओं की विस्तृत श्रृंखला का पता लगाने के लिए उत्साहित हैं।

यदि आपने डिफ़ॉल्ट (default) कौशल सुविधा सक्षम की है तो आप यह कहकर अपने सहायक के साथ बातचीत करना शुरू कर सकते हैं:

  - Hey Mycroft, समय क्या हुआ?
  - Hey Mycroft, तापमान क्या है?
  - Hey Mycroft, आपको किसने बनाया?
  - Hey Mycroft, एडा लवलेस कौन है?
  - Hey Mycroft, ड्यूक नुकेम क्या कहेंगे?

आपके सहायक की सेटिंग्स को ${CONFIG_FILE:-} कॉन्फ़िगरेशन फ़ाइल(configuration file) में बदला जा सकता है।

यदि आपको भविष्य में किसी सहायता या अपडेट की आवश्यकता हो तो बेझिझक संपर्क करें। अपने Open Voice OS अनुभव का आनंद लें!
$HIVEMIND_SATELLITE_HINT
"
TITLE="Open Voice OS Installation - अन्त"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT
