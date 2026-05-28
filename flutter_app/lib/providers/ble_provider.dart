import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ble_image_service.dart';
import 'data_provider.dart';

class BleProvider with ChangeNotifier {
  final BleImageService bleService = BleImageService();

  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // ── NEW: accept DataProvider so we can inject it into BleImageService ─────
  // Call this once from main.dart after both providers are created:
  //   bleProvider.init(dataProvider);
  void init(DataProvider dataProvider) {
    bleService.dataProvider = dataProvider;
  }

  BleProvider() {
    _initAutoReconnect();
  }

  Future<void> _initAutoReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMac = prefs.getString('saved_ble_mac');
    if (savedMac != null && savedMac.isNotEmpty) {
      try {
        print("Auto-reconnect attempt: $savedMac");
        final device = BluetoothDevice.fromId(savedMac);
        await connect(device);
      } catch (e) {
        print("Auto-reconnect failed: $e");
      }
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    bool success = await bleService.connectToDevice(device);
    if (success) {
      _isConnected = true;
      _connectedDevice = device;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_ble_mac', device.remoteId.str);

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

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _isConnected = false;
      _connectedDevice = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_ble_mac');
      notifyListeners();
    }
  }
}