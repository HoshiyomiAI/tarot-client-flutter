import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home.dart';
import 'screens/chat.dart';
import 'screens/profile.dart';
import 'screens/calendar.dart';
import 'screens/settings.dart';
import 'screens/detail.dart';
import 'widgets/nav_shell.dart';
import 'screens/history.dart';
import 'screens/tarot_reading.dart';
import 'screens/card_face.dart';
import 'screens/account_login.dart';
import 'screens/account_data.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        pageBuilder: (context, state, child) => NoTransitionPage<void>(
          child: NavShell(child: child),
        ),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: ChatScreen(
                init: state.extra as ChatInit?,
                threadId: state.uri.queryParameters['t'],
              ),
            ),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/card-face',
            name: 'card-face',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: CardFaceScreen(),
            ),
          ),
          GoRoute(
            path: '/card-face/front',
            name: 'card-face-front',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: CardFaceFrontScreen(),
            ),
          ),
          GoRoute(
            path: '/card-face/back',
            name: 'card-face-back',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: CardFaceBackScreen(),
            ),
          ),
          GoRoute(
            path: '/account/login',
            name: 'account-login',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: AccountLoginScreen(),
            ),
          ),
          GoRoute(
            path: '/account/data',
            name: 'account-data',
            pageBuilder: (context, state) => const NoTransitionPage<void>(
              child: AccountDataScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          child: const CalendarScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/detail',
        name: 'detail',
        builder: (context, state) => const DetailScreen(),
      ),
      GoRoute(
        path: '/reading',
        name: 'reading',
        builder: (context, state) => const TarotReadingScreen(),
      ),
    ],
  );
}

