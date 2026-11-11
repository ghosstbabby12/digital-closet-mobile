import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:closet_ai/core/theme/app_theme.dart';
import 'package:closet_ai/features/outfits/domain/outfit.dart';
import 'package:closet_ai/features/outfits/presentation/controllers/outfit_controller.dart';
import 'package:closet_ai/features/outfits/presentation/widgets/outfit_calendar.dart';
import 'package:closet_ai/features/outfits/presentation/widgets/outfit_card.dart';
import 'package:closet_ai/core/widgets/pill_tabs.dart';
import 'package:closet_ai/features/home/presentation/widgets/screen_header.dart';
import 'package:closet_ai/core/utils/text.dart';
import 'package:closet_ai/core/widgets/error_snackbar.dart';
import 'package:closet_ai/features/outfits/presentation/controllers/outfit_actions.dart';
import 'package:closet_ai/core/widgets/confirm_dialog.dart';

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

  Future<void> _delete(Outfit outfit) async {
    final confirmed = await confirmDestructive(
      context,
      title: outfit.isEvent ? '¿Borrar evento?' : '¿Borrar outfit?',
      message:
          'Se borrará ${outfit.isEvent ? 'el evento "${outfit.eventTitle}" y su outfit' : 'este outfit'}. '
          'Tus prendas siguen en el clóset.',
    );
    if (!confirmed) return;
    try {
      await ref.read(outfitActionsProvider).delete(outfit.id);
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    }
  }

  Widget _calendar(List<Outfit> outfits) {
    // The day's events first, then the outfits generated that day.
    final dayOutfits = outfits.where((outfit) => DateUtils.isSameDay(outfit.calendarDay, _selectedDay)).toList()
      ..sort((a, b) => (b.isEvent ? 1 : 0).compareTo(a.isEvent ? 1 : 0));
    final isPast = _selectedDay.isBefore(DateUtils.dateOnly(DateTime.now()));
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
        Row(
          children: [
            Expanded(child: Text(capitalized(dayName), style: Theme.of(context).textTheme.titleLarge)),
            if (!isPast)
              TextButton.icon(
                onPressed: () => context.push('/add-event', extra: _selectedDay),
                icon: const Icon(Icons.add),
                label: const Text('Agregar evento'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (dayOutfits.isEmpty)
          const Text('No hay outfits este día.')
        else
          for (final outfit in dayOutfits)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OutfitCard(outfit: outfit, onDelete: () => _delete(outfit)),
            ),
      ],
    );
  }
}
