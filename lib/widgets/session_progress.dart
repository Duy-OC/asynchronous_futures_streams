import 'package:flutter/material.dart';

class SessionProgress extends StatelessWidget {
  const SessionProgress({super.key, required this.completedFocusSessions,
    this.isLongBreak = false});
  final int completedFocusSessions;
  final bool isLongBreak;

  @override
  Widget build(BuildContext context) {
    // Trong nghỉ dài vẫn hiển thị đủ 4 phiên của chu kỳ vừa hoàn thành.
    final cycle = isLongBreak ? 4 : completedFocusSessions % 4;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TIẾN TRÌNH CHU KỲ: $cycle / 4 phiên'),
      const SizedBox(height: 14),
      LinearProgressIndicator(value: cycle / 4, minHeight: 8),
      const SizedBox(height: 12),
      const Text('Hoàn thành 4 phiên tập trung để nghỉ dài.'),
    ]);
  }
}
