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
  late final Future<List<SessionRecord>> _sessions;

  @override
  void initState() {
    super.initState();
    // Tạo Future một lần, không đọc bộ nhớ lại sau mỗi lần build.
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
    return '${two(local.hour)}:${two(local.minute)} · '
        '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lịch sử phiên')),
    // FUTURE: một lần đọc -> đang tải / lỗi / kết quả.
    body: FutureBuilder<List<SessionRecord>>(
      future: _sessions,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Không thể tải lịch sử.'));
        }
        final records = (snapshot.data ?? []).reversed.toList();
        if (records.isEmpty) {
          return const Center(child: Text('Chưa có phiên nào hoàn thành'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(child: ListTile(
              leading: Icon(record.sessionType == SessionType.focus
                  ? Icons.spa_outlined : Icons.coffee_outlined),
              title: Text(_label(record.sessionType)),
              subtitle: Text(_date(record.completedAt)),
              trailing: Text('${record.duration.inMinutes} phút'),
            ));
          },
        );
      },
    ),
  );
}
