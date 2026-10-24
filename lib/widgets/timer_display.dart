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
    return Semantics(
      label: 'Thời gian còn lại ${state.formattedTime}',
      child: SizedBox.square(
        dimension: diameter,
        child: CustomPaint(
          painter: _TimerRingPainter(progress: state.progress, color: accent),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.formattedTime,
                style: const TextStyle(
                  fontSize: 62,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -3,
                  color: Color(0xFF1F2925),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                switch (state.status) {
                  TimerStatus.idle => 'SẴN SÀNG',
                  TimerStatus.running => 'ĐANG ĐẾM GIỜ',
                  TimerStatus.paused => 'ĐÃ TẠM DỪNG',
                },
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final track = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, active);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
