import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_record.dart';

class SessionRepository {
  SessionRepository({Future<SharedPreferences> Function()? preferencesProvider})
    : _preferencesProvider =
          preferencesProvider ?? SharedPreferences.getInstance;

  static const String storageKey = 'focus_flow_sessions';

  final Future<SharedPreferences> Function() _preferencesProvider;

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

  Future<void> saveSession(SessionRecord session) async {
    final sessions = await loadSessions();
    sessions.add(session);
    await saveSessions(sessions);
  }

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

  Future<void> clearSessions() async {
    final preferences = await _preferencesProvider();
    await preferences.remove(storageKey);
  }
}
