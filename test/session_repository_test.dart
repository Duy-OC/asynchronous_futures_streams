import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/models/pomodoro_state.dart';
import 'package:pomodoro/models/session_record.dart';
import 'package:pomodoro/services/session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

SessionRecord makeRecord({
  SessionType sessionType = SessionType.focus,
  DateTime? startedAt,
  Duration? duration,
}) {
  final start = startedAt ?? DateTime.utc(2026, 1, 1, 8);
  final actualDuration = duration ?? sessionType.defaultDuration;
  return SessionRecord(
    sessionType: sessionType,
    startedAt: start,
    completedAt: start.add(actualDuration),
    duration: actualDuration,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SessionRecord', () {
    test('serializes to JSON and back', () {
      final record = makeRecord(
        sessionType: SessionType.longBreak,
        startedAt: DateTime.utc(2026, 2, 3, 10, 15, 30),
        duration: const Duration(minutes: 15),
      );

      final json = record.toJson();
      expect(json, <String, dynamic>{
        'sessionType': 'longBreak',
        'startedAt': '2026-02-03T10:15:30.000Z',
        'completedAt': '2026-02-03T10:30:30.000Z',
        'durationMs': 900000,
      });

      expect(SessionRecord.fromJson(json), record);
    });

    test('survives a JSON encode/decode round trip', () {
      final record = makeRecord(
        sessionType: SessionType.shortBreak,
        startedAt: DateTime.utc(2026, 5, 6, 7, 8, 9),
      );

      final decoded = jsonDecode(jsonEncode(record.toJson()));
      final restored = SessionRecord.fromJson(decoded as Map<String, dynamic>);

      expect(restored, record);
    });

    test('rejects an unknown session type', () {
      final json = makeRecord().toJson()..['sessionType'] = 'nap';

      expect(() => SessionRecord.fromJson(json), throwsFormatException);
    });

    test('rejects missing or invalid fields', () {
      final valid = makeRecord().toJson();

      expect(
        () => SessionRecord.fromJson({...valid}..remove('sessionType')),
        throwsFormatException,
      );
      expect(
        () => SessionRecord.fromJson({...valid}..remove('startedAt')),
        throwsFormatException,
      );
      expect(
        () => SessionRecord.fromJson({...valid}..['startedAt'] = 'not-a-date'),
        throwsFormatException,
      );
      expect(
        () => SessionRecord.fromJson({...valid}..['durationMs'] = -1),
        throwsFormatException,
      );
      expect(
        () => SessionRecord.fromJson({...valid}..['durationMs'] = '900000'),
        throwsFormatException,
      );
      expect(
        () => SessionRecord.fromJson({
          ...valid,
          'startedAt': '2026-01-01T10:00:00.000Z',
          'completedAt': '2026-01-01T09:00:00.000Z',
        }),
        throwsFormatException,
      );
    });
  });

  group('SessionRepository', () {
    test('returns an empty list when nothing is stored', () async {
      expect(await SessionRepository().loadSessions(), isEmpty);
    });

    test(
      'returns an empty list when the stored value is empty or invalid',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          SessionRepository.storageKey: '',
        });
        expect(await SessionRepository().loadSessions(), isEmpty);

        SharedPreferences.setMockInitialValues(<String, Object>{
          SessionRepository.storageKey: 'not json',
        });
        expect(await SessionRepository().loadSessions(), isEmpty);

        SharedPreferences.setMockInitialValues(<String, Object>{
          SessionRepository.storageKey: jsonEncode(<String, Object>{'a': 1}),
        });
        expect(await SessionRepository().loadSessions(), isEmpty);
      },
    );

    test('saveSession appends records and persists them as JSON', () async {
      final repository = SessionRepository();
      final focus = makeRecord();
      final shortBreak = makeRecord(
        sessionType: SessionType.shortBreak,
        startedAt: focus.completedAt,
      );

      await repository.saveSession(focus);
      await repository.saveSession(shortBreak);

      expect(await repository.loadSessions(), [focus, shortBreak]);

      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(SessionRepository.storageKey);
      expect(raw, isNotNull);
      expect(jsonDecode(raw!), [focus.toJson(), shortBreak.toJson()]);
    });

    test('saveSessions replaces the existing history', () async {
      final repository = SessionRepository();
      await repository.saveSession(makeRecord());

      final replacement = [
        makeRecord(sessionType: SessionType.shortBreak),
        makeRecord(sessionType: SessionType.longBreak),
      ];
      await repository.saveSessions(replacement);

      expect(await repository.loadSessions(), replacement);
    });

    test('clearSessions removes the stored history', () async {
      final repository = SessionRepository();
      await repository.saveSession(makeRecord());

      await repository.clearSessions();

      expect(await repository.loadSessions(), isEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(SessionRepository.storageKey), isNull);
    });

    test(
      'persists and reloads every session type through a new instance',
      () async {
        final records = [
          makeRecord(),
          makeRecord(
            sessionType: SessionType.shortBreak,
            startedAt: DateTime.utc(2026, 1, 1, 9),
          ),
          makeRecord(
            sessionType: SessionType.longBreak,
            startedAt: DateTime.utc(2026, 1, 1, 10),
          ),
        ];

        await SessionRepository().saveSessions(records);
        final loaded = await SessionRepository().loadSessions();

        expect(loaded, records);
      },
    );

    test('skips corrupt entries while keeping valid records', () async {
      final valid = makeRecord();
      final payload = jsonEncode(<Object>[
        valid.toJson(),
        <String, Object>{'sessionType': 'unknown'},
        <String, Object>{
          'sessionType': 'focus',
          'startedAt': 'bad-date',
          'completedAt': 'bad-date',
          'durationMs': 1000,
        },
        42,
        'not a record',
      ]);
      SharedPreferences.setMockInitialValues(<String, Object>{
        SessionRepository.storageKey: payload,
      });

      expect(await SessionRepository().loadSessions(), [valid]);
    });

    test('uses the injected preferences provider', () async {
      var calls = 0;
      final repository = SessionRepository(
        preferencesProvider: () {
          calls++;
          return SharedPreferences.getInstance();
        },
      );

      await repository.saveSession(makeRecord());

      // saveSession loads the current history and then writes it.
      expect(calls, 2);
      expect(await repository.loadSessions(), hasLength(1));
      expect(calls, 3);
    });
  });
}
