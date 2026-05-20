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

  // Mock adatok, amik a diagramot és a listát is táplálják (backendből fognak jönni)
  final List<double> _chartData = [4, 2, 5, 3, 4]; // F, C, A, S, E
  final List<String> _titles = ['F', 'C', 'A', 'S', 'E'];
  final List<String> _fullNames = ['Focus', 'Consumption', 'Activity', 'Social', 'Explore'];
  final List<IconData> _icons = [Icons.center_focus_strong, Icons.phone_android, Icons.directions_run, Icons.people, Icons.travel_explore];

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal.shade600, 
              onPrimary: Colors.white, 
              onSurface: Colors.black87, 
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      // fetchNewRadarData(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA), // Sleek Teal háttér
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Progression',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              
              // EGYEDI DÁTUM VÁLASZTÓ GOMB
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: DateRangeSelector(
                  selectedRange: _selectedDateRange,
                  onTap: _pickDateRange,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // A NAGY RADAR DIAGRAM KÁRTYA
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: SizedBox(
                  height: 280, // Hatalmas, gyönyörű grafikon
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          dataEntries: _chartData.map((val) => RadarEntry(value: val)).toList(),
                          fillColor: Colors.teal.shade400.withValues(alpha: 0.25),
                          borderColor: Colors.teal.shade600,
                          entryRadius: 4, // Kis pöttyök a sarkokon
                          borderWidth: 3,
                        ),
                      ],
                      getTitle: (index, angle) {
                        return RadarChartTitle(
                          text: _titles[index],
                          angle: angle,
                        );
                      },
                      tickCount: 5, // 5 szint (0-5)
                      ticksTextStyle: const TextStyle(color: Colors.transparent),
                      gridBorderData: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      radarBorderData: BorderSide(color: Colors.grey.shade300, width: 2),
                      titlePositionPercentageOffset: 0.15, // Címek távolsága
                    ),
                    duration: const Duration(milliseconds: 300),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              const Text('Goal Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              
              // JELMAGYARÁZAT / ÉRTÉKELÉS (Automatikusan épül a chart adataiból)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final score = _chartData[index];
                  final percentage = (score / 5.0); // 5 a maximum érték

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                          child: Icon(_icons[index], color: Colors.teal.shade600, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fullNames[index],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              // Kis progress bar az adott kategóriához
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade200,
                                  color: Colors.teal.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${(percentage * 100).toInt()}%',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.teal.shade800),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}