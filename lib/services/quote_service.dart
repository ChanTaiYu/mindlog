import 'dart:convert';

import 'package:http/http.dart' as http;

/// An inspirational quote fetched from an external REST API.
class Quote {
  final String text;
  final String author;
  const Quote(this.text, this.author);
}

/// Fetches a daily inspirational quote from ZenQuotes (no API key required),
/// with a graceful offline fallback so the dashboard always shows something.
class QuoteService {
  QuoteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _fallback = Quote(
    'Small steps every day add up to big changes.',
    'MindLog',
  );

  Quote? _cached;
  DateTime? _cachedAt;

  Future<Quote> todayQuote() async {
    // Serve a same-day cached quote to avoid hammering the API.
    if (_cached != null && _cachedAt != null) {
      final now = DateTime.now();
      if (now.difference(_cachedAt!).inHours < 12) return _cached!;
    }
    try {
      final res = await _client
          .get(Uri.parse('https://zenquotes.io/api/today'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final q = data.first as Map<String, dynamic>;
          final quote = Quote(
            (q['q'] as String).trim(),
            (q['a'] as String).trim(),
          );
          _cached = quote;
          _cachedAt = DateTime.now();
          return quote;
        }
      }
    } catch (_) {
      // fall through to fallback
    }
    return _cached ?? _fallback;
  }
}
