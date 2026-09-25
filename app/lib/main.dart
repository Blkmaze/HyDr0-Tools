import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const MazeToolsApp());

const Color kAccent = Color(0xFF00B4FF);

class MazeToolsApp extends StatelessWidget {
  const MazeToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maze-Tools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0D12),
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent, brightness: Brightness.dark),
        useMaterial3: true,
        chipTheme: const ChipThemeData(showCheckmark: false),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
