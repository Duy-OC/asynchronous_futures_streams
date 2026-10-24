import 'pomodoro_state.dart';

class SessionRecord {
  const SessionRecord({
    required this.sessionType,
    required this.startedAt,
    required this.completedAt,
    required this.duration,
  });

  final SessionType sessionType;
  final DateTime startedAt;
  final DateTime completedAt;
  final Duration duration;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionType': sessionType.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'durationMs': duration.inMilliseconds,
    };
  }

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    final rawSessionType = json['sessionType'];
    if (rawSessionType is! String) {
      throw const FormatException(
        'SessionRecord.sessionType must be a string.',
      );
    }

    SessionType? sessionType;
    for (final value in SessionType.values) {
      if (value.name == rawSessionType) {
        sessionType = value;
        break;
      }
    }
    if (sessionType == null) {
      throw FormatException('Unknown session type: $rawSessionType');
    }

    final startedAt = _parseDate(json['startedAt'], 'startedAt');
    final completedAt = _parseDate(json['completedAt'], 'completedAt');
    if (completedAt.isBefore(startedAt)) {
      throw const FormatException(
        'SessionRecord.completedAt cannot be before startedAt.',
      );
    }

    final rawDuration = json['durationMs'];
    if (rawDuration is! int || rawDuration < 0) {
      throw const FormatException(
        'SessionRecord.durationMs must be a non-negative integer.',
      );
    }

    return SessionRecord(
      sessionType: sessionType,
      startedAt: startedAt,
      completedAt: completedAt,
      duration: Duration(milliseconds: rawDuration),
    );
  }

  static DateTime _parseDate(Object? value, String field) {
    if (value is! String) {
      throw FormatException('SessionRecord.$field must be an ISO-8601 string.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('SessionRecord.$field is not a valid date: $value');
    }
    return parsed;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SessionRecord &&
            other.sessionType == sessionType &&
            other.startedAt == startedAt &&
            other.completedAt == completedAt &&
            other.duration == duration;
  }

  @override
  int get hashCode =>
      Object.hash(sessionType, startedAt, completedAt, duration);

  @override
  String toString() {
    return 'SessionRecord('
        'sessionType: $sessionType, '
        'startedAt: $startedAt, '
        'completedAt: $completedAt, '
        'duration: $duration)';
  }
}
