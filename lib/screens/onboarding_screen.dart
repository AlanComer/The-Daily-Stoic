import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _storage = FlutterSecureStorage();

  String? _selectedProvider; // 'ollama' | 'openai' | 'anthropic' | null
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isSaving = false;

  bool get _isDesktop => Platform.isMacOS || Platform.isWindows;

  bool get _canSetUp {
    if (_selectedProvider == null) return false;
    if (_selectedProvider == 'ollama') return true;
    return _apiKeyController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _setUp() async {
    setState(() => _isSaving = true);
    await _storage.write(key: 'provider', value: _selectedProvider!);
    await _storage.write(
      key: 'api_key',
      value: _selectedProvider == 'ollama' ? '' : _apiKeyController.text.trim(),
    );
    await _storage.write(key: 'onboarding_complete', value: 'true');
    if (!mounted) return;
    _navigateHome();
  }

  Future<void> _skip() async {
    await _storage.write(key: 'onboarding_complete', value: 'true');
    if (!mounted) return;
    _navigateHome();
  }

  void _navigateHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App title
              Text(
                'The Daily Stoic',
                style: GoogleFonts.lora(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF0EDE8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your daily Stoic companion',
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFFF0EDE8).withOpacity(0.55),
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 48),

              // AI setup section
              Text(
                'AI Diary Summaries (optional)',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: const Color(0xFFF0EDE8).withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate a one-line summary of each passage for your diary. You can set this up later.',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFF0EDE8).withOpacity(0.45),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Provider options
              if (_isDesktop) _providerTile('ollama', 'Ollama — free, runs on your computer'),
              _providerTile('openai', 'OpenAI'),
              _providerTile('anthropic', 'Anthropic Claude'),

              // Ollama hint
              if (_selectedProvider == 'ollama') ...[
                const SizedBox(height: 12),
                Text(
                  "Make sure Ollama is running with: ollama serve",
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFF0EDE8).withOpacity(0.45),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // API key field (OpenAI / Anthropic only)
              if (_selectedProvider == 'openai' || _selectedProvider == 'anthropic') ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Color(0xFFF0EDE8), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'API key',
                    hintStyle: TextStyle(color: const Color(0xFFF0EDE8).withOpacity(0.3)),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF444444)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF8A7F70)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFFF0EDE8).withOpacity(0.4),
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _skip,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF444444)),
                        foregroundColor: const Color(0xFFF0EDE8).withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Skip for now'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_canSetUp && !_isSaving) ? _setUp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A352C),
                        foregroundColor: const Color(0xFFF0EDE8),
                        disabledBackgroundColor: const Color(0xFF2A2A2A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFF0EDE8),
                              ),
                            )
                          : const Text('Set Up AI'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _providerTile(String value, String label) {
    final selected = _selectedProvider == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedProvider = value;
        _apiKeyController.clear();
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? const Color(0xFF8A7F70) : const Color(0xFF333333),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: selected
                  ? const Color(0xFF8A7F70)
                  : const Color(0xFFF0EDE8).withOpacity(0.3),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFFF0EDE8).withOpacity(selected ? 0.9 : 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
