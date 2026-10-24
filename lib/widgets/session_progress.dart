import 'package:flutter/material.dart';

class SessionProgress extends StatelessWidget {
  const SessionProgress({super.key, required this.completedFocusSessions});

  final int completedFocusSessions;

  @override
  Widget build(BuildContext context) {
    final cycle = completedFocusSessions % 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TIẾN TRÌNH CHU KỲ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Color(0xFF79847D),
              ),
            ),
            Text(
              '$cycle / 4 phiên',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF425A49),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: index < cycle
                        ? const Color(0xFF4C8065)
                        : const Color(0xFFE4E8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 11),
        const Text(
          'Hoàn thành 4 phiên tập trung để nghỉ dài.',
          style: TextStyle(fontSize: 12, color: Color(0xFF79847D)),
        ),
      ],
    );
  }
}
