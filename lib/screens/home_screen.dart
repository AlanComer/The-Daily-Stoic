import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../services/ai_service.dart';
import '../services/entry_service.dart';
import '../widgets/entry_display.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _storage = FlutterSecureStorage();

  DateTime _selectedDate = DateTime.now();
  Entry? _entry;
  bool _entryLoading = true;
  bool _entryNotFound = false;

  SummaryState _summaryState = SummaryState.notConfigured;
  String? _summary;
  String? _summaryError;

  // Incremented on every _loadEntry call; async callbacks check this to
  // discard results from superseded requests (rapid date navigation).
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadEntry(_selectedDate);
  }

  Future<void> _loadEntry(DateTime date) async {
    final generation = ++_loadGeneration;

    setState(() {
      _entryLoading = true;
      _entryNotFound = false;
      _entry = null;
      _summaryState = SummaryState.notConfigured;
      _summary = null;
      _summaryError = null;
    });

    final entry = await EntryService.getEntry(date);

    if (!mounted || generation != _loadGeneration) return;

    if (entry == null) {
      setState(() {
        _entryLoading = false;
        _entryNotFound = true;
      });
      return;
    }

    setState(() {
      _entry = entry;
      _entryLoading = false;
    });

    _loadSummary(entry, generation);
  }

  Future<void> _loadSummary(Entry entry, int generation) async {
    final provider = await _storage.read(key: 'provider');
    if (!mounted || generation != _loadGeneration) return;

    if (provider == null || provider.isEmpty) {
      setState(() => _summaryState = SummaryState.notConfigured);
      return;
    }

    setState(() => _summaryState = SummaryState.loading);

    try {
      final apiKey = await _storage.read(key: 'api_key') ?? '';
      final summary = await AiService.generateSummary(
        body: entry.body,
        provider: provider,
        apiKey: apiKey,
      );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _summaryState = SummaryState.loaded;
        _summary = summary;
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _summaryState = SummaryState.error;
        _summaryError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _goToPrevDay() {
    final newDate = _selectedDate.subtract(const Duration(days: 1));
    setState(() => _selectedDate = newDate);
    _loadEntry(newDate);
  }

  void _goToNextDay() {
    final newDate = _selectedDate.add(const Duration(days: 1));
    setState(() => _selectedDate = newDate);
    _loadEntry(newDate);
  }

  Future<void> _pickDate() async {
    // Year is irrelevant — only month+day are used for lookup.
    // We anchor the picker in year 2000 so Feb 29 is always available.
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, _selectedDate.month, _selectedDate.day),
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2000, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF8A7F70),
            onPrimary: Color(0xFFF0EDE8),
            surface: Color(0xFF242424),
            onSurface: Color(0xFFF0EDE8),
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    // Map picker result back to current-timezone date, keeping month+day only.
    final newDate = DateTime(_selectedDate.year, picked.month, picked.day);
    setState(() => _selectedDate = newDate);
    _loadEntry(newDate);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    // Reload summary in case provider changed.
    if (_entry != null && mounted) {
      _loadSummary(_entry!, _loadGeneration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        titleSpacing: 24,
        title: const Text(
          'The Daily Stoic',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFFF0EDE8),
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            color: const Color(0xFFF0EDE8),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2A2A2A)),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final label = DateFormat('MMMM d').format(_selectedDate);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            color: const Color(0xFFF0EDE8).withOpacity(0.6),
            onPressed: _goToPrevDay,
          ),
          GestureDetector(
            onTap: _pickDate,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFF0EDE8),
                letterSpacing: 0.4,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            color: const Color(0xFFF0EDE8).withOpacity(0.6),
            onPressed: _goToNextDay,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_entryLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Color(0xFF8A7F70),
        ),
      );
    }

    if (_entryNotFound || _entry == null) {
      return Center(
        child: Text(
          'No entry found for this date.',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFFF0EDE8).withOpacity(0.4),
          ),
        ),
      );
    }

    return EntryDisplay(
      entry: _entry!,
      summaryState: _summaryState,
      summary: _summary,
      errorMessage: _summaryError,
      onConfigureTapped: _openSettings,
    );
  }
}
