/// The three kinds of sessions that make up a Pomodoro cycle.
enum SessionType {
  focus('Focus', Duration(minutes: 25)),
  shortBreak('Short break', Duration(minutes: 5)),
  longBreak('Long break', Duration(minutes: 15));

  const SessionType(this.label, this.defaultDuration);

  /// Human readable name, suitable for the UI.
  final String label;

  /// Duration used when no custom duration is configured.
  final Duration defaultDuration;

  /// Whether this session is a rest period.
  bool get isBreak => this != SessionType.focus;
}

/// Lifecycle of the countdown managed by `PomodoroTimer`.
enum TimerStatus { idle, running, paused }

/// Immutable snapshot of the timer at a point in time.
///
/// A new instance is emitted through `PomodoroTimer.stream` whenever the
/// countdown, session type, status or completed session count changes.
class PomodoroState {
  const PomodoroState({
    required this.sessionType,
    required this.remaining,
    required this.totalDuration,
    required this.status,
    this.completedFocusSessions = 0,
  });

  /// State for a session that has not started yet.
  factory PomodoroState.initial({
    SessionType sessionType = SessionType.focus,
    Duration? duration,
  }) {
    final total = duration ?? sessionType.defaultDuration;
    return PomodoroState(
      sessionType: sessionType,
      remaining: total,
      totalDuration: total,
      status: TimerStatus.idle,
    );
  }

  /// Type of the current (or upcoming, when idle) session.
  final SessionType sessionType;

  /// Time left in the current session.
  final Duration remaining;

  /// Full duration of the current session.
  final Duration totalDuration;

  /// Whether the countdown is idle, running or paused.
  final TimerStatus status;

  /// Number of focus sessions completed since the timer was created.
  final int completedFocusSessions;

  bool get isIdle => status == TimerStatus.idle;
  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isFocusSession => sessionType == SessionType.focus;

  /// Fraction of the session that has already elapsed, in the range 0..1.
  double get progress {
    final totalMs = totalDuration.inMilliseconds;
    if (totalMs <= 0) return 0;
    final elapsedMs = totalMs - remaining.inMilliseconds;
    return (elapsedMs / totalMs).clamp(0.0, 1.0).toDouble();
  }

  /// Remaining time formatted as `MM:SS`.
  String get formattedTime {
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;
    final minutes = safeRemaining.inMinutes;
    final seconds = safeRemaining.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  PomodoroState copyWith({
    SessionType? sessionType,
    Duration? remaining,
    Duration? totalDuration,
    TimerStatus? status,
    int? completedFocusSessions,
  }) {
    return PomodoroState(
      sessionType: sessionType ?? this.sessionType,
      remaining: remaining ?? this.remaining,
      totalDuration: totalDuration ?? this.totalDuration,
      status: status ?? this.status,
      completedFocusSessions:
          completedFocusSessions ?? this.completedFocusSessions,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PomodoroState &&
            other.sessionType == sessionType &&
            other.remaining == remaining &&
            other.totalDuration == totalDuration &&
            other.status == status &&
            other.completedFocusSessions == completedFocusSessions;
  }

  @override
  int get hashCode => Object.hash(
    sessionType,
    remaining,
    totalDuration,
    status,
    completedFocusSessions,
  );

  @override
  String toString() {
    return 'PomodoroState('
        'sessionType: $sessionType, '
        'remaining: $remaining, '
        'totalDuration: $totalDuration, '
        'status: $status, '
        'completedFocusSessions: $completedFocusSessions)';
  }
}
