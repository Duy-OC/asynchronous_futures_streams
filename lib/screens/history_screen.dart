import 'package:flutter/material.dart';

import '../models/pomodoro_state.dart';
import '../models/session_record.dart';
import '../services/session_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.repository});

  final SessionRepository repository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SessionRecord>> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = widget.repository.loadSessions();
  }

  String _label(SessionType type) => switch (type) {
    SessionType.focus => 'Tập trung',
    SessionType.shortBreak => 'Nghỉ ngắn',
    SessionType.longBreak => 'Nghỉ dài',
  };

  String _date(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}  ·  '
        '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử phiên',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<SessionRecord>>(
        future: _sessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Không thể tải lịch sử.'));
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Color(0xFF829589),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có phiên nào hoàn thành',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Phiên đầu tiên của bạn sẽ xuất hiện ở đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF78847C)),
                    ),
                  ],
                ),
              ),
            );
          }
          final newestFirst = records.reversed.toList();
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: newestFirst.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final record = newestFirst[index];
              final isFocus = record.sessionType == SessionType.focus;
              return Card(
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isFocus
                            ? const Color(0xFFE7F1E9)
                            : const Color(0xFFF6EDE5),
                        child: Icon(
                          isFocus ? Icons.spa_outlined : Icons.coffee_outlined,
                          color: isFocus
                              ? const Color(0xFF467D60)
                              : const Color(0xFFAC7953),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _label(record.sessionType),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _date(record.completedAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF77837B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${record.duration.inMinutes} phút',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B6855),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
