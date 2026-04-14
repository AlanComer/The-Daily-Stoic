import 'package:flutter/gestures.dart';
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF242424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MonthDayPicker(
        month: _selectedDate.month,
        day: _selectedDate.day,
        onConfirm: (month, day) {
          final newDate = DateTime(_selectedDate.year, month, day);
          setState(() => _selectedDate = newDate);
          _loadEntry(newDate);
        },
      ),
    );
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
    final label = DateFormat('d MMMM').format(_selectedDate);
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

// ── Month/Day picker ──────────────────────────────────────────────────────────

class _MonthDayPicker extends StatefulWidget {
  final int month;
  final int day;
  final void Function(int month, int day) onConfirm;

  const _MonthDayPicker({
    required this.month,
    required this.day,
    required this.onConfirm,
  });

  @override
  State<_MonthDayPicker> createState() => _MonthDayPickerState();
}

class _MonthDayPickerState extends State<_MonthDayPicker> {
  late int _month;
  late int _day;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _dayController;

  // Drag tracking for manual scroll handling
  double _dayDragStart = 0;
  int _dayStartItem = 0;
  double _monthDragStart = 0;
  int _monthStartItem = 0;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _itemExtent = 44.0;

  int _daysInMonth(int month) => DateTime(2000, month + 1, 0).day;

  void _scrollByDelta(FixedExtentScrollController controller, double dy, int maxIndex) {
    if (dy == 0) return;
    final next = (controller.selectedItem + (dy > 0 ? 1 : -1)).clamp(0, maxIndex);
    controller.animateToItem(next, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  }

  @override
  void initState() {
    super.initState();
    _month = widget.month;
    _day = widget.day;
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int maxIndex,
    required double dragStartRef,
    required int startItemRef,
    required void Function(double) onDragStart,
    required void Function(double) onDragUpdate,
    required void Function(int) onChanged,
    required Widget Function(int) itemBuilder,
  }) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _scrollByDelta(controller, event.scrollDelta.dy, maxIndex);
        }
      },
      child: GestureDetector(
        onVerticalDragStart: (d) => onDragStart(d.globalPosition.dy),
        onVerticalDragUpdate: (d) => onDragUpdate(d.globalPosition.dy),
        child: ListWheelScrollView(
          controller: controller,
          itemExtent: _itemExtent,
          perspective: 0.003,
          diameterRatio: 1.6,
          physics: const NeverScrollableScrollPhysics(),
          onSelectedItemChanged: (i) => setState(() => onChanged(i)),
          children: List.generate(
            itemCount,
            (i) => GestureDetector(
              onTap: () => controller.animateToItem(i, duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
              child: itemBuilder(i),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF8A7F70).withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildWheel(
                        controller: _dayController,
                        itemCount: 31,
                        maxIndex: 30,
                        dragStartRef: _dayDragStart,
                        startItemRef: _dayStartItem,
                        onDragStart: (y) {
                          _dayDragStart = y;
                          _dayStartItem = _dayController.selectedItem;
                        },
                        onDragUpdate: (y) {
                          final delta = y - _dayDragStart;
                          final next = (_dayStartItem + (-delta / _itemExtent).round()).clamp(0, 30);
                          _dayController.jumpToItem(next);
                        },
                        onChanged: (i) => _day = i + 1,
                        itemBuilder: (i) => Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: _day == i + 1 ? 20 : 16,
                              fontWeight: _day == i + 1 ? FontWeight.w600 : FontWeight.w400,
                              color: _day == i + 1
                                  ? const Color(0xFFF0EDE8)
                                  : const Color(0xFFF0EDE8).withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildWheel(
                        controller: _monthController,
                        itemCount: 12,
                        maxIndex: 11,
                        dragStartRef: _monthDragStart,
                        startItemRef: _monthStartItem,
                        onDragStart: (y) {
                          _monthDragStart = y;
                          _monthStartItem = _monthController.selectedItem;
                        },
                        onDragUpdate: (y) {
                          final delta = y - _monthDragStart;
                          final next = (_monthStartItem + (-delta / _itemExtent).round()).clamp(0, 11);
                          _monthController.jumpToItem(next);
                        },
                        onChanged: (i) => _month = i + 1,
                        itemBuilder: (i) => Center(
                          child: Text(
                            _months[i],
                            style: TextStyle(
                              fontSize: _month == i + 1 ? 20 : 16,
                              fontWeight: _month == i + 1 ? FontWeight.w600 : FontWeight.w400,
                              color: _month == i + 1
                                  ? const Color(0xFFF0EDE8)
                                  : const Color(0xFFF0EDE8).withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Selection highlight band — sits over wheels, ignores all input
                IgnorePointer(
                  child: Container(
                    height: _itemExtent,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDE8).withOpacity(0.07),
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: const Color(0xFF8A7F70).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF8A7F70),
                  foregroundColor: const Color(0xFFF0EDE8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onConfirm(_month, _day.clamp(1, _daysInMonth(_month)));
                },
                child: const Text('Select', style: TextStyle(fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
