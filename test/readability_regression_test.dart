import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/models/pomodoro_state.dart';
import 'package:pomodoro/models/session_record.dart';
import 'package:pomodoro/screens/pomodoro_screen.dart';
import 'package:pomodoro/services/pomodoro_timer.dart';
import 'package:pomodoro/services/session_repository.dart';
import 'package:pomodoro/widgets/session_progress.dart';

class FailingRepository extends SessionRepository {
  @override
  Future<List<SessionRecord>> loadSessions() async => [];

  @override
  Future<void> saveSession(SessionRecord session) async {
    throw StateError('Storage unavailable');
  }
}

void main() {
  test('pause at session boundary leaves next session paused', () {
    fakeAsync((async) {
      final base = DateTime(2026);
      final timer = PomodoroTimer(
        focusDuration: const Duration(seconds: 2),
        tickInterval: const Duration(seconds: 10),
        now: () => base.add(async.elapsed),
      );
      timer.start();
      async.elapse(const Duration(seconds: 2));
      timer.pause();
      expect(timer.state.sessionType, SessionType.shortBreak);
      expect(timer.state.status, TimerStatus.paused);
      expect(timer.state.completedFocusSessions, 1);
      async.elapse(const Duration(minutes: 1));
      expect(timer.state.remaining, const Duration(minutes: 5));
      timer.dispose();
    });
  });

  testWidgets('long break displays a completed cycle', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SessionProgress(completedFocusSessions: 4, isLongBreak: true),
    )));
    expect(find.text('TIẾN TRÌNH CHU KỲ: 4 / 4 phiên'), findsOneWidget);
  });

  testWidgets('failed write does not increase saved count', (tester) async {
    var clock = DateTime(2026);
    await tester.pumpWidget(MaterialApp(home: PomodoroScreen(
      repository: FailingRepository(),
      timerFactory: (completed) => PomodoroTimer(
        focusDuration: const Duration(seconds: 1),
        now: () => clock,
        onSessionCompleted: completed,
      ),
    )));
    await tester.pump();
    await tester.tap(find.text('Bắt đầu'));
    clock = clock.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Phiên tập trung đã lưu: 0'), findsOneWidget);
    expect(find.text('Không thể lưu phiên vừa hoàn thành.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
