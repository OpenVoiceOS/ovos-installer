#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS Installation - LLM"
LLM_CONTENT_HAVE_DETAILS="
आपने ovos-persona के लिए LLM विकल्प चुना है।

इससे OVOS AI सहायक का उपयोग कर सकता है, जब सामान्य कौशलों के पास अच्छा जवाब न हो।

आपसे यह जानकारी मांगी जाएगी:
  - API URL: OVOS AI अनुरोध कहाँ भेजता है
  - API key: उस सेवा के लिए आपकी निजी एक्सेस कुंजी
  - मॉडल: कौन-सा AI मॉडल इस्तेमाल करना है
  - सहायक की शैली: सहायक को किस तरह बोलना चाहिए
  - जवाब की लंबाई: मॉडल को जवाब देने के लिए कितना स्थान मिले
  - रचनात्मकता: कम मान अधिक सुरक्षित, अधिक मान ज्यादा कल्पनाशील
  - फोकस: कम मान जवाब को अधिक सीधा और अनुमानित रखते हैं

उन्नत विकल्पों के लिए सुरक्षित डिफ़ॉल्ट मान पहले से भरे हुए हैं।
"
LLM_TITLE_EXISTING="Open Voice OS Installation - मौजूदा LLM सेटिंग्स"
LLM_CONTENT_EXISTING="
मौजूदा LLM persona कॉन्फ़िगरेशन मिला।

API URL: __URL__
मॉडल: __MODEL__

क्या आप मौजूदा कॉन्फ़िगरेशन रखना चाहते हैं?
"
LLM_TITLE_URL="Open Voice OS Installation - LLM API URL"
LLM_CONTENT_URL="
कृपया अपने सेवा प्रदाता का OpenAI-संगत API URL दर्ज करें।

उदाहरण: https://llama.smartgic.io/v1

सुझाव: कई संगत सर्वर को /v1 हिस्सा चाहिए होता है।
"
LLM_TITLE_KEY="Open Voice OS Installation - LLM API Key"
LLM_CONTENT_KEY="
कृपया अपने AI सेवा प्रदाता की API key दर्ज करें।

यह निजी रखी जाती है और इंस्टॉलर सारांश में नहीं दिखाई जाती।
"
LLM_CONTENT_KEY_KEEP_EXISTING="
मौजूदा key रखने के लिए इसे खाली छोड़ दें।
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM मॉडल"
LLM_CONTENT_MODEL="
कृपया उस मॉडल का नाम दर्ज करें जिसे OVOS बातचीत के लिए इस्तेमाल करे।

उदाहरण: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Open Voice OS Installation - LLM सहायक शैली"
LLM_DEFAULT_PERSONA="उपयोगकर्ता की भाषा में वॉइस असिस्टेंट के लिए सरल और स्वाभाविक बोलचाल की शैली में उत्तर दें। इमोजी न हों। मार्कडाउन न हो। बुलेट पॉइंट न हों। कोष्ठकों में अतिरिक्त टिप्पणियां न हों। उत्तर संक्षिप्त रखें, आमतौर पर एक या दो छोटे वाक्य। सीधे उत्तर से शुरू करें और उसे ज़ोर से बोलने पर स्वाभाविक लगना चाहिए।"
LLM_CONTENT_PERSONA="
बताइए कि सहायक को कैसे बोलना और व्यवहार करना चाहिए।

डिफ़ॉल्ट विकल्प छोटे और आवाज़ के लिए उपयुक्त जवाबों के लिए सेट है।
उदाहरण: वॉइस असिस्टेंट के लिए सरल हिंदी में जवाब दें। इमोजी न दें। जवाब संक्षिप्त रखें।
"
LLM_TITLE_MAX_TOKENS="Open Voice OS Installation - LLM जवाब की लंबाई"
LLM_CONTENT_MAX_TOKENS="
चुनें कि हर जवाब के लिए मॉडल को कितना स्थान मिले।

ज्यादा मान से जवाब अधिक पूरा हो सकता है, लेकिन धीमा भी हो सकता है।
कम मान से जवाब छोटा और तेज़ रहता है।

वॉइस उपयोग के लिए सुझाया गया मान: 300
"
LLM_TITLE_TEMPERATURE="Open Voice OS Installation - LLM रचनात्मकता"
LLM_CONTENT_TEMPERATURE="
चुनें कि जवाब कितने रचनात्मक हों।

कम मान अधिक शांत और अनुमानित होते हैं।
ज्यादा मान अधिक विविध और कल्पनाशील होते हैं।

वॉइस उपयोग के लिए सुझाया गया मान: 0.2
"
LLM_TITLE_TOP_P="Open Voice OS Installation - LLM फोकस"
LLM_CONTENT_TOP_P="
चुनें कि मॉडल सबसे संभावित शब्दों पर कितना टिका रहे।

कम मान जवाब को अधिक केंद्रित और स्थिर रखते हैं।
ज्यादा मान अधिक विविधता की अनुमति देते हैं।

वॉइस उपयोग के लिए सुझाया गया मान: 0.1
"
LLM_TITLE_INVALID="Open Voice OS Installation - अमान्य LLM कॉन्फ़िगरेशन"
LLM_CONTENT_MISSING_INFO="
कुछ आवश्यक LLM जानकारी गायब है।

कृपया API URL, API key, मॉडल, सहायक शैली और समायोजन मान प्रदान करें।
"
LLM_CONTENT_INVALID_URL="
अमान्य URL।

कृपया वैध OpenAI-संगत API URL दें।
"
LLM_CONTENT_INVALID_MAX_TOKENS="
जवाब की लंबाई अमान्य है।

कृपया 0 से बड़ा पूरा अंक दर्ज करें।
"
LLM_CONTENT_INVALID_TEMPERATURE="
रचनात्मकता स्तर अमान्य है।

कृपया 0 और 2 के बीच का अंक दर्ज करें।
"
LLM_CONTENT_INVALID_TOP_P="
फोकस स्तर अमान्य है।

कृपया 0 और 1 के बीच का अंक दर्ज करें।
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
