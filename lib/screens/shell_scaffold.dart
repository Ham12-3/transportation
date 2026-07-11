import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Bottom-nav shell hosting Home, Nearby, Air and Saved.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.blueTint,
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : AppColors.muted,
              )),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : AppColors.muted,
              )),
        ),
        child: NavigationBar(
          height: 66,
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Plan'),
            NavigationDestination(
                icon: Icon(Icons.near_me_outlined),
                selectedIcon: Icon(Icons.near_me),
                label: 'Nearby'),
            NavigationDestination(
                icon: Icon(Icons.flight_outlined),
                selectedIcon: Icon(Icons.flight),
                label: 'Air'),
            NavigationDestination(
                icon: Icon(Icons.star_outline_rounded),
                selectedIcon: Icon(Icons.star_rounded),
                label: 'Saved'),
          ],
        ),
      ),
    );
  }
}
