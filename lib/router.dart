import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/journey.dart';
import 'screens/airports_screen.dart';
import 'screens/home_screen.dart';
import 'screens/nearby_screen.dart';
import 'screens/results_screen.dart';
import 'screens/route_detail_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/shell_scaffold.dart';
import 'ar/ar_navigation_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScaffold(shell: shell),
      branches: [
        StatefulShellBranch(navigatorKey: _shellKey, routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/nearby', builder: (c, s) => const NearbyScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/air', builder: (c, s) => const AirportsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/saved', builder: (c, s) => const SavedScreen()),
        ]),
      ],
    ),
    GoRoute(
      path: '/results',
      parentNavigatorKey: _rootKey,
      builder: (c, s) => const ResultsScreen(),
    ),
    GoRoute(
      path: '/detail',
      parentNavigatorKey: _rootKey,
      builder: (c, s) => RouteDetailScreen(journey: s.extra as Journey),
    ),
    GoRoute(
      path: '/ar',
      parentNavigatorKey: _rootKey,
      builder: (c, s) => ARNavigationScreen(journey: s.extra as Journey),
    ),
  ],
);
