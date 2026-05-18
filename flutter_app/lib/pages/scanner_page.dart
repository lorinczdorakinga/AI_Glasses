import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_image_service.dart';

class ScannerPage extends StatefulWidget {
  final BleImageService bleService;

  const ScannerPage({super.key, required this.bleService});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    // Pulzáló animáció beállítása
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Keresés indítása
    widget.bleService.startScan();
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.bleService.stopScan();
    super.dispose();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    widget.bleService.stopScan();
    setState(() {
      _isConnecting = true;
    });

    bool success = await widget.bleService.connectToDevice(device);
    
    if (mounted) {
      Navigator.pop(context, success); 
    }
  }

  // ÚJ: Felugró ablak hibás eszköz kiválasztásakor
  void _showInvalidDevicePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.pinkAccent,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Wrong Device',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sorry, we are looking for an AIGLS device, not something else.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Ablak bezárása
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Got it', style: TextStyle(fontSize: 18)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Bluetooth devices available',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
      body: _isConnecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.pinkAccent),
                  SizedBox(height: 20),
                  Text('Pairing with glasses...', style: TextStyle(fontSize: 18)),
                ],
              ),
            )
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Text(
                    'Make sure your glasses are turned on.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                // Pulzáló "radar" animáció
                ScaleTransition(
                  scale: Tween(begin: 0.9, end: 1.1).animate(
                    CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.pinkAccent.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.radar, color: Colors.pinkAccent, size: 30),
                  ),
                ),
                const SizedBox(height: 20),
                // Eszközök listája
                Expanded(
                  child: StreamBuilder<List<ScanResult>>(
                    stream: widget.bleService.scanResults,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Scanning for devices...'));
                      }

                      // 1. ÚJ LOGIKA: Kiszűrjük az üres nevű (Unknown) eszközöket
                      final validDevices = snapshot.data!.where((result) {
                        return result.device.platformName.trim().isNotEmpty;
                      }).toList();

                      // Ha szűrés után nem maradt semmi (csak unknown eszközök vannak a közelben)
                      if (validDevices.isEmpty) {
                        return const Center(child: Text('Scanning for devices...'));
                      }

                      // 2. A már megtisztított listát (validDevices) építjük fel
                      return ListView.builder(
                        itemCount: validDevices.length,
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, index) {
                          final data = validDevices[index];
                          final deviceName = data.device.platformName; // Itt már biztosan van neve

                          // Ellenőrizzük, hogy ez a mi szemüvegünk-e
                          final isTargetDevice = deviceName.startsWith(widget.bleService.targetDevicePrefix);

                          return GestureDetector(
                            onTap: () {
                              // Csak az AIGLS-t engedjük!
                              if (isTargetDevice) {
                                _connectToDevice(data.device);
                              } else {
                                _showInvalidDevicePopup();
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isTargetDevice ? Colors.pinkAccent : Colors.grey.shade300,
                                  width: isTargetDevice ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      deviceName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: isTargetDevice ? FontWeight.bold : FontWeight.normal,
                                        color: isTargetDevice ? Colors.black : Colors.black54,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isTargetDevice)
                                    const Icon(Icons.link, color: Colors.pinkAccent)
                                  else
                                    const Icon(Icons.bluetooth, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}