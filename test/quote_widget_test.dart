import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_stoic_reader/widgets/quote_widget.dart';

void main() {
  testWidgets('QuoteWidget renders quote text and attribution', (tester) async {
    const testQuote = '\u201cThe chief task in life is simply this.\u201d';
    const testAttribution = 'EPICTETUS, DISCOURSES, 2.5.4';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuoteWidget(
            quote: testQuote,
            attribution: testAttribution,
          ),
        ),
      ),
    );

    expect(find.text(testQuote), findsOneWidget);
    expect(find.text(testAttribution), findsOneWidget);
  });

  testWidgets('QuoteWidget quote text is italic', (tester) async {
    const testQuote = '\u201cA Stoic quote.\u201d';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuoteWidget(quote: testQuote, attribution: 'MARCUS AURELIUS'),
        ),
      ),
    );

    final textWidget = tester.widget<Text>(find.text(testQuote));
    expect(textWidget.style?.fontStyle, FontStyle.italic);
  });
}
