import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/outfit.dart';
import '../state/outfit_provider.dart';
import '../widgets/outfit_calendar.dart';
import '../widgets/outfit_card.dart';
import '../widgets/pill_tabs.dart';
import '../widgets/screen_header.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _tab = 0;
  DateTime _selectedDay = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(outfitHistoryProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Outfits'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: PillTabs(
              labels: const ['Guardados', 'Calendario'],
              selectedIndex: _tab,
              onSelected: (index) => setState(() => _tab = index),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(outfitHistoryProvider.future),
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(child: Text('No se pudo cargar tu historial:\n$error', textAlign: TextAlign.center)),
                  ],
                ),
                data: (outfits) => _tab == 0 ? _savedList(outfits) : _calendar(outfits),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedList(List<Outfit> outfits) {
    if (outfits.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Aún no has generado ningún outfit.')),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, floatingNavClearance),
      itemCount: outfits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => OutfitCard(outfit: outfits[index]),
    );
  }

  Widget _calendar(List<Outfit> outfits) {
    final dayOutfits = outfits
        .where((outfit) => DateUtils.isSameDay(outfit.createdAt.toLocal(), _selectedDay))
        .toList();
    final dayName = DateFormat("EEEE, d 'de' MMMM", 'es').format(_selectedDay);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, floatingNavClearance),
      children: [
        OutfitCalendar(
          outfits: outfits,
          selectedDay: _selectedDay,
          onDaySelected: (day) => setState(() => _selectedDay = day),
        ),
        const SizedBox(height: 18),
        Text(
          '${dayName[0].toUpperCase()}${dayName.substring(1)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (dayOutfits.isEmpty)
          const Text('No hay outfits este día.')
        else
          for (final outfit in dayOutfits)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OutfitCard(outfit: outfit),
            ),
      ],
    );
  }
}
