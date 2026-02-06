import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    // IIT Bombay Primary Blue (approximate)
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3C73)),
    textTheme: GoogleFonts.interTextTheme(),
    scaffoldBackgroundColor: Colors.white,
  );
}