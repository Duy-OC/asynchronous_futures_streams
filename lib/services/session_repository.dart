import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_record.dart';

/// Reads and writes completed sessions in local storage.
///
/// The history is stored as a JSON array under [storageKey] using
/// `shared_preferences`. Corrupt entries are skipped instead of breaking the
/// whole history, so a single bad record cannot prevent the app from loading.
class SessionRepository {
  SessionRepository({Future<SharedPreferences> Function()? preferencesProvider})
    : _preferencesProvider =
          preferencesProvider ?? SharedPreferences.getInstance;

  /// Key used to persist the JSON history.
  static const String storageKey = 'focus_flow_sessions';

  final Future<SharedPreferences> Function() _preferencesProvider;

  /// Loads every valid session, preserving storage order.
  ///
  /// Returns an empty list when nothing has been saved yet or when the stored
  /// payload is not a valid JSON array.
  Future<List<SessionRecord>> loadSessions() async {
    final preferences = await _preferencesProvider();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return <SessionRecord>[];

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return <SessionRecord>[];
    }

    if (decoded is! List) return <SessionRecord>[];

    final sessions = <SessionRecord>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      try {
        sessions.add(SessionRecord.fromJson(Map<String, dynamic>.from(entry)));
      } on FormatException {
        // Ignore individual corrupt records and keep the rest of the history.
      } on TypeError {
        // Ignore individual corrupt records and keep the rest of the history.
      }
    }
    return sessions;
  }

  /// Appends one session to the stored history.
  Future<void> saveSession(SessionRecord session) async {
    final sessions = await loadSessions();
    sessions.add(session);
    await saveSessions(sessions);
  }

  /// Replaces the stored history with [sessions].
  Future<void> saveSessions(List<SessionRecord> sessions) async {
    final preferences = await _preferencesProvider();
    final encoded = jsonEncode(
      sessions.map((session) => session.toJson()).toList(),
    );
    final saved = await preferences.setString(storageKey, encoded);
    if (!saved) {
      throw StateError('Could not save sessions to local storage.');
    }
  }

  /// Removes the stored history.
  Future<void> clearSessions() async {
    final preferences = await _preferencesProvider();
    await preferences.remove(storageKey);
  }
}
