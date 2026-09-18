import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_localizations.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  int get _selectedIndex {
    if (location.startsWith(AppRoutes.community)) return 1;
    if (location.startsWith(AppRoutes.tours)) return 2;
    if (location.startsWith(AppRoutes.messages)) return 3;
    if (location.startsWith(AppRoutes.profile) ||
        location.startsWith(AppRoutes.visits)) {
      return 4;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                    (states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(
                      color: Colors.white,
                    );
                  }

                  return const IconThemeData(
                    color: AppColors.textBrightBlack,
                  );
                },
              ),
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                    (states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      color: Colors.white,
                    );
                  }

                  return const TextStyle(
                    color: AppColors.textBrightBlack,
                  );
                },
              ),
            ),
            child: NavigationBar(
              height: 70,
              elevation: 0,
              backgroundColor: AppColors.surfaceMint.withValues(alpha: 0.97),
              indicatorShape: const StadiumBorder(),
              indicatorColor: AppColors.primary,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go(AppRoutes.home);
                    return;

                  case 1:
                    context.go(AppRoutes.community);
                    return;

                  case 2:
                    context.go(AppRoutes.tours);
                    return;

                  case 3:
                    context.go(AppRoutes.messages);
                    return;

                  case 4:
                    context.go(AppRoutes.profile);
                    return;
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(
                    Icons.explore,
                    color: Colors.white,
                  ),
                  label: context.l10n.text('discover'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.photo_library_outlined),
                  selectedIcon: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                  ),
                  label: context.l10n.text('community'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.tour_outlined),
                  selectedIcon: const Icon(
                    Icons.tour_rounded,
                    color: Colors.white,
                  ),
                  label: context.l10n.text('tours'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.forum_outlined),
                  selectedIcon: const Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                  ),
                  label: context.l10n.text('messages'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                  label: context.l10n.text('profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}