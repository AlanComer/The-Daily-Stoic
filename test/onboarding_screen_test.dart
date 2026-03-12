import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_stoic_reader/screens/onboarding_screen.dart';

// These tests only exercise UI state (button enabled/disabled) and do not
// trigger storage writes, so no storage mock is needed. If future tests cover
// the full save/skip flows, inject a mock via a seam at that point.

void main() {
  testWidgets('"Skip for now" button is always enabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    final skipButton = find.widgetWithText(OutlinedButton, 'Skip for now');
    expect(skipButton, findsOneWidget);

    final btn = tester.widget<OutlinedButton>(skipButton);
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('"Set Up AI" is disabled with no provider selected', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    final setupBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Set Up AI'),
    );
    expect(setupBtn.onPressed, isNull);
  });

  testWidgets('"Set Up AI" is disabled when OpenAI selected but key is empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    // Tap the OpenAI option
    await tester.tap(find.text('OpenAI'));
    await tester.pump();

    final setupBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Set Up AI'),
    );
    expect(setupBtn.onPressed, isNull);
  });

  testWidgets('"Set Up AI" is enabled when OpenAI selected and key is non-empty',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    await tester.tap(find.text('OpenAI'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'sk-test-key');
    await tester.pump();

    final setupBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Set Up AI'),
    );
    expect(setupBtn.onPressed, isNotNull);
  });
}
