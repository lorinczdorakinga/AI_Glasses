import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart'; // ÚJ IMPORT
import '../../providers/ble_provider.dart'; // ÚJ IMPORT

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Provideren keresztül indítjuk a keresést
    context.read<BleProvider>().bleService.startScan();
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Ezt el kell kapni egy mentett kontextussal vagy egyszerűen kihagyjuk, mert a FlutterBlue megállítja magát.
    FlutterBluePlus.stopScan(); 
    super.dispose();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    FlutterBluePlus.stopScan();
    setState(() {
      _isConnecting = true;
    });

    // 2. A Provider hívja meg a csatlakozást, és ő jegyzi meg az állapotot!
    bool success = await context.read<BleProvider>().connect(device);
    
    if (mounted) {
      Navigator.pop(context, success); 
    }
  }

  // PRÉMIUM: Lekerekített, modern hiba ablak
  void _showInvalidDevicePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bluetooth_disabled_rounded, color: Colors.red.shade400, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Wrong Device',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sorry, we are looking for an AIGLS device, not something else. Please select the correct glasses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade900, // Elegáns sötétszürke/fekete gomb
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Got it', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFFF7F8FA), // Prémium világosszürke háttér
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Láthatatlan AppBar, hogy egybeolvadjon a háttérrel
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Pair Device',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isConnecting
          ? _buildConnectingView()
          : _buildScanningView(),
    );
  }

  // --- ELEGÁNS TÖLTŐKÉPERNYŐ ---
  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 5)],
            ),
            child: CircularProgressIndicator(color: Colors.teal.shade600, strokeWidth: 4),
          ),
          const SizedBox(height: 32),
          const Text('Establishing connection...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Configuring MTU and preparing channels', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // --- SZKENNER NÉZET ---
  Widget _buildScanningView() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          'Looking for your glasses...',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 30),
        
        // PRÉMIUM: Hullámzó (Ripple) radar animáció
        SizedBox(
          width: 120,
          height: 120,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Táguló és elhalványuló kör
                  Container(
                    width: 120 * _animationController.value,
                    height: 120 * _animationController.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal.shade400.withValues(alpha: 1.0 - _animationController.value),
                    ),
                  ),
                  // Fix belső kör az ikonnal
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal.shade50,
                      border: Border.all(color: Colors.teal.shade200, width: 2),
                    ),
                    child: Icon(Icons.bluetooth_searching_rounded, color: Colors.teal.shade700, size: 28),
                  ),
                ],
              );
            },
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Eszközök listája
        Expanded(
          child: StreamBuilder<List<ScanResult>>(
            stream: context.read<BleProvider>().bleService.scanResults,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              // Kiszűrjük az üres nevű (Unknown) eszközöket
              final validDevices = snapshot.data!.where((result) {
                return result.device.platformName.trim().isNotEmpty;
              }).toList();

              if (validDevices.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: validDevices.length,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = validDevices[index];
                  final deviceName = data.device.platformName; 

                  // TESZT MÓD: Ha mindent engedni akarsz, írd át ezt `true`-ra!
                  final isTargetDevice = deviceName.startsWith(context.read<BleProvider>().bleService.targetDevicePrefix);
                  // final isTargetDevice = true; 

                  return _buildDeviceCard(deviceName, data.device, isTargetDevice);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Segédfüggvény: Üres állapot (amikor még nem talált semmit)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.device_unknown_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Scanning nearby devices...', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  // Segédfüggvény: A modern eszköz kártya felépítése
  Widget _buildDeviceCard(String deviceName, BluetoothDevice device, bool isTargetDevice) {
    return GestureDetector(
      onTap: () {
        if (isTargetDevice) {
          _connectToDevice(device);
        } else {
          _showInvalidDevicePopup();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isTargetDevice ? Colors.teal.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTargetDevice ? Colors.teal.shade300 : Colors.grey.shade200,
            width: isTargetDevice ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // JAVÍTVA: Első Expanded biztosítja, hogy a bal oldal ne tolja ki a jobb oldali gombot
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isTargetDevice ? Colors.teal.shade100 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTargetDevice ? Icons.lens_blur : Icons.bluetooth,
                      color: isTargetDevice ? Colors.teal.shade700 : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // JAVÍTVA: Második Expanded + maxLines kényszeríti ki a szövegcsonkítást (...)
                  Expanded(
                    child: Text(
                      deviceName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isTargetDevice ? FontWeight.w800 : FontWeight.w600,
                        color: isTargetDevice ? Colors.teal.shade900 : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12), // Biztonsági rés a szöveg és a gomb között
            if (isTargetDevice)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('CONNECT', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            else
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16),
          ],
        ),
      ),
    );
  }
  }