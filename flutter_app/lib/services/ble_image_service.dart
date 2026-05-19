import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BleImageService {
  final String targetDevicePrefix = "AIGLS";

  // UUID-k pontosan a config.h alapján
  final Guid imgServiceUuid = Guid("e86fa43c-5ae8-4663-abb2-889f09cfb822");
  final Guid imgControlUuid = Guid("8a80c26e-404c-4436-8877-bc643a7194c9");
  final Guid imgStatusUuid  = Guid("13a56951-37c2-4517-98a6-353e7c5b299b");
  final Guid imgDataUuid    = Guid("8fcc7c0e-a4c0-4f56-abcd-fb61e137aa7a");

  BluetoothDevice? _device;
  BluetoothCharacteristic? _imgControl;
  BluetoothCharacteristic? _imgStatus;
  BluetoothCharacteristic? _imgData;

  // Állapotváltozók a képösszerakáshoz
  int _nextIndexToRequest = 0;
  int _expectedChunks = 0;
  int _expectedBytes = 0;
  Uint8List? _imageBuffer;
  int _chunksReceived = 0;

  // 1. Keresés indítása
  Future<void> startScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
  }

  // 2. Keresés leállítása
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // 3. Csatlakozás és a csatornák felfedezése
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(license: License.free, autoConnect: true);
      _device = device;
      
      // Megpróbáljuk betölteni, hogy hol tartottunk legutóbb a képekkel
      final prefs = await SharedPreferences.getInstance();
      _nextIndexToRequest = prefs.getInt('aigls_next_index') ?? 0;

      await _discoverAndSubscribe();
      return true;
    } catch (e) {
      print("Csatlakozási hiba: $e");
      return false;
    }
  }

  Future<void> _discoverAndSubscribe() async {
    if (_device == null) return;
    List<BluetoothService> services = await _device!.discoverServices();

    for (BluetoothService service in services) {
      if (service.uuid == imgServiceUuid) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.uuid == imgControlUuid) _imgControl = c;
          if (c.uuid == imgStatusUuid) _imgStatus = c;
          if (c.uuid == imgDataUuid) _imgData = c;
        }
      }
    }

    // Feliratkozás a státuszra és az adatra
    if (_imgStatus != null) {
      await _imgStatus!.setNotifyValue(true);
      _imgStatus!.onValueReceived.listen(_handleStatus);
    }
    if (_imgData != null) {
      await _imgData!.setNotifyValue(true);
      _imgData!.onValueReceived.listen(_handleData);
    }

    // Várunk egy picit, majd kikérjük az első képet!
    await Future.delayed(const Duration(milliseconds: 500));
    await _requestImage(_nextIndexToRequest);
  }

  // 4. Kép kikérése az ESP-től (Az 'R' parancs)
  Future<void> _requestImage(int index) async {
    if (_imgControl == null) return;
    print("Kikérés: $index. számú kép...");
    
    final cmd = Uint8List(5);
    cmd[0] = 0x52; // 'R' betű ASCII kódja
    ByteData.view(cmd.buffer).setUint32(1, index, Endian.big);
    
    await _imgControl!.write(cmd, withoutResponse: false);
  }

  // 5. Státusz üzenetek feldolgozása az ESP-től
  void _handleStatus(List<int> value) {
    if (value.isEmpty) return;
    int msgType = value[0];

    if (msgType == 0x53) { // 'S' - Start
      final bd = ByteData.view(Uint8List.fromList(value).buffer);
      _expectedBytes = bd.getUint32(5, Endian.big);
      _expectedChunks = bd.getUint16(9, Endian.big);
      
      _imageBuffer = Uint8List(_expectedBytes); // Lefoglaljuk a RAM-ot
      _chunksReceived = 0;
      print("Kép jön! Méret: $_expectedBytes byte, Darabok: $_expectedChunks");

    } else if (msgType == 0x45) { // 'E' - End
      print("Kép sikeresen megérkezett az appba!");
      _reconstructAndUploadImage();

    } else if (msgType == 0x4E) { // 'N' - Not available (Nincs több kép)
      final bd = ByteData.view(Uint8List.fromList(value).buffer);
      final lastAvailable = bd.getUint32(5, Endian.big);
      print("Nincs új kép. A legutolsó létező index a kamerán: $lastAvailable");

    } else if (msgType == 0x58) { // 'X' - Error
      print("Hiba az ESP oldalon! Kód: ${value[5]}");
      if (value[5] != 5) {
        // Ha nem timeout hiba, ugorjunk a következő képre
        _nextIndexToRequest++;
        _requestImage(_nextIndexToRequest);
      }
    }
  }

  // 6. Nyers bájtok összerakása a megfelelő helyre
  void _handleData(List<int> value) {
    if (value.length < 3 || _imageBuffer == null) return;
    
    final bd = ByteData.view(Uint8List.fromList(value).buffer);
    final chunkIndex = bd.getUint16(0, Endian.big);
    final payload = value.sublist(2);
    
    final offset = chunkIndex * 396; // A config.h BUFFERSIZE alapján
    
    if (offset + payload.length <= _imageBuffer!.length) {
      _imageBuffer!.setRange(offset, offset + payload.length, payload);
      _chunksReceived++;
    }
  }

  // 7. Backend feltöltés és következő kép kérése
  Future<void> _reconstructAndUploadImage() async {
    if (_imageBuffer == null) return;

    if (_chunksReceived != _expectedChunks) {
      print("Hiányzó darabok! Újrakérés...");
      await Future.delayed(const Duration(milliseconds: 200));
      await _requestImage(_nextIndexToRequest);
      return;
    }

    String filename = "image_${_nextIndexToRequest.toString().padLeft(4, '0')}.jpg";
    
    try {
      // 187.124.25.127 a te géped IP címe, ezen fut a Node.js szervered
      var uri = Uri.parse('http://187.124.25.127:3000/api/images/upload');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(http.MultipartFile.fromBytes('image', _imageBuffer!, filename: filename));
      var response = await request.send();

      if (response.statusCode == 200) {
        print("Sikeresen elküldve a backendnek: $filename");
        
        // Ha sikeres, léptetjük az indexet és elmentjük a memóriába
        _nextIndexToRequest++;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('aigls_next_index', _nextIndexToRequest);
        
        // Rögtön kikérjük a következőt!
        await _requestImage(_nextIndexToRequest);
      } else {
        print("Backend hiba: ${response.statusCode}");
      }
    } catch (e) {
      print("Hálózati hiba a backend feltöltéskor: $e");
    }
  }
}