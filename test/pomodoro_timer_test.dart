import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/models/pomodoro_state.dart';
import 'package:pomodoro/models/session_record.dart';
import 'package:pomodoro/services/pomodoro_timer.dart';

void main() {
  group('SessionType', () {
    test('uses the durations and labels from the plan', () {
      expect(SessionType.focus.label, 'Focus');
      expect(SessionType.shortBreak.label, 'Short break');
      expect(SessionType.longBreak.label, 'Long break');

      expect(SessionType.focus.defaultDuration, const Duration(minutes: 25));
      expect(
        SessionType.shortBreak.defaultDuration,
        const Duration(minutes: 5),
      );
      expect(
        SessionType.longBreak.defaultDuration,
        const Duration(minutes: 15),
      );

      expect(SessionType.focus.isBreak, isFalse);
      expect(SessionType.shortBreak.isBreak, isTrue);
      expect(SessionType.longBreak.isBreak, isTrue);
    });
  });

  group('PomodoroState', () {
    test('initial state is an idle focus session', () {
      final state = PomodoroState.initial();

      expect(state.sessionType, SessionType.focus);
      expect(state.remaining, const Duration(minutes: 25));
      expect(state.totalDuration, const Duration(minutes: 25));
      expect(state.status, TimerStatus.idle);
      expect(state.completedFocusSessions, 0);
      expect(state.isIdle, isTrue);
      expect(state.isRunning, isFalse);
      expect(state.isPaused, isFalse);
      expect(state.isFocusSession, isTrue);
      expect(state.progress, 0);
      expect(state.formattedTime, '25:00');
    });

    test('initial state supports a custom session and duration', () {
      final state = PomodoroState.initial(
        sessionType: SessionType.shortBreak,
        duration: const Duration(minutes: 2),
      );

      expect(state.sessionType, SessionType.shortBreak);
      expect(state.remaining, const Duration(minutes: 2));
      expect(state.totalDuration, const Duration(minutes: 2));
      expect(state.isFocusSession, isFalse);
    });

    test('computes progress from elapsed time', () {
      const state = PomodoroState(
        sessionType: SessionType.focus,
        remaining: Duration(minutes: 12, seconds: 34),
        totalDuration: Duration(minutes: 25),
        status: TimerStatus.running,
      );

      expect(state.formattedTime, '12:34');
      expect(
        state
            .copyWith(
              remaining: const Duration(
                minutes: 12,
                seconds: 33,
                milliseconds: 1,
              ),
            )
            .formattedTime,
        '12:34',
      );
      expect(state.progress, closeTo(746 / 1500, 1e-9));

      expect(state.copyWith(remaining: Duration.zero).progress, 1);
      expect(state.copyWith(remaining: state.totalDuration).progress, 0);
    });

    test('clamps progress and formatted time for out-of-range values', () {
      const beyondTotal = PomodoroState(
        sessionType: SessionType.focus,
        remaining: Duration(seconds: 20),
        totalDuration: Duration(seconds: 10),
        status: TimerStatus.running,
      );
      expect(beyondTotal.progress, 0);

      const negative = PomodoroState(
        sessionType: SessionType.focus,
        remaining: Duration(seconds: -2),
        totalDuration: Duration(seconds: 10),
        status: TimerStatus.running,
      );
      expect(negative.progress, 1);
      expect(negative.formattedTime, '00:00');

      const zeroTotal = PomodoroState(
        sessionType: SessionType.focus,
        remaining: Duration.zero,
        totalDuration: Duration.zero,
        status: TimerStatus.idle,
      );
      expect(zeroTotal.progress, 0);
    });

    test('copyWith changes only the provided fields', () {
      final initial = PomodoroState.initial();
      final updated = initial.copyWith(
        sessionType: SessionType.longBreak,
        remaining: const Duration(minutes: 4),
        totalDuration: const Duration(minutes: 15),
        status: TimerStatus.paused,
        completedFocusSessions: 3,
      );

      expect(updated.sessionType, SessionType.longBreak);
      expect(updated.remaining, const Duration(minutes: 4));
      expect(updated.totalDuration, const Duration(minutes: 15));
      expect(updated.status, TimerStatus.paused);
      expect(updated.completedFocusSessions, 3);
      expect(updated.isPaused, isTrue);
    });

    test('value equality compares every field', () {
      const first = PomodoroState(
        sessionType: SessionType.focus,
        remaining: Duration(seconds: 10),
        totalDuration: Duration(seconds: 20),
        status: TimerStatus.running,
        completedFocusSessions: 2,
      );
      const same = PomodoroState(
        sessionType: SessionType.focus,
        remaining: Duration(seconds: 10),
        totalDuration: Duration(seconds: 20),
        status: TimerStatus.running,
        completedFocusSessions: 2,
      );
      const different = PomodoroState(
        sessionType: SessionType.focus,
        remaining: Duration(seconds: 9),
        totalDuration: Duration(seconds: 20),
        status: TimerStatus.running,
        completedFocusSessions: 2,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('PomodoroTimer', () {
    late DateTime base;

    setUp(() {
      base = DateTime.utc(2026, 1, 1, 8);
    });

    test('starts idle on a full focus session', () {
      fakeAsync((async) {
        final timer = PomodoroTimer(now: () => base.add(async.elapsed));

        expect(timer.state, PomodoroState.initial());
        expect(timer.isDisposed, isFalse);

        timer.dispose();
      });
    });

    test('counts down, pauses, resumes and completes sessions', () {
      fakeAsync((async) {
        final records = <SessionRecord>[];
        final timer = PomodoroTimer(
          focusDuration: const Duration(seconds: 5),
          shortBreakDuration: const Duration(seconds: 2),
          longBreakDuration: const Duration(seconds: 9),
          now: () => base.add(async.elapsed),
          onSessionCompleted: records.add,
        );

        timer.start();
        expect(timer.state.status, TimerStatus.running);
        expect(timer.state.remaining, const Duration(seconds: 5));

        async.elapse(const Duration(seconds: 2));
        expect(timer.state.remaining, const Duration(seconds: 3));
        expect(records, isEmpty);

        timer.pause();
        expect(timer.state.status, TimerStatus.paused);
        expect(timer.state.remaining, const Duration(seconds: 3));

        async.elapse(const Duration(seconds: 10));
        expect(timer.state.status, TimerStatus.paused);
        expect(timer.state.remaining, const Duration(seconds: 3));
        expect(records, isEmpty);

        timer.resume();
        expect(timer.state.status, TimerStatus.running);
        async.elapse(const Duration(seconds: 3));

        expect(records, hasLength(1));
        final focusRecord = records.single;
        expect(focusRecord.sessionType, SessionType.focus);
        expect(focusRecord.startedAt, base);
        expect(focusRecord.completedAt, base.add(const Duration(seconds: 15)));
        expect(focusRecord.duration, const Duration(seconds: 5));

        expect(timer.state.sessionType, SessionType.shortBreak);
        expect(timer.state.status, TimerStatus.running);
        expect(timer.state.remaining, const Duration(seconds: 2));
        expect(timer.state.completedFocusSessions, 1);

        async.elapse(const Duration(seconds: 2));
        expect(records, hasLength(2));
        expect(records.last.sessionType, SessionType.shortBreak);
        expect(records.last.duration, const Duration(seconds: 2));
        expect(timer.state.sessionType, SessionType.focus);
        expect(timer.state.completedFocusSessions, 1);

        timer.dispose();
      });
    });

    test('start also resumes a paused session', () {
      fakeAsync((async) {
        final timer = PomodoroTimer(
          focusDuration: const Duration(seconds: 4),
          shortBreakDuration: const Duration(seconds: 2),
          longBreakDuration: const Duration(seconds: 6),
          now: () => base.add(async.elapsed),
        );

        timer.start();
        async.elapse(const Duration(seconds: 1));
        timer.pause();
        expect(timer.state.remaining, const Duration(seconds: 3));

        timer.start();
        expect(timer.state.status, TimerStatus.running);
        async.elapse(const Duration(seconds: 3));

        expect(timer.state.sessionType, SessionType.shortBreak);
        expect(timer.state.completedFocusSessions, 1);

        timer.dispose();
      });
    });

    test('ignores pause and resume when they are not applicable', () {
      fakeAsync((async) {
        final timer = PomodoroTimer(
          focusDuration: const Duration(seconds: 3),
          shortBreakDuration: const Duration(seconds: 2),
          longBreakDuration: const Duration(seconds: 5),
          now: () => base.add(async.elapsed),
        );

        timer.pause();
        timer.resume();
        expect(timer.state.status, TimerStatus.idle);
        expect(timer.state.remaining, const Duration(seconds: 3));

        timer.start();
        timer.start();
        async.elapse(const Duration(seconds: 1));
        expect(timer.state.remaining, const Duration(seconds: 2));

        timer.dispose();
      });
    });

    test('alternates sessions and schedules a long break after the configured '
        'number of focus sessions', () {
      fakeAsync((async) {
        final records = <SessionRecord>[];
        final timer = PomodoroTimer(
          focusDuration: const Duration(seconds: 2),
          shortBreakDuration: const Duration(seconds: 1),
          longBreakDuration: const Duration(seconds: 5),
          sessionsBeforeLongBreak: 2,
          now: () => base.add(async.elapsed),
          onSessionCompleted: records.add,
        );

        timer.start();

        async.elapse(const Duration(seconds: 2));
        expect(timer.state.sessionType, SessionType.shortBreak);
        expect(timer.state.remaining, const Duration(seconds: 1));
        expect(timer.state.completedFocusSessions, 1);

        async.elapse(const Duration(seconds: 1));
        expect(timer.state.sessionType, SessionType.focus);
        expect(timer.state.remaining, const Duration(seconds: 2));

        async.elapse(const Duration(seconds: 2));
        expect(timer.state.sessionType, SessionType.longBreak);
        expect(timer.state.remaining, const Duration(seconds: 5));
        expect(timer.state.completedFocusSessions, 2);

        async.elapse(const Duration(seconds: 5));
        expect(timer.state.sessionType, SessionType.focus);
        expect(timer.state.completedFocusSessions, 2);
        expect(timer.state.status, TimerStatus.running);

        expect(records.map((record) => record.sessionType), [
          SessionType.focus,
          SessionType.shortBreak,
          SessionType.focus,
          SessionType.longBreak,
        ]);

        timer.dispose();
      });
    });

    test('reset stops the countdown and restores the full current session', () {
      fakeAsync((async) {
        final timer = PomodoroTimer(
          focusDuration: const Duration(seconds: 5),
          shortBreakDuration: const Duration(seconds: 2),
          longBreakDuration: const Duration(seconds: 4),
          now: () => base.add(async.elapsed),
        );

        timer.start();
        async.elapse(const Duration(seconds: 2));
        timer.reset();

        expect(timer.state.status, TimerStatus.idle);
        expect(timer.state.remaining, const Duration(seconds: 5));
        expect(timer.state.totalDuration, const Duration(seconds: 5));
        expect(timer.state.completedFocusSessions, 0);

        async.elapse(const Duration(seconds: 10));
        expect(timer.state.status, TimerStatus.idle);
        expect(timer.state.remaining, const Duration(seconds: 5));

        timer.start();
        async.elapse(const Duration(seconds: 5));
        expect(timer.state.sessionType, SessionType.shortBreak);
        expect(timer.state.completedFocusSessions, 1);

        timer.dispose();
      });
    });

    test(
      'reset preserves completed focus sessions and the current break type',
      () {
        fakeAsync((async) {
          final timer = PomodoroTimer(
            focusDuration: const Duration(seconds: 2),
            shortBreakDuration: const Duration(seconds: 3),
            longBreakDuration: const Duration(seconds: 4),
            now: () => base.add(async.elapsed),
          );

          timer.start();
          async.elapse(const Duration(seconds: 2));

          timer.reset();
          expect(timer.state.sessionType, SessionType.shortBreak);
          expect(timer.state.status, TimerStatus.idle);
          expect(timer.state.remaining, const Duration(seconds: 3));
          expect(timer.state.completedFocusSessions, 1);

          timer.dispose();
        });
      },
    );

    test('emits every state change through the broadcast stream', () {
      fakeAsync((async) {
        final timer = PomodoroTimer(
          focusDuration: const Duration(seconds: 3),
          shortBreakDuration: const Duration(seconds: 2),
          longBreakDuration: const Duration(seconds: 4),
          now: () => base.add(async.elapsed),
        );
        final events = <PomodoroState>[];
        final subscription = timer.stream.listen(events.add);

        expect(events, isEmpty);

        timer.start();
        async.flushMicrotasks();
        expect(events, hasLength(1));
        expect(events.single.status, TimerStatus.running);

        async.elapse(const Duration(seconds: 1));
        expect(events.last.remaining, const Duration(seconds: 2));

        timer.pause();
        async.flushMicrotasks();
        expect(events.last.status, TimerStatus.paused);

        timer.dispose();
        async.flushMicrotasks();
        unawaited(subscription.cancel());
      });
    });

    test(
      'dispose cancels the ticker, closes the stream and disables actions',
      () {
        fakeAsync((async) {
          final timer = PomodoroTimer(
            focusDuration: const Duration(seconds: 5),
            shortBreakDuration: const Duration(seconds: 2),
            longBreakDuration: const Duration(seconds: 4),
            now: () => base.add(async.elapsed),
          );
          var streamDone = false;
          timer.stream.listen((_) {}, onDone: () => streamDone = true);

          timer.start();
          async.elapse(const Duration(seconds: 1));
          expect(timer.state.remaining, const Duration(seconds: 4));

          timer.dispose();
          expect(timer.isDisposed, isTrue);
          async.flushMicrotasks();
          expect(streamDone, isTrue);

          timer.start();
          timer.pause();
          timer.resume();
          timer.reset();
          async.elapse(const Duration(seconds: 20));

          expect(timer.state.status, TimerStatus.running);
          expect(timer.state.remaining, const Duration(seconds: 4));
        });
      },
    );
  });
}
