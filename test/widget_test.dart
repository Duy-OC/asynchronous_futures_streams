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

  testWidgets('focus duration can be set and restored', (tester) async {
    await tester.pumpWidget(const FocusFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('TẠO KHÔNG GIAN CHO ĐIỀU QUAN TRỌNG'), findsNothing);
    expect(
      find.text('Một việc tại một thời điểm. Bạn làm được mà.'),
      findsNothing,
    );
    await tester.tap(find.text('25 phút'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '40');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('40:00'), findsOneWidget);
    expect(find.text('40 phút'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('focus_flow_focus_minutes'), 40);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const FocusFlowApp());
    await tester.pumpAndSettle();
    expect(find.text('40:00'), findsOneWidget);
  });
}
