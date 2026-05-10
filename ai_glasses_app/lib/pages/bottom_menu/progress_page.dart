import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../components/date_range_selector.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  DateTimeRange? _selectedDateRange;

  // Ez a függvény nyitja meg a beépített naptárat
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1), // Ettől régebbre nem lehet lapozni
      lastDate: DateTime.now(),        // A mai nap a maximum
      builder: (context, child) {
        return Theme(
          // Kicsit átszínezzük a naptárat, hogy illeszkedjen a dizájnhoz
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal, 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
          ),
          child: child!,
        );
      },
    );

    // Ha a felhasználó választott dátumot (és nem a Mégse gombra nyomott)
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      // KÉSŐBB ITT LEHET MEGHÍVNI A BACKENDET:
      // fetchNewRadarData(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Az új, egyedi gombod beillesztése
            DateRangeSelector(
              selectedRange: _selectedDateRange,
              onTap: _pickDateRange,
            ),
            
            const SizedBox(height: 40),
            
            // A Spider (Radar) Diagram (Egyelőre a dummy adatokkal)
            Expanded(
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      dataEntries: [
                        const RadarEntry(value: 4), // F
                        const RadarEntry(value: 3), // E
                        const RadarEntry(value: 2), // S
                        const RadarEntry(value: 5), // A
                        const RadarEntry(value: 2), // C
                      ],
                      fillColor: Colors.blueAccent.withValues(alpha: 0.2),
                      borderColor: Colors.blueAccent,
                      entryRadius: 3,
                    ),
                  ],
                  getTitle: (index, angle) {
                    final titles = ['F', 'E', 'S', 'A', 'C'];
                    return RadarChartTitle(
                      text: titles[index],
                      angle: angle,
                    );
                  },
                  tickCount: 5,
                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                  gridBorderData: const BorderSide(color: Colors.black26, width: 1.5),
                  radarBorderData: const BorderSide(color: Colors.black, width: 2),
                ),
                duration: const Duration(milliseconds: 150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}