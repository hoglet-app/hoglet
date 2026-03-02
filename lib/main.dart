import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/activity_screen.dart';

void main() {
  runApp(const HogletApp());
}

class HogletApp extends StatelessWidget {
  const HogletApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme();

    return MaterialApp(
      title: 'Hoglet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF15A24),
          brightness: Brightness.light,
        ),
        textTheme: textTheme,
        useMaterial3: true,
      ),
      home: const ActivityScreen(),
    );
  }
}
