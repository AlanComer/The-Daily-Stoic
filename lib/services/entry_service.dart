import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';

class EntryService {
  // Lazy-loaded cache — populated on first call, reused thereafter.
  static Map<String, Entry>? _cache;

  /// Clears the in-memory cache. Only for use in tests.
  @visibleForTesting
  static void clearCache() => _cache = null;

  /// Returns the entry for the given [date], or null if not found.
  /// Only month and day are used for lookup — the year is irrelevant.
  static Future<Entry?> getEntry(DateTime date) async {
    final all = await _loadAll();
    // Key is MM-dd (zero-padded) — year is ignored intentionally.
    final key = DateFormat('MM-dd').format(date);
    return all[key];
  }

  static Future<Map<String, Entry>> _loadAll() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString('assets/data/entries.json');
    final Map<String, dynamic> decoded = json.decode(raw) as Map<String, dynamic>;

    _cache = decoded.map(
      (key, value) => MapEntry(key, Entry.fromJson(value as Map<String, dynamic>)),
    );

    return _cache!;
  }
}
