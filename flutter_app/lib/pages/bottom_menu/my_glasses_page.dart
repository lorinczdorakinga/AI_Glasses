import 'package:flutter/material.dart';
import '../../services/ble_image_service.dart';
import '../scanner_page.dart'; // Importáljuk az új oldalt

class MyGlassesPage extends StatefulWidget {
  const MyGlassesPage({super.key});

  @override
  State<MyGlassesPage> createState() => _MyGlassesPageState();
}

class _MyGlassesPageState extends State<MyGlassesPage> {
  final BleImageService _bleService = BleImageService();
  bool _isConnected = false;

  // Navigáció a szkenner oldalra
  Future<void> _openScanner() async {
    final bool? connectionResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerPage(bleService: _bleService),
      ),
    );

    // Ha a scanner oldal "true" értékkel tért vissza, összekapcsolódtunk
    if (connectionResult == true && mounted) {
      setState(() {
        _isConnected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isConnected ? _buildConnectedView() : _buildDisconnectedView(),
    );
  }

  // VÁZLAT BAL FELSŐ RÉSZE
  Widget _buildDisconnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'You have no glasses connected to your phone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 60),
          OutlinedButton(
            onPressed: _openScanner,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.pinkAccent, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Bind device',
              style: TextStyle(fontSize: 22, color: Colors.black),
            ),
          ),
          const SizedBox(height: 80),
          // Diszkrét modern ikon az ódivatú Bluetooth helyett
          const Icon(Icons.lens_blur, size: 60, color: Colors.black54), 
        ],
      ),
    );
  }

  // VÁZLAT BAL ALSÓ RÉSZE (Mockup)
  Widget _buildConnectedView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Felső sor akkumulátorral
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.remove_red_eye_outlined, size: 32),
              Row(
                children: [
                  const Icon(Icons.battery_4_bar, size: 28),
                  const SizedBox(width: 8),
                  const Text('41%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            "Yesterday's summary",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          
          // Helykitöltő a kördiagrammnak és a statisztikáknak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                child: const Center(child: Icon(Icons.pie_chart_outline, size: 60, color: Colors.grey)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _mockStatLine(),
                  const SizedBox(height: 10),
                  _mockStatLine(),
                  const SizedBox(height: 10),
                  _mockStatLine(),
                ],
              )
            ],
          ),
          const SizedBox(height: 40),
          
          // Kép helykitöltője
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Ez a kép homályos, ha rákattint a user, csak akkor jelenik meg.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _mockStatLine(width: double.infinity),
          const SizedBox(height: 10),
          _mockStatLine(width: 200),
        ],
      ),
    );
  }

  // Segédfüggvény a rajzolt "hullámos vonalak" imitálására
  Widget _mockStatLine({double width = 100}) {
    return Container(
      height: 10,
      width: width,
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(5)),
    );
  }
}