import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_stoic_reader/models/entry.dart';
import 'package:daily_stoic_reader/widgets/entry_display.dart';

const _testEntry = Entry(
  dateKey: '01-01',
  month: 'January',
  day: 1,
  title: 'CONTROL AND CHOICE',
  quote: '\u201cThe chief task in life.\u201d',
  attribution: 'EPICTETUS',
  body: 'The single most important practice in Stoic philosophy.',
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('EntryDisplay shows loading indicator when summaryState == loading',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const EntryDisplay(
        entry: _testEntry,
        summaryState: SummaryState.loading,
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('EntryDisplay shows summary text when summaryState == loaded', (tester) async {
    const summaryText = 'Focus on what you can control.';

    await tester.pumpWidget(_wrap(
      const EntryDisplay(
        entry: _testEntry,
        summaryState: SummaryState.loaded,
        summary: summaryText,
      ),
    ));

    expect(find.text(summaryText), findsOneWidget);
  });

  testWidgets('EntryDisplay shows error text when summaryState == error', (tester) async {
    const errorMsg = 'Could not generate summary — check Settings.';

    await tester.pumpWidget(_wrap(
      const EntryDisplay(
        entry: _testEntry,
        summaryState: SummaryState.error,
        errorMessage: errorMsg,
      ),
    ));

    expect(find.text(errorMsg), findsOneWidget);
  });

  testWidgets('EntryDisplay shows configure prompt when summaryState == notConfigured',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const EntryDisplay(
        entry: _testEntry,
        summaryState: SummaryState.notConfigured,
      ),
    ));

    expect(find.text('Set up AI summaries in Settings →'), findsOneWidget);
  });

  testWidgets('EntryDisplay renders entry title and body', (tester) async {
    await tester.pumpWidget(_wrap(
      const EntryDisplay(
        entry: _testEntry,
        summaryState: SummaryState.notConfigured,
      ),
    ));

    expect(find.text('CONTROL AND CHOICE'), findsOneWidget);
    expect(
      find.text('The single most important practice in Stoic philosophy.'),
      findsOneWidget,
    );
  });
}
