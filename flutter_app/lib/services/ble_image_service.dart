import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;

class BleImageService {
  final String targetDevicePrefix = ""; // AIGLS-sel kezdődő eszközök keresése 
  final Guid serviceUuid = Guid("e86fa43c-5ae8-4663-abb2-889f09cfb822");
  final Guid statusUuid = Guid("13a56951-37c2-4517-98a6-353e7c5b299b");
  final Guid dataUuid = Guid("8fcc7c0e-a4c0-4f56-abcd-fb61e137aa7a");

  int _expectedChunks = 0;
  final Map<int, List<int>> _receivedChunks = {};
  int _imageCounter = 1;
  BluetoothDevice? _device;

  // 1. Keresés indítása (10 másodpercig)
  Future<void> startScan() async {
    // Ha esetleg már futna egy keresés, azt leállítjuk az új előtt
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
  }

  // 2. Keresés leállítása
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // 3. A talált eszközök streamje, amit a UI figyelni tud
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // 4. Csatlakozás a KIVÁLASZTOTT eszközhöz
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(license: License.free);
      _device = device;
      await _discoverAndSubscribe();
      return true; // Sikeres csatlakozás
    } catch (e) {
      print("Csatlakozási hiba: $e");
      return false; // Sikertelen csatlakozás
    }
  }

  Future<void> _discoverAndSubscribe() async {
    if (_device == null) return;
    List<BluetoothService> services = await _device!.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid == serviceUuid) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.uuid == statusUuid) {
            await c.setNotifyValue(true);
            c.onValueReceived.listen(_handleStatus);
          }
          if (c.uuid == dataUuid) {
            await c.setNotifyValue(true);
            c.onValueReceived.listen(_handleData);
          }
        }
      }
    }
  }

  void _handleStatus(List<int> data) {
    if (data.isEmpty) return;
    String msgType = String.fromCharCode(data[0]);
    if (msgType == 'S') {
      _receivedChunks.clear();
      var byteData = ByteData.sublistView(Uint8List.fromList(data));
      _expectedChunks = byteData.getUint16(9, Endian.big);
    } else if (msgType == 'E') {
      _reconstructAndUploadImage();
    }
  }

  void _handleData(List<int> data) {
    if (data.length < 2) return;
    int chunkId = (data[0] << 8) | data[1];
    _receivedChunks[chunkId] = data.sublist(2);
  }

  Future<void> _reconstructAndUploadImage() async {
    BytesBuilder builder = BytesBuilder();
    for (int i = 0; i < _expectedChunks; i++) {
      if (!_receivedChunks.containsKey(i)) return;
      builder.add(_receivedChunks[i]!);
    }
    Uint8List imageBytes = builder.toBytes();
    String filename = "image_${_imageCounter.toString().padLeft(4, '0')}.jpg";
    _imageCounter++;

    try {
      var uri = Uri.parse('http://187.124.25.127:3000/api/images/upload');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: filename));
      await request.send();
      print(  "Image uploaded: $filename");
    } catch (e) {
      print("Hálózati hiba feltöltéskor: $e");
    }
  }
}