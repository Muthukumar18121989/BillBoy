import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../blocs/bill/bill_bloc.dart';
import '../blocs/bill/bill_event.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _routes = ['/home', '/analytics', '/warranty', '/search', '/settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
            context.go(_routes[index]);
            if (index == 0) {
              // Reload bills when returning to home
              context.read<BillBloc>().add(const BillLoadEvent());
            }
          },
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? AppColors.surfaceLight
              : AppColors.surfaceDark,
          indicatorColor: AppColors.primary.withOpacity(0.15),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: const Icon(Icons.shield_outlined),
              selectedIcon: const Icon(Icons.shield_rounded, color: AppColors.primary),
              label: 'Warranty',
            ),
            NavigationDestination(
              icon: const Icon(Icons.search_outlined),
              selectedIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              label: 'Search',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded, color: AppColors.primary),
              label: 'Settings',
            ),
          ],
        ),
      ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOutCubic),
    );
  }
}
