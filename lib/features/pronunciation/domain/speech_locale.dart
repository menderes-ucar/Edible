/// BCP-47 voice locale for a destination country, used to read local phrases
/// aloud with the phone's text-to-speech engine. Unknown countries return null,
/// and then no "listen" button is offered, so a phrase is never read with the
/// wrong language's voice. Multilingual countries (e.g. BE, CH, LU, CA, IN, SG, ZA,
/// KZ, BY) are deliberately left out: the phrase could be in any of several
/// languages, so no voice is offered.
const _countryLocale = <String, String>{
  // Europe
  'TR': 'tr-TR', 'DE': 'de-DE', 'AT': 'de-AT', 'LI': 'de-DE',
  'FR': 'fr-FR', 'MC': 'fr-FR',
  'ES': 'es-ES', 'PT': 'pt-PT', 'IT': 'it-IT', 'SM': 'it-IT', 'VA': 'it-IT',
  'NL': 'nl-NL', 'GR': 'el-GR', 'CY': 'el-GR', 'CZ': 'cs-CZ', 'SK': 'sk-SK',
  'PL': 'pl-PL', 'HU': 'hu-HU', 'RO': 'ro-RO', 'BG': 'bg-BG', 'HR': 'hr-HR',
  'RS': 'sr-RS', 'SI': 'sl-SI', 'GB': 'en-GB', 'IE': 'en-IE', 'SE': 'sv-SE',
  'NO': 'nb-NO', 'DK': 'da-DK', 'FI': 'fi-FI', 'IS': 'is-IS', 'EE': 'et-EE',
  'LV': 'lv-LV', 'LT': 'lt-LT', 'UA': 'uk-UA', 'RU': 'ru-RU', 'AL': 'sq-AL', 'MT': 'mt-MT', 'GE': 'ka-GE', 'AM': 'hy-AM', 'AZ': 'az-AZ',
  // Americas
  'US': 'en-US', 'MX': 'es-MX', 'BR': 'pt-BR', 'AR': 'es-AR',
  'CL': 'es-CL', 'CO': 'es-CO', 'PE': 'es-PE', 'VE': 'es-VE', 'EC': 'es-EC',
  'UY': 'es-UY', 'CR': 'es-CR', 'PA': 'es-PA', 'DO': 'es-DO', 'CU': 'es-CU',
  'GT': 'es-GT', 'BO': 'es-BO', 'PY': 'es-PY',
  // Asia-Pacific
  'JP': 'ja-JP', 'KR': 'ko-KR', 'CN': 'zh-CN', 'TW': 'zh-TW', 'HK': 'zh-HK',
  'TH': 'th-TH', 'VN': 'vi-VN', 'ID': 'id-ID', 'MY': 'ms-MY', 'PH': 'fil-PH', 'LK': 'si-LK', 'NP': 'ne-NP', 'BD': 'bn-BD',
  'KH': 'km-KH', 'AU': 'en-AU', 'NZ': 'en-NZ', // Middle East & Africa
  'EG': 'ar-EG', 'MA': 'ar-MA', 'AE': 'ar-AE', 'SA': 'ar-SA', 'JO': 'ar-JO',
  'LB': 'ar-LB', 'KW': 'ar-KW', 'QA': 'ar-QA', 'OM': 'ar-OM', 'BH': 'ar-BH',
  'TN': 'ar-TN', 'DZ': 'ar-DZ', 'IL': 'he-IL', 'KE': 'sw-KE',
  'TZ': 'sw-TZ',
};

String? speechLocaleForCountry(String? countryCode) {
  final code = (countryCode ?? '').trim().toUpperCase();
  return code.isEmpty ? null : _countryLocale[code];
}
