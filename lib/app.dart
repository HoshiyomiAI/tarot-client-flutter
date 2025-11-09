import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'router.dart';

class TarotApp extends StatelessWidget {
  const TarotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createRouter();
    return MaterialApp.router(
      title: 'Tarot Minimal',
      routerConfig: router,
      scrollBehavior: const AppScrollBehavior(),
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

// 全局滚动行为：移除过度滚动的水波纹/辉光，并允许触控/鼠标/触控笔拖拽
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
      };
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    // 移除默认的辉光效果，保持沉稳的移动端滚动体验
    return child;
  }
}
