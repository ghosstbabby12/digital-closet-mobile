import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/try_on/presentation/controllers/try_on_request_provider.dart';

import 'package:closet_ai/features/home/presentation/widgets/floating_nav_bar.dart';
import 'package:closet_ai/features/home/presentation/widgets/mirror_icon.dart';
import 'package:closet_ai/features/closet/presentation/screens/closet_screen.dart';
import 'package:closet_ai/features/outfits/presentation/screens/stylist_screen.dart';
import 'package:closet_ai/features/outfits/presentation/screens/outfits_screen.dart';
import 'package:closet_ai/features/try_on/presentation/screens/try_on_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _tryOnIndex = 2;

  int _index = 1;

  static const _screens = [ClosetScreen(), StylistScreen(), TryOnScreen(), HistoryScreen()];
  static const _items = [
    FloatingNavItem(icon: Icons.checkroom_outlined, selectedIcon: Icons.checkroom, label: 'Clóset'),
    FloatingNavItem(icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: 'Estilista'),
    FloatingNavItem.custom(iconBuilder: _mirror, label: 'Probador'),
    FloatingNavItem(icon: Icons.dry_cleaning_outlined, selectedIcon: Icons.dry_cleaning, label: 'Outfits'),
  ];

  static Widget _mirror(Color color, bool selected) => MirrorIcon(size: 22, color: color, filled: selected);

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
