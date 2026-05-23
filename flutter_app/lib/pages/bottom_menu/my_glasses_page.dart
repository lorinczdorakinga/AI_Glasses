import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../scanner_page.dart';

class MyGlassesPage extends StatefulWidget {
  const MyGlassesPage({super.key});

  @override
  State<MyGlassesPage> createState() => _MyGlassesPageState();
}

class _MyGlassesPageState extends State<MyGlassesPage> {
  bool _isImageRevealed = false;

  Future<void> _openScanner() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Okiolvassuk a globális Bluetooth állapotot a Providerből
    final isConnected = context.watch<BleProvider>().isConnected;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: isConnected ? _buildConnectedView() : _buildDisconnectedView(),
      ),
    );
  }

  Widget _buildDisconnectedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.bluetooth_searching_rounded, size: 80, color: Colors.teal.shade300),
            ),
            const SizedBox(height: 32),
            const Text('No Glasses Connected', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 12),
            Text(
              'Pair your AIGLS device to sync data and view your daily summaries.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 48),
            Container(
              width: double.infinity, height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]),
                boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _openScanner,
                  child: const Center(child: Text('BIND DEVICE', style: TextStyle(fontSize: 18, letterSpacing: 1.5, color: Colors.white, fontWeight: FontWeight.bold))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.remove_red_eye_rounded, size: 36, color: Colors.teal.shade700),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.battery_charging_full_rounded, size: 24, color: Colors.teal.shade600),
                    const SizedBox(width: 8),
                    const Text('41%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                  ],
                ),
              )
            ],
          ),
          
          const SizedBox(height: 32),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text("Yesterday's Summary", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87)),
          ),
          const SizedBox(height: 24),
          
          // 1. KÁRTYA: MEGNÖVELT RADAR DIAGRAM FELIRATOK NÉLKÜL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: SizedBox(
              height: 240, // Kicsit még magasabb lett, hogy kitöltse a teret
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      dataEntries: const [
                        RadarEntry(value: 4), // Focus
                        RadarEntry(value: 2), // Consumption
                        RadarEntry(value: 5), // Activity
                        RadarEntry(value: 3), // Social
                        RadarEntry(value: 4), // Explore
                      ],
                      fillColor: Colors.teal.shade400.withValues(alpha: 0.25),
                      borderColor: Colors.teal.shade600,
                      entryRadius: 4, 
                      borderWidth: 2,
                    ),
                  ],
                  getTitle: (index, angle) {
                    // JAVÍTVA: Consumption teljesen kiírva
                    final titles = ['Focus', 'Consumption', 'Activity', 'Social', 'Explore'];
                    return RadarChartTitle(
                      text: titles[index],
                      angle: angle,
                    );
                  },
                  tickCount: 5,
                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                  gridBorderData: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  radarBorderData: const BorderSide(color: Colors.transparent),
                  titlePositionPercentageOffset: 0.18,
                ),
                duration: const Duration(milliseconds: 300),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          GestureDetector(
            onTap: () {
              setState(() { _isImageRevealed = !_isImageRevealed; });
            },
            child: Container(
              height: 220, width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.teal.shade300, Colors.blueGrey.shade800]),
                      ),
                      child: const Center(child: Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white24)),
                    ),
                    if (!_isImageRevealed)
                      BackdropFilter(filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0), child: Container(color: Colors.black.withValues(alpha: 0.2))),
                    if (!_isImageRevealed)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(30)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Tap to reveal moment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: Colors.amber.shade600),
                    const SizedBox(width: 8),
                    const Text('AI Insight', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "You maintained an excellent flow state during the morning. "
                  "Reducing your screen time directly contributed to higher activity levels. Keep up the momentum!",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }
  }