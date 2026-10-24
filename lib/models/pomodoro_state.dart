enum SessionType {
  focus('Focus', Duration(minutes: 25)),
  shortBreak('Short break', Duration(minutes: 5)),
  longBreak('Long break', Duration(minutes: 15));

  const SessionType(this.label, this.defaultDuration);

  final String label;
  final Duration defaultDuration;

  bool get isBreak => this != SessionType.focus;
}

enum TimerStatus { idle, running, paused }

class PomodoroState {
  const PomodoroState({
    required this.sessionType,
    required this.remaining,
    required this.totalDuration,
    required this.status,
    this.completedFocusSessions = 0,
  });

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

  final SessionType sessionType;
  final Duration remaining;
  final Duration totalDuration;
  final TimerStatus status;
  final int completedFocusSessions;

  bool get isIdle => status == TimerStatus.idle;
  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isFocusSession => sessionType == SessionType.focus;

  double get progress {
    final totalMs = totalDuration.inMilliseconds;
    if (totalMs <= 0) return 0;
    final elapsedMs = totalMs - remaining.inMilliseconds;
    return (elapsedMs / totalMs).clamp(0.0, 1.0).toDouble();
  }

  String get formattedTime {
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;
    final roundedSeconds = (safeRemaining.inMilliseconds + 999) ~/ 1000;
    final minutes = roundedSeconds ~/ 60;
    final seconds = roundedSeconds.remainder(60);
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
