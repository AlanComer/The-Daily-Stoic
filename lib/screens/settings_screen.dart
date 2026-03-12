import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _storage = FlutterSecureStorage();

  String? _selectedProvider; // 'ollama' | 'openai' | 'anthropic' | null (= none)
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isSaving = false;
  bool _isLoading = true;

  bool get _isDesktop => Platform.isMacOS || Platform.isWindows;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final provider = await _storage.read(key: 'provider');
    final apiKey = await _storage.read(key: 'api_key');

    setState(() {
      _selectedProvider = provider;
      // Pre-fill with placeholder so user knows a key is already stored
      if (apiKey != null && apiKey.isNotEmpty) {
        _apiKeyController.text = '••••••••';
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    if (_selectedProvider == null) {
      // None — remove both keys
      await _storage.delete(key: 'provider');
      await _storage.delete(key: 'api_key');
    } else {
      await _storage.write(key: 'provider', value: _selectedProvider!);

      if (_selectedProvider == 'ollama') {
        await _storage.write(key: 'api_key', value: '');
      } else {
        // Only update api_key if user typed a real value (not the placeholder)
        final typed = _apiKeyController.text.trim();
        if (typed != '••••••••' && typed.isNotEmpty) {
          await _storage.write(key: 'api_key', value: typed);
        }
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  void _onProviderChanged(String? value) {
    setState(() {
      _selectedProvider = value;
      // Clear the key field when switching providers
      _apiKeyController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF0EDE8)),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFF0EDE8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF8A7F70),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('AI DIARY SUMMARIES'),
                  const SizedBox(height: 16),

                  // Provider options
                  _providerOption(null, 'None (disable summaries)'),
                  if (_isDesktop) _providerOption('ollama', 'Ollama — free, runs locally'),
                  _providerOption('openai', 'OpenAI'),
                  _providerOption('anthropic', 'Anthropic Claude'),

                  // Ollama hint
                  if (_selectedProvider == 'ollama') ...[
                    const SizedBox(height: 12),
                    Text(
                      'Ensure Ollama is running: ollama serve',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFF0EDE8).withOpacity(0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  // API key field
                  if (_selectedProvider == 'openai' || _selectedProvider == 'anthropic') ...[
                    const SizedBox(height: 24),
                    _sectionLabel('API KEY'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _obscureKey,
                      onTap: () {
                        // Clear placeholder on tap so user can type freely
                        if (_apiKeyController.text == '••••••••') {
                          _apiKeyController.clear();
                        }
                      },
                      style: const TextStyle(color: Color(0xFFF0EDE8), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter API key',
                        hintStyle: TextStyle(
                          color: const Color(0xFFF0EDE8).withOpacity(0.3),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF444444)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF8A7F70)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureKey ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: const Color(0xFFF0EDE8).withOpacity(0.4),
                          ),
                          onPressed: () => setState(() => _obscureKey = !_obscureKey),
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A352C),
                        foregroundColor: const Color(0xFFF0EDE8),
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
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.8,
        color: const Color(0xFFF0EDE8).withOpacity(0.4),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _providerOption(String? value, String label) {
    final selected = _selectedProvider == value;
    return RadioListTile<String?>(
      value: value,
      groupValue: _selectedProvider,
      onChanged: _onProviderChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFF8A7F70),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: const Color(0xFFF0EDE8).withOpacity(selected ? 0.9 : 0.55),
        ),
      ),
    );
  }
}
