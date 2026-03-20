import 'package:flutter/material.dart';

class AppTheme {
  // Logic: Centralized color palette used throughout the app (Jeepney/Cyberpunk aesthetic)
  static const primary = Color(0xFF5865F2);
  static const accent = Color(0xFF6C63FF);

  // UI: Accent colors used for Story rings, AI Assistant icons, and Dark Mode highlights
  static const neonPurple = Color(0xFFBC13FE);
  static const neonCyan = Color(0xFF0FF0FC);

  // Logic: Configuration for the Light Mode experience
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFFF4F5FA),
    fontFamily: "Roboto",

    // UI: Clean white AppBar for the light version of JoshquadApp
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),

    // UI: Rounded corners for PostCards and Profile sections
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Logic: Styling for CustomTextFields in login/register screens
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );

  // Logic: Configuration for the "Midnight" / Cyberpunk Dark Mode
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: neonPurple, // UI: Switches primary branding to Neon Purple
    hintColor: neonCyan,      // UI: Uses Cyan for subtle highlights and icons
    scaffoldBackgroundColor: const Color(0xFF0D0D0D), // UI: Deep black background

    cardColor: const Color(0xFF1A1A1A), // UI: Dark grey cards to contrast with the black background

    // Connection: Styled AppBar for the top of HomeScreen and Profile
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D0D0D),
      foregroundColor: neonPurple,
      elevation: 0,
    ),

    // Connection: Styles the "+" button for creating posts
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: neonPurple,
      foregroundColor: Colors.white,
    ),

    // Logic: Dark Mode version of input fields with a neon border when selected
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: neonPurple, width: 1),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}