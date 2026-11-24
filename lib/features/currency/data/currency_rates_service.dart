import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CurrencyRates {
  const CurrencyRates({
    required this.usdRates,
    required this.fetchedAt,
    this.isStale = false,
  });

  /// Units of each currency per 1 USD.
  final Map<String, double> usdRates;
  final DateTime fetchedAt;

  /// True when the live request failed and saved rates are shown instead.
  final bool isStale;

  CurrencyRates asStale() =>
      CurrencyRates(usdRates: usdRates, fetchedAt: fetchedAt, isStale: true);
}

/// Parses the `open.er-api.com/v6/latest/USD` payload. Returns null for a
/// failed or implausible response, so bad data is never shown as a rate.
CurrencyRates? parseRatesResponse(String body, DateTime now) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map || decoded['result'] != 'success') return null;
    final raw = decoded['rates'];
    if (raw is! Map) return null;

    final rates = <String, double>{};
    raw.forEach((key, value) {
      if (value is num && value > 0 && value.isFinite) {
        rates[key.toString().toUpperCase()] = value.toDouble();
      }
    });

    if (rates.length < 20 || rates['USD'] != 1.0) return null;
    return CurrencyRates(usdRates: rates, fetchedAt: now);
  } catch (_) {
    return null;
  }
}

class CurrencyRatesService {
  CurrencyRatesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://open.er-api.com/v6/latest/USD';
  static const _freshFor = Duration(hours: 12);
  static const _fileName = 'edible_currency_rates.json';

  /// Fresh cache -> that; otherwise fetch; if the fetch fails use the saved
  /// rates (marked stale); with nothing saved, the error is rethrown.
  Future<CurrencyRates> load({bool forceRefresh = false}) async {
    final cached = await _readCache();
    final now = DateTime.now();

    if (!forceRefresh &&
        cached != null &&
        now.difference(cached.fetchedAt) < _freshFor) {
      return cached;
    }

    try {
      final response = await _client
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw HttpException('status ${response.statusCode}');
      }
      final parsed = parseRatesResponse(response.body, now);
      if (parsed == null) throw const FormatException('bad rates payload');
      await _writeCache(parsed);
      return parsed;
    } catch (_) {
      if (cached != null) return cached.asStale();
      rethrow;
    }
  }

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}/$_fileName');
  }

  Future<CurrencyRates?> _readCache() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      final fetchedAt = DateTime.tryParse(decoded['fetchedAt']?.toString() ?? '');
      final raw = decoded['rates'];
      if (fetchedAt == null || raw is! Map) return null;
      final rates = <String, double>{
        for (final entry in raw.entries)
          if (entry.value is num) entry.key.toString(): (entry.value as num).toDouble(),
      };
      return rates.length < 20
          ? null
          : CurrencyRates(usdRates: rates, fetchedAt: fetchedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(CurrencyRates rates) async {
    try {
      final file = await _file();
      await file.writeAsString(
        jsonEncode({
          'fetchedAt': rates.fetchedAt.toIso8601String(),
          'rates': rates.usdRates,
        }),
        flush: true,
      );
    } catch (_) {
      // Caching is best-effort.
    }
  }
}
