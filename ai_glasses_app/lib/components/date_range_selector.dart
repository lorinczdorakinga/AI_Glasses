import 'package:flutter/material.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final VoidCallback onTap;

  const DateRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onTap,
  });

  // Ez a logika formázza meg a szöveget. Ha nincs választott dátum, 
  // akkor "Last week"-et ír, különben a választott intervallumot.
  String get _formattedText {
    if (selectedRange == null) return 'Last week';
    final start = selectedRange!.start;
    final end = selectedRange!.end;
    return '${start.month}.${start.day}. - ${end.month}.${end.day}.';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Csak akkora legyen, amekkora a tartalom
          children: [
            Text(
              _formattedText,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_month, color: Colors.black, size: 28),
          ],
        ),
      ),
    );
  }
}