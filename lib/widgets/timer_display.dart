import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/pomodoro_state.dart';

class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key, required this.state, required this.accent});
  final PomodoroState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final diameter = math.min(290.0, MediaQuery.sizeOf(context).width - 48);
    final statusText = switch (state.status) {
      TimerStatus.idle => 'SẴN SÀNG',
      TimerStatus.running => 'ĐANG ĐẾM GIỜ',
      TimerStatus.paused => 'ĐÃ TẠM DỪNG',
    };
    return Semantics(
      label: 'Thời gian còn lại ${state.formattedTime}',
      child: SizedBox.square(
        dimension: diameter,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: state.progress,
              strokeWidth: 9,
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.12),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(state.formattedTime,
              style: const TextStyle(fontSize: 62, fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 12),
            Text(statusText, style: TextStyle(color: accent)),
          ]),
        ]),
      ),
    );
  }
}
