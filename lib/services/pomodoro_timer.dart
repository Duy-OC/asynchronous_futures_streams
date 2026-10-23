import 'dart:async';

import '../models/pomodoro_state.dart';
import '../models/session_record.dart';

/// Receives every session that reaches zero, in completion order.
typedef SessionCompletedCallback = void Function(SessionRecord record);

/// Owns the Pomodoro countdown and exposes its state as a broadcast stream.
///
/// The timer is driven by [Timer.periodic]. The remaining time is always
/// recalculated from an absolute `endTime`, so a late callback cannot make the
/// countdown drift. When a session finishes the next one starts automatically:
///
/// focus -> short break -> focus -> ... -> long break (every
/// [sessionsBeforeLongBreak] focus sessions).
///
/// Pausing/resetting only cancels the ticker; the stream stays open until
/// [dispose] is called.
class PomodoroTimer {
  PomodoroTimer({
    this.focusDuration = const Duration(minutes: 25),
    this.shortBreakDuration = const Duration(minutes: 5),
    this.longBreakDuration = const Duration(minutes: 15),
    this.sessionsBeforeLongBreak = 4,
    this.tickInterval = const Duration(seconds: 1),
    DateTime Function()? now,
    this.onSessionCompleted,
  }) : assert(
         focusDuration > Duration.zero,
         'focusDuration must be greater than zero',
       ),
       assert(
         shortBreakDuration > Duration.zero,
         'shortBreakDuration must be greater than zero',
       ),
       assert(
         longBreakDuration > Duration.zero,
         'longBreakDuration must be greater than zero',
       ),
       assert(
         sessionsBeforeLongBreak > 0,
         'sessionsBeforeLongBreak must be greater than zero',
       ),
       assert(
         tickInterval > Duration.zero,
         'tickInterval must be greater than zero',
       ),
       _now = now ?? DateTime.now,
       _state = PomodoroState.initial(
         sessionType: SessionType.focus,
         duration: focusDuration,
       );

  /// Length of a focus session.
  final Duration focusDuration;

  /// Length of a short break.
  final Duration shortBreakDuration;

  /// Length of a long break.
  final Duration longBreakDuration;

  /// Number of focus sessions that trigger a long break.
  final int sessionsBeforeLongBreak;

  /// How often the countdown is refreshed.
  final Duration tickInterval;

  /// Called synchronously when a session completes.
  final SessionCompletedCallback? onSessionCompleted;

  /// Injectable clock, useful for deterministic tests.
  final DateTime Function() _now;

  final StreamController<PomodoroState> _stateController =
      StreamController<PomodoroState>.broadcast();

  PomodoroState _state;
  Timer? _ticker;
  DateTime? _endTime;
  DateTime? _sessionStartedAt;
  bool _disposed = false;

  /// Broadcast stream of state snapshots.
  ///
  /// The stream does not replay the current state; new listeners should start
  /// from [state] (for example with `StreamBuilder.initialData`).
  Stream<PomodoroState> get stream => _stateController.stream;

  /// Current snapshot of the timer.
  PomodoroState get state => _state;

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  /// Starts a fresh session. When paused, this behaves like [resume].
  void start() {
    if (_disposed || _state.isRunning) return;
    if (_state.isPaused) {
      resume();
      return;
    }

    _sessionStartedAt = _now();
    _startTicker();
  }

  /// Pauses a running session, keeping the remaining time.
  void pause() {
    if (_disposed || !_state.isRunning) return;

    final remaining = _remainingFromEndTime() ?? _state.remaining;
    if (remaining <= Duration.zero) {
      _completeSession();
      return;
    }

    _stopTicker();
    _emit(_state.copyWith(remaining: remaining, status: TimerStatus.paused));
  }

  /// Continues a paused session from where it stopped.
  void resume() {
    if (_disposed || !_state.isPaused) return;

    if (_state.remaining <= Duration.zero) {
      _completeSession();
      return;
    }

    _sessionStartedAt ??= _now();
    _startTicker();
  }

  /// Stops the countdown and restores the current session to full duration.
  ///
  /// The completed focus session count is preserved.
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

  /// Cancels the ticker and closes the state stream. Further calls are no-ops.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stopTicker();
    _sessionStartedAt = null;
    unawaited(_stateController.close());
  }

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

  void _completeSession() {
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

    _sessionStartedAt = completedAt;
    _endTime = completedAt.add(nextDuration);
    _emit(
      PomodoroState(
        sessionType: nextSessionType,
        remaining: nextDuration,
        totalDuration: nextDuration,
        status: TimerStatus.running,
        completedFocusSessions: completedFocusSessions,
      ),
    );

    onSessionCompleted?.call(record);
    if (_disposed) return;

    // Keep the flow running: breaks and focus sessions switch automatically.
    _ticker = Timer.periodic(tickInterval, (_) => _onTick());
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
      SessionType.focus => focusDuration,
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
