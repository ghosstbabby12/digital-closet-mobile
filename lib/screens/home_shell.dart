import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/try_on_request_provider.dart';

import '../widgets/floating_nav_bar.dart';
import 'closet_screen.dart';
import 'generate_outfit_screen.dart';
import 'history_screen.dart';
import 'try_on_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _tryOnIndex = 2;

  int _index = 1;

  static const _screens = [ClosetScreen(), GenerateOutfitScreen(), TryOnScreen(), HistoryScreen()];
  static const _items = [
    FloatingNavItem(icon: Icons.checkroom_outlined, selectedIcon: Icons.checkroom, label: 'Clóset'),
    FloatingNavItem(icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: 'Estilista'),
    FloatingNavItem(icon: Icons.accessibility_new_outlined, selectedIcon: Icons.accessibility_new, label: 'Probador'),
    FloatingNavItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Outfits'),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen(tryOnRequestProvider, (previous, next) {
      if (next != null) setState(() => _index = _tryOnIndex);
    });
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: FloatingNavBar(
        items: _items,
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}
