import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ble_image_service.dart';

class BleProvider with ChangeNotifier {
  final BleImageService bleService = BleImageService();
  
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  BleProvider() {
    _initAutoReconnect();
  }

  // Automatikus visszacsatlakozás az app indulásakor
  Future<void> _initAutoReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMac = prefs.getString('saved_ble_mac');
    
    if (savedMac != null && savedMac.isNotEmpty) {
      try {
        print("Próbálkozás automatikus visszacsatlakozással: $savedMac");
        // MAC cím alapján létrehozzuk az eszközt és csatlakozunk
        final device = BluetoothDevice.fromId(savedMac);
        await connect(device);
      } catch (e) {
        print("Auto-reconnect failed: $e");
      }
    }
  }

  // Csatlakozás és az állapot elmentése
  Future<bool> connect(BluetoothDevice device) async {
    bool success = await bleService.connectToDevice(device);
    if (success) {
      _isConnected = true;
      _connectedDevice = device;
      
      // Elmentjük a MAC címet a jövőbeli újraindításokhoz
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_ble_mac', device.remoteId.str);

      // Figyeljük, ha az eszköz esetleg megszakad (pl. kikapcsolják a szemüveget)
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _isConnected = false;
          _connectedDevice = null;
          notifyListeners();
        }
      });
      
      notifyListeners();
      return true;
    }
    return false;
  }

  // Manuális leválasztás (Forget device gombhoz)
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _isConnected = false;
      _connectedDevice = null;
      
      // Kitöröljük a memóriából
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_ble_mac');
      
      notifyListeners();
    }
  }
}