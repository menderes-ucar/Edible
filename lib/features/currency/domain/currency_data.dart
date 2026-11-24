/// Default currency of a destination (ISO 3166 country -> ISO 4217 currency).
/// Countries that are missing simply get no default; the user can pick one.
const _countryCurrency = <String, String>{
  // Euro area
  'AT': 'EUR', 'BE': 'EUR', 'BG': 'EUR', 'CY': 'EUR', 'DE': 'EUR', 'EE': 'EUR',
  'ES': 'EUR', 'FI': 'EUR', 'FR': 'EUR', 'GR': 'EUR', 'HR': 'EUR', 'IE': 'EUR',
  'IT': 'EUR', 'LT': 'EUR', 'LU': 'EUR', 'LV': 'EUR', 'MT': 'EUR', 'NL': 'EUR',
  'PT': 'EUR', 'SI': 'EUR', 'SK': 'EUR', 'ME': 'EUR', 'XK': 'EUR', 'MC': 'EUR',
  'SM': 'EUR', 'VA': 'EUR', 'AD': 'EUR',
  // Rest of Europe
  'CH': 'CHF', 'CZ': 'CZK', 'DK': 'DKK', 'GB': 'GBP', 'HU': 'HUF', 'PL': 'PLN',
  'RO': 'RON', 'SE': 'SEK', 'NO': 'NOK', 'IS': 'ISK', 'TR': 'TRY', 'RU': 'RUB',
  'UA': 'UAH', 'RS': 'RSD', 'AL': 'ALL', 'MK': 'MKD', 'BA': 'BAM', 'MD': 'MDL',
  'BY': 'BYN', 'GE': 'GEL', 'AZ': 'AZN', 'AM': 'AMD', 'KZ': 'KZT', 'UZ': 'UZS',
  // Americas
  'US': 'USD', 'CA': 'CAD', 'MX': 'MXN', 'BR': 'BRL', 'AR': 'ARS', 'CL': 'CLP',
  'CO': 'COP', 'PE': 'PEN',
  // Asia-Pacific
  'JP': 'JPY', 'CN': 'CNY', 'HK': 'HKD', 'TW': 'TWD', 'KR': 'KRW', 'TH': 'THB',
  'VN': 'VND', 'ID': 'IDR', 'MY': 'MYR', 'SG': 'SGD', 'PH': 'PHP', 'IN': 'INR',
  'LK': 'LKR', 'NP': 'NPR', 'PK': 'PKR', 'BD': 'BDT', 'KH': 'KHR', 'LA': 'LAK',
  'MM': 'MMK', 'MV': 'MVR', 'AU': 'AUD', 'NZ': 'NZD',
  // Middle East & Africa
  'AE': 'AED', 'SA': 'SAR', 'EG': 'EGP', 'MA': 'MAD', 'TN': 'TND', 'IL': 'ILS',
  'JO': 'JOD', 'QA': 'QAR', 'KW': 'KWD', 'BH': 'BHD', 'OM': 'OMR', 'LB': 'LBP',
  'ZA': 'ZAR', 'KE': 'KES', 'TZ': 'TZS',
};

/// Used when the phone's locale has no region (e.g. plain "de" or "tr").
const _languageCurrency = <String, String>{
  'en': 'USD', 'tr': 'TRY', 'de': 'EUR', 'fr': 'EUR', 'es': 'EUR', 'it': 'EUR',
  'pt': 'EUR', 'nl': 'EUR', 'ar': 'USD', 'zh': 'CNY', 'ru': 'RUB', 'ko': 'KRW',
  'ja': 'JPY',
};

/// Currencies that are normally shown without decimals.
const _zeroDecimal = {'JPY', 'KRW', 'VND', 'IDR', 'CLP', 'ISK', 'UGX', 'PYG'};

String? currencyForCountry(String? countryCode) {
  final code = (countryCode ?? '').trim().toUpperCase();
  return code.isEmpty ? null : _countryCurrency[code];
}

/// Best guess of the traveller's home currency from the phone locale.
String homeCurrencyFor({String? countryCode, required String languageCode}) =>
    currencyForCountry(countryCode) ??
    _languageCurrency[languageCode.toLowerCase()] ??
    'USD';

int currencyDecimals(String code) => _zeroDecimal.contains(code) ? 0 : 2;
