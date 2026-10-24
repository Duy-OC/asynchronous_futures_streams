import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pomodoro_state.dart';
import '../models/session_record.dart';
import '../services/pomodoro_timer.dart';
import '../services/session_repository.dart';
import '../widgets/session_progress.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_display.dart';
import 'history_screen.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key, this.timerFactory, this.repository});

  final PomodoroTimer Function(SessionCompletedCallback onCompleted)?
  timerFactory;
  final SessionRepository? repository;

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const _focusMinutesKey = 'focus_flow_focus_minutes';
  late final PomodoroTimer _timer;
  late final SessionRepository _repository;
  Future<void> _pendingSave = Future<void>.value();
  int _savedFocusCount = 0;
  String? _storageError;
  bool _focusDurationChanged = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SessionRepository();
    _timer =
        widget.timerFactory?.call(_saveCompleted) ??
        PomodoroTimer(onSessionCompleted: _saveCompleted);
    _pendingSave = _loadCount();
    _loadFocusDuration();
  }

  Future<void> _loadFocusDuration() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final minutes = preferences.getInt(_focusMinutesKey);
      if (!mounted || _focusDurationChanged || minutes == null) return;
      if (minutes >= 1 && minutes <= 180) {
        _timer.setFocusDuration(Duration(minutes: minutes));
        setState(() {});
      }
    } catch (_) {
      // Keep the default duration if settings cannot be read.
    }
  }

  Future<void> _editFocusDuration() async {
    var input = _focusMinutes.toString();
    String? errorText;
    final minutes = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Thời gian tập trung'),
          content: TextFormField(
            initialValue: input,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => input = value,
            decoration: InputDecoration(
              labelText: 'Số phút (1–180)',
              errorText: errorText,
            ),
            onFieldSubmitted: (_) {
              final value = int.tryParse(input);
              if (value != null && value >= 1 && value <= 180) {
                Navigator.of(dialogContext).pop(value);
              } else {
                setDialogState(() => errorText = 'Nhập từ 1 đến 180 phút');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(input);
                if (value != null && value >= 1 && value <= 180) {
                  Navigator.of(dialogContext).pop(value);
                } else {
                  setDialogState(() => errorText = 'Nhập từ 1 đến 180 phút');
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (minutes == null || !mounted) return;

    _focusDurationChanged = true;
    _timer.setFocusDuration(Duration(minutes: minutes));
    setState(() {});
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setInt(_focusMinutesKey, minutes);
      if (!saved) throw StateError('Could not save focus duration');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lưu thời gian tập trung.')),
        );
      }
    }
  }

  Future<void> _loadCount() async {
    try {
      final records = await _repository.loadSessions();
      if (mounted) {
        setState(
          () => _savedFocusCount = records
              .where((record) => record.sessionType == SessionType.focus)
              .length,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _storageError = 'Không thể tải lịch sử.');
    }
  }

  // Xếp các lần lưu nối tiếp để hai phiên không ghi đè lịch sử của nhau.
  void _saveCompleted(SessionRecord record) {
    _pendingSave = _pendingSave.then((_) => _persistSession(record));
  }

  Future<void> _persistSession(SessionRecord record) async {
    try {
      await _repository.saveSession(record);
      if (!mounted) return;
      setState(() {
        if (record.sessionType == SessionType.focus) _savedFocusCount++;
        _storageError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _storageError = 'Không thể lưu phiên vừa hoàn thành.');
      }
    }
  }

  Future<void> _openHistory() async {
    await _pendingSave;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryScreen(repository: _repository),
      ),
    );
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  int get _focusMinutes =>
      (_timer.focusDuration.inSeconds / 60).ceil().clamp(1, 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusFlow'),
        actions: [
          IconButton(
            onPressed: _openHistory,
            tooltip: 'Lịch sử',
            icon: const Icon(Icons.history_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // StreamBuilder tự đăng ký/hủy lắng nghe khi widget được tạo/hủy.
      body: StreamBuilder<PomodoroState>(
        stream: _timer.stream,
        initialData: _timer.state,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _timer.state;
          final isFocus = state.sessionType == SessionType.focus;
          final accent = isFocus
              ? const Color(0xFF467D60)
              : const Color(0xFFAC7953);
          final heading = switch (state.sessionType) {
            SessionType.focus => 'Tập trung',
            SessionType.shortBreak => 'Nghỉ ngắn',
            SessionType.longBreak => 'Nghỉ dài',
          };
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                  child: Column(
                    children: [
                      Text(
                        heading,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: Color(0xFF1F2925),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: TimerDisplay(state: state, accent: accent),
                      ),
                      const SizedBox(height: 28),
                      TimerControls(
                        status: state.status,
                        accent: accent,
                        onStart: _timer.start,
                        onPause: _timer.pause,
                        onReset: _timer.reset,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Tooltip(
                          message: 'Đặt thời gian tập trung',
                          child: TextButton.icon(
                            onPressed: _editFocusDuration,
                            icon: const Icon(Icons.tune_rounded),
                            label: Text('$_focusMinutes phút'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            children: [
                              SessionProgress(
                                completedFocusSessions:
                                    state.completedFocusSessions,
                                isLongBreak:
                                    state.sessionType == SessionType.longBreak,
                              ),
                              const Divider(height: 32),
                              Text('Phiên tập trung đã lưu: $_savedFocusCount'),
                            ],
                          ),
                        ),
                      ),
                      if (_storageError != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _storageError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
