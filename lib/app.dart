import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class PlanoraApp extends StatefulWidget {
  const PlanoraApp({super.key});

  @override
  State<PlanoraApp> createState() => _PlanoraAppState();
}

class _PlanoraAppState extends State<PlanoraApp> {
  static const _primary = Color(0xFF0D9488);
  static const _accent = Color(0xFFFB923C);

  ThemeMode _themeMode = ThemeMode.light;

  void _updateThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _accent,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: const Color(0xFF14B8A6),
      secondary: _accent,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Planora',
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: HomeScreen(
        themeMode: _themeMode,
        onThemeModeChanged: _updateThemeMode,
      ),
    );
  }
}
