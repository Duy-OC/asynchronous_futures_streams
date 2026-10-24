import 'dart:async';

import '../models/pomodoro_state.dart';
import '../models/session_record.dart';

typedef SessionCompletedCallback = void Function(SessionRecord record);

class PomodoroTimer {
  PomodoroTimer({
    Duration focusDuration = const Duration(minutes: 25),
    this.shortBreakDuration = const Duration(minutes: 5),
    this.longBreakDuration = const Duration(minutes: 15),
    this.sessionsBeforeLongBreak = 4,
    this.tickInterval = const Duration(seconds: 1),
    DateTime Function()? now,
    this.onSessionCompleted,
  }) : assert(focusDuration > Duration.zero),
       assert(shortBreakDuration > Duration.zero),
       assert(longBreakDuration > Duration.zero),
       assert(sessionsBeforeLongBreak > 0),
       assert(tickInterval > Duration.zero),
       _focusDuration = focusDuration,
       _now = now ?? DateTime.now,
       _state = PomodoroState.initial(
         sessionType: SessionType.focus,
         duration: focusDuration,
       );

  Duration _focusDuration;
  Duration get focusDuration => _focusDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int sessionsBeforeLongBreak;
  final Duration tickInterval;
  final SessionCompletedCallback? onSessionCompleted;
  final DateTime Function() _now;

  // STREAM: phát toàn bộ trạng thái đồng hồ cho giao diện.
  final StreamController<PomodoroState> _stateController =
      StreamController<PomodoroState>.broadcast();

  PomodoroState _state;
  Timer? _ticker;
  DateTime? _endTime;
  DateTime? _sessionStartedAt;
  bool _disposed = false;

  Stream<PomodoroState> get stream => _stateController.stream;

  PomodoroState get state => _state;

  bool get isDisposed => _disposed;

  void setFocusDuration(Duration duration) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'Must be positive');
    }
    if (_disposed) return;

    _focusDuration = duration;
    // Keep an active session intact; the new duration applies next time.
    if (_state.sessionType == SessionType.focus && _state.isIdle) {
      _emit(_state.copyWith(remaining: duration, totalDuration: duration));
    }
  }

  void start() {
    if (_disposed || _state.isRunning) return;
    if (_state.isPaused) {
      resume();
      return;
    }

    _sessionStartedAt = _now();
    _startTicker();
  }

  void pause() {
    if (_disposed || !_state.isRunning) return;

    final remaining = _remainingFromEndTime() ?? _state.remaining;
    if (remaining <= Duration.zero) {
      _completeSession(autoStart: false);
      return;
    }

    _stopTicker();
    _emit(_state.copyWith(remaining: remaining, status: TimerStatus.paused));
  }

  void resume() {
    if (_disposed || !_state.isPaused) return;

    if (_state.remaining <= Duration.zero) {
      _completeSession();
      return;
    }

    _sessionStartedAt ??= _now();
    _startTicker();
  }

  void reset() {
    if (_disposed) return;

    _stopTicker();
    _sessionStartedAt = null;
    _emit(
      _state.copyWith(
        remaining: _state.totalDuration,
        status: TimerStatus.idle,
      ),
    );
  }

  // Thoát màn hình: hủy nguồn phát trước, rồi đóng Stream.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stopTicker();
    _sessionStartedAt = null;
    unawaited(_stateController.close());
  }

  // Tính theo mốc kết thúc để callback trễ không làm đồng hồ chạy chậm.
  void _startTicker() {
    _endTime = _now().add(_state.remaining);
    _ticker?.cancel();
    _ticker = Timer.periodic(tickInterval, (_) => _onTick());
    _emit(_state.copyWith(status: TimerStatus.running));
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _endTime = null;
  }

  void _onTick() {
    if (_disposed) return;

    final remaining = _remainingFromEndTime();
    if (remaining == null) return;

    if (remaining <= Duration.zero) {
      _completeSession();
      return;
    }

    _emit(_state.copyWith(remaining: remaining));
  }

  Duration? _remainingFromEndTime() {
    final endTime = _endTime;
    if (endTime == null) return null;
    final remaining = endTime.difference(_now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _completeSession({bool autoStart = true}) {
    if (_disposed) return;

    _stopTicker();

    final completedAt = _now();
    final record = SessionRecord(
      sessionType: _state.sessionType,
      startedAt:
          _sessionStartedAt ?? completedAt.subtract(_state.totalDuration),
      completedAt: completedAt,
      duration: _state.totalDuration,
    );

    final wasFocus = _state.sessionType == SessionType.focus;
    final completedFocusSessions =
        _state.completedFocusSessions + (wasFocus ? 1 : 0);
    final nextSessionType = _nextSessionType(
      currentSessionType: _state.sessionType,
      completedFocusSessions: completedFocusSessions,
    );
    final nextDuration = _durationFor(nextSessionType);

    _sessionStartedAt = autoStart ? completedAt : null;
    _emit(
      PomodoroState(
        sessionType: nextSessionType,
        remaining: nextDuration,
        totalDuration: nextDuration,
        status: autoStart ? TimerStatus.running : TimerStatus.paused,
        completedFocusSessions: completedFocusSessions,
      ),
    );

    onSessionCompleted?.call(record);
    if (!_disposed && autoStart && _state.isRunning) _startTicker();
  }

  SessionType _nextSessionType({
    required SessionType currentSessionType,
    required int completedFocusSessions,
  }) {
    if (currentSessionType != SessionType.focus) {
      return SessionType.focus;
    }
    final cycleFinished = completedFocusSessions % sessionsBeforeLongBreak == 0;
    return cycleFinished ? SessionType.longBreak : SessionType.shortBreak;
  }

  Duration _durationFor(SessionType sessionType) {
    return switch (sessionType) {
      SessionType.focus => _focusDuration,
      SessionType.shortBreak => shortBreakDuration,
      SessionType.longBreak => longBreakDuration,
    };
  }

  void _emit(PomodoroState nextState) {
    if (_disposed) return;
    _state = nextState;
    _stateController.add(nextState);
  }
}
