import 'package:flutter/material.dart';

import '../models/pomodoro_state.dart';

class TimerControls extends StatelessWidget {
  const TimerControls({
    super.key,
    required this.status,
    required this.accent,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
  });

  final TimerStatus status;
  final Color accent;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final running = status == TimerStatus.running;
    final idle = status == TimerStatus.idle;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: running ? onPause : (idle ? onStart : onResume),
            icon: Icon(
              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(running ? 'Tạm dừng' : (idle ? 'Bắt đầu' : 'Tiếp tục')),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 54),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Đặt lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF46554C),
              side: const BorderSide(color: Color(0xFFD7DDD5)),
              minimumSize: const Size(0, 54),
            ),
          ),
        ),
      ],
    );
  }
}
