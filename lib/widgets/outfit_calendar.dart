import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/image_url.dart';
import '../models/garment.dart';
import '../models/outfit.dart';

/// Calendario mensual: cada día muestra una prenda del outfit generado ese día.
class OutfitCalendar extends StatefulWidget {
  final List<Outfit> outfits;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const OutfitCalendar({
    super.key,
    required this.outfits,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  State<OutfitCalendar> createState() => _OutfitCalendarState();
}

class _OutfitCalendarState extends State<OutfitCalendar> {
  static const _weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  late DateTime _month = DateTime(widget.selectedDay.year, widget.selectedDay.month);

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  /// Primera prenda disponible por día, para la miniatura de la celda.
  Map<DateTime, Garment?> _thumbnailsByDay() {
    final thumbnails = <DateTime, Garment?>{};
    for (final outfit in widget.outfits) {
      final local = outfit.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      thumbnails[day] ??= outfit.garments.isNotEmpty ? outfit.garments.first : null;
    }
    return thumbnails;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final thumbnails = _thumbnailsByDay();
    final monthName = DateFormat('MMMM y', 'es').format(_month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = _month.weekday - 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mes anterior',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Expanded(
                  child: Text(
                    '${monthName[0].toUpperCase()}${monthName.substring(1)}',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Mes siguiente',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final weekday in _weekdays)
                  Expanded(child: Text(weekday, textAlign: TextAlign.center, style: textTheme.bodySmall)),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 0.82,
              ),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();
                final day = DateTime(_month.year, _month.month, index - leadingBlanks + 1);
                return _DayCell(
                  day: day,
                  selected: DateUtils.isSameDay(day, widget.selectedDay),
                  hasOutfit: thumbnails.containsKey(day),
                  thumbnail: thumbnails[day],
                  onTap: () => widget.onDaySelected(day),
                  scheme: scheme,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool selected;
  final bool hasOutfit;
  final Garment? thumbnail;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _DayCell({
    required this.day,
    required this.selected,
    required this.hasOutfit,
    required this.thumbnail,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat('d MMMM', 'es').format(day),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                '${day.day}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: foreground),
              ),
              if (hasOutfit)
                Expanded(
                  child: thumbnail != null
                      ? Image.network(
                          fullImageUrl(thumbnail!.imageUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.checkroom, size: 16, color: foreground),
                        )
                      : Icon(Icons.checkroom, size: 16, color: foreground),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
