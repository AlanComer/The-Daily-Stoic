import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_stoic_reader/models/entry.dart';
import 'package:daily_stoic_reader/services/entry_service.dart';

// Minimal fixture covering Jan 1, Feb 29, Dec 31.
const _fixtureJson = '''
{
  "01-01": {
    "date_key": "01-01",
    "month": "January",
    "day": 1,
    "title": "CONTROL AND CHOICE",
    "quote": "\\u201cThe chief task in life.\\u201d",
    "attribution": "EPICTETUS, DISCOURSES, 2.5.4",
    "body": "Body text for January 1."
  },
  "02-29": {
    "date_key": "02-29",
    "month": "February",
    "day": 29,
    "title": "YOU CAN'T ALWAYS GET WHAT YOU WANT",
    "quote": "\\u201cA quote.\\u201d",
    "attribution": "EPICTETUS",
    "body": "Body text for February 29."
  },
  "12-31": {
    "date_key": "12-31",
    "month": "December",
    "day": 31,
    "title": "FINAL ENTRY",
    "quote": "\\u201cAnother quote.\\u201d",
    "attribution": "MARCUS AURELIUS",
    "body": "Body text for December 31."
  }
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Inject mock asset so EntryService can load from rootBundle in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == 'assets/data/entries.json') {
        return const StringCodec().encodeMessage(_fixtureJson);
      }
      return null;
    });
  });

  group('EntryService.getEntry', () {
    setUp(() => EntryService.clearCache());

    test('returns Jan 1 entry with correct fields', () async {
      final entry = await EntryService.getEntry(DateTime(2024, 1, 1));
      expect(entry, isNotNull);
      expect(entry!.dateKey, '01-01');
      expect(entry.title, 'CONTROL AND CHOICE');
      expect(entry.attribution, 'EPICTETUS, DISCOURSES, 2.5.4');
    });

    test('returns Feb 29 entry (leap year entry always accessible)', () async {
      final entry = await EntryService.getEntry(DateTime(2000, 2, 29));
      expect(entry, isNotNull);
      expect(entry!.title, "YOU CAN'T ALWAYS GET WHAT YOU WANT");
    });

    test('returns Dec 31 entry', () async {
      final entry = await EntryService.getEntry(DateTime(2024, 12, 31));
      expect(entry, isNotNull);
      expect(entry!.dateKey, '12-31');
    });

    test('returns null for invalid date (month 13)', () async {
      // DateTime(2024, 13, 1) normalises to 2025-01-01 in Dart, which maps to
      // '01-01' — so test with a date that simply has no entry in our fixture.
      // We use a real non-fixture key like March 1.
      final entry = await EntryService.getEntry(DateTime(2024, 3, 1));
      expect(entry, isNull);
    });
  });
}
