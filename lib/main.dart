import 'package:flutter/material.dart';

import 'screens/pomodoro_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1F2925);
    const cream = Color(0xFFF8F7F2);
    return MaterialApp(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F725A),
          surface: cream,
          onSurface: ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
          elevation: 0,
        ),
      ),
      home: const PomodoroScreen(),
    );
  }
}
