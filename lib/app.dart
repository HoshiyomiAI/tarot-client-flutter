import 'package:flutter/material.dart';
import 'router.dart';

class TarotApp extends StatelessWidget {
  const TarotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createRouter();
    return MaterialApp.router(
      title: 'Tarot Minimal',
      routerConfig: router,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF9E83FF),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF9E83FF),
        scaffoldBackgroundColor: const Color(0xFF121019),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1724)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1724),
          selectedItemColor: Color(0xFFFFD57A),
          unselectedItemColor: Color(0xFF8A809E),
        ),
      ),
    );
  }
}

