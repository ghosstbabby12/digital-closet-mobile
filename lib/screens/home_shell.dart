import 'package:flutter/material.dart';

import '../widgets/floating_nav_bar.dart';
import 'closet_screen.dart';
import 'generate_outfit_screen.dart';
import 'history_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1;

  static const _screens = [ClosetScreen(), GenerateOutfitScreen(), HistoryScreen()];
  static const _items = [
    FloatingNavItem(icon: Icons.checkroom_outlined, selectedIcon: Icons.checkroom, label: 'Clóset'),
    FloatingNavItem(icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: 'Estilista'),
    FloatingNavItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Outfits'),
  ];

  @override
  Widget build(BuildContext context) {
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
