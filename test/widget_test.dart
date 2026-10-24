import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('timer controls and history navigation work', (tester) async {
    await tester.pumpWidget(const FocusFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu'));
    await tester.pump();
    expect(find.text('Tạm dừng'), findsOneWidget);

    await tester.tap(find.text('Tạm dừng'));
    await tester.pump();
    expect(find.text('Tiếp tục'), findsOneWidget);

    await tester.tap(find.text('Đặt lại'));
    await tester.pump();
    expect(find.text('Bắt đầu'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có phiên nào hoàn thành'), findsOneWidget);
  });
}
