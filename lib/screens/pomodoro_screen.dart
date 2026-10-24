import 'dart:async';

import 'package:flutter/material.dart';

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
  late final PomodoroTimer _timer;
  late final SessionRepository _repository;
  Future<void> _pendingSave = Future<void>.value();
  int _savedFocusCount = 0;
  String? _storageError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SessionRepository();
    _timer =
        widget.timerFactory?.call(_saveCompleted) ??
        PomodoroTimer(onSessionCompleted: _saveCompleted);
    _loadCount();
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

  void _saveCompleted(SessionRecord record) {
    if (record.sessionType == SessionType.focus && mounted) {
      setState(() => _savedFocusCount++);
    }
    _pendingSave = _pendingSave.catchError((Object _) {}).then((_) async {
      try {
        await _repository.saveSession(record);
      } catch (_) {
        if (mounted) {
          setState(() => _storageError = 'Không thể lưu phiên vừa hoàn thành.');
        }
      }
    });
  }

  Future<void> _openHistory() async {
    await _pendingSave;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryScreen(repository: _repository),
      ),
    );
    if (mounted) unawaited(_loadCount());
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.circle_outlined, color: Color(0xFF4C8065), size: 25),
            SizedBox(width: 10),
            Text(
              'focusflow',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openHistory,
            tooltip: 'Lịch sử',
            icon: const Icon(Icons.history_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
            SessionType.focus => 'Đến lúc tập trung',
            SessionType.shortBreak => 'Nghỉ một chút nhé',
            SessionType.longBreak => 'Bạn xứng đáng nghỉ dài',
          };
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                  children: [
                    Text(
                      'TẠO KHÔNG GIAN CHO ĐIỀU QUAN TRỌNG',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 15),
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
                    const SizedBox(height: 8),
                    Text(
                      isFocus
                          ? 'Một việc tại một thời điểm. Bạn làm được mà.'
                          : 'Hít thở, thư giãn và nạp lại năng lượng.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF78847C)),
                    ),
                    const SizedBox(height: 35),
                    Center(
                      child: TimerDisplay(state: state, accent: accent),
                    ),
                    const SizedBox(height: 28),
                    TimerControls(
                      status: state.status,
                      accent: accent,
                      onStart: _timer.start,
                      onPause: _timer.pause,
                      onResume: _timer.resume,
                      onReset: _timer.reset,
                    ),
                    const SizedBox(height: 44),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE8ECE6)),
                      ),
                      child: Column(
                        children: [
                          SessionProgress(
                            completedFocusSessions:
                                state.completedFocusSessions,
                          ),
                          const Divider(height: 35, color: Color(0xFFE8ECE6)),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF4C8065),
                                size: 21,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Phiên tập trung đã lưu',
                                  style: TextStyle(color: Color(0xFF556259)),
                                ),
                              ),
                              Text(
                                '$_savedFocusCount',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF25382B),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                    const SizedBox(height: 26),
                    const Text(
                      '25 phút tập trung  ·  5 phút nghỉ ngắn  ·  15 phút nghỉ dài',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF929B94)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
