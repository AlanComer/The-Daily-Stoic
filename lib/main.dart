import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  // Required before any platform channel calls (including flutter_secure_storage).
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
  final onboardingComplete = await storage.read(key: 'onboarding_complete');
  final showOnboarding = onboardingComplete != 'true';

  runApp(DailyStoicApp(showOnboarding: showOnboarding));
}

class DailyStoicApp extends StatelessWidget {
  final bool showOnboarding;

  const DailyStoicApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Daily Stoic',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    const background = Color(0xFF1A1A1A);
    const surface = Color(0xFF242424);
    const primaryText = Color(0xFFF0EDE8);
    const accent = Color(0xFF8A7F70);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: primaryText,
        surface: surface,
        onSurface: primaryText,
      ),
      textTheme: GoogleFonts.loraTextTheme(
        ThemeData.dark().textTheme.apply(
              bodyColor: primaryText,
              displayColor: primaryText,
            ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primaryText,
        elevation: 0,
      ),
      dividerColor: Color(0xFF2A2A2A),
    );
  }
}
