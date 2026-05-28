import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// Import your DataProvider so we can trigger a refresh after each upload.
// Adjust the path to match your actual project structure.
import '../providers/data_provider.dart';

class BleImageService {
  final String targetDevicePrefix = "AIGLS";

  final Guid imgServiceUuid = Guid("e86fa43c-5ae8-4663-abb2-889f09cfb822");
  final Guid imgControlUuid = Guid("8a80c26e-404c-4436-8877-bc643a7194c9");
  final Guid imgStatusUuid  = Guid("13a56951-37c2-4517-98a6-353e7c5b299b");
  final Guid imgDataUuid    = Guid("8fcc7c0e-a4c0-4f56-abcd-fb61e137aa7a");

  final Guid cmdServiceUuid = Guid("6d22fa7b-4f6c-4bd7-962c-a343c00060a1");
  final Guid cmdBatUuid     = Guid("726530db-8845-4241-a10e-e26f20b095d6");

  BluetoothDevice? _device;
  BluetoothCharacteristic? _imgControl;
  BluetoothCharacteristic? _imgStatus;
  BluetoothCharacteristic? _imgData;

  // ── NEW: injected reference to DataProvider ──────────────────────────────
  // Set this once in BleProvider after creating the service:
  //   bleService.dataProvider = context.read<DataProvider>();
  DataProvider? dataProvider;

  int _nextIndexToRequest = 0;
  int _expectedChunks = 0;
  int _expectedBytes = 0;
  Uint8List? _imageBuffer;
  int _chunksReceived = 0;

  // ── Battery ───────────────────────────────────────────────────────────────
  // The camera sends battery as a single uint8 notify on CMD_BAT_UUID.
  // We read it here and push it into DataProvider so MyGlassesPage can show it.
  void _handleBattery(List<int> data) {
    if (data.isEmpty) return;
    final percent = data[0].clamp(0, 100);
    if (dataProvider != null) {
      dataProvider!.batteryPercent = percent;
      dataProvider!.notifyListeners();
    }
  }

  // ── Scan ──────────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
  }

  Future<void> stopScan() async => FlutterBluePlus.stopScan();

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // ── Connect ───────────────────────────────────────────────────────────────

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false, mtu: null, license: License.free);
      _device = device;

      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print("MTU negotiation error (non-blocking): $e");
        }
      }

      final currentMtu = await device.mtu.first;
      print("Connected. MTU: $currentMtu");

      final prefs = await SharedPreferences.getInstance();
      _nextIndexToRequest = prefs.getInt('aigls_next_index') ?? 0;

      await _discoverAndSubscribe();
      return true;
    } catch (e) {
      print("Connection error: $e");
      return false;
    }
  }

  Future<void> _discoverAndSubscribe() async {
    if (_device == null) return;
    final services = await _device!.discoverServices();

    for (final service in services) {
      if (service.uuid == imgServiceUuid) {
        for (final c in service.characteristics) {
          if (c.uuid == imgControlUuid) _imgControl = c;
          if (c.uuid == imgStatusUuid)  _imgStatus  = c;
          if (c.uuid == imgDataUuid)    _imgData    = c;
        }
      }
      // Subscribe to battery notifications from CMD service
      if (service.uuid == cmdServiceUuid) {
        for (final c in service.characteristics) {
          if (c.uuid == cmdBatUuid) {
            await c.setNotifyValue(true);
            c.onValueReceived.listen(_handleBattery);
          }
        }
      }
    }

    if (_imgStatus != null) {
      await _imgStatus!.setNotifyValue(true);
      _imgStatus!.onValueReceived.listen(_handleStatus);
    }
    if (_imgData != null) {
      await _imgData!.setNotifyValue(true);
      _imgData!.onValueReceived.listen(_handleData);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    await _requestImage(_nextIndexToRequest);
  }

  // ── BLE protocol ──────────────────────────────────────────────────────────

  Future<void> _requestImage(int index) async {
    if (_imgControl == null) return;
    final cmd = Uint8List(5);
    cmd[0] = 0x52; // 'R'
    ByteData.view(cmd.buffer).setUint32(1, index, Endian.big);
    await _imgControl!.write(cmd, withoutResponse: false);
    print("Requested image $index");
  }

  void _handleStatus(List<int> value) {
    if (value.isEmpty) return;

    switch (value[0]) {
      case 0x53: // 'S' — start
        final bd = ByteData.view(Uint8List.fromList(value).buffer);
        _expectedBytes  = bd.getUint32(5, Endian.big);
        _expectedChunks = bd.getUint16(9, Endian.big);
        _imageBuffer    = Uint8List(_expectedBytes);
        _chunksReceived = 0;
        print("Incoming image: $_expectedBytes bytes, $_expectedChunks chunks");

      case 0x45: // 'E' — end
        print("Image transfer complete");
        _reconstructAndUpload();

      case 0x4E: // 'N' — not available (caught up)
        final bd = ByteData.view(Uint8List.fromList(value).buffer);
        final last = bd.getUint32(5, Endian.big);
        print("No new image. Latest on device: $last");

      case 0x58: // 'X' — error
        final code = value[5];
        print("ESP error code: $code");
        if (code != 5) {
          // Error code 5 is just a timeout nudge — don't skip the index.
          _nextIndexToRequest++;
          _requestImage(_nextIndexToRequest);
        }
    }
  }

  void _handleData(List<int> value) {
    if (value.length < 3 || _imageBuffer == null) return;
    final bd = ByteData.view(Uint8List.fromList(value).buffer);
    final chunkIndex = bd.getUint16(0, Endian.big);
    final payload    = value.sublist(2);
    final offset     = chunkIndex * 396; // BUFFERSIZE from config.h
    if (offset + payload.length <= _imageBuffer!.length) {
      _imageBuffer!.setRange(offset, offset + payload.length, payload);
      _chunksReceived++;
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  Future<void> _reconstructAndUpload() async {
    if (_imageBuffer == null) return;

    if (_chunksReceived != _expectedChunks) {
      print("Missing chunks ($_chunksReceived / $_expectedChunks). Retrying...");
      await Future.delayed(const Duration(milliseconds: 200));
      await _requestImage(_nextIndexToRequest);
      return;
    }

    final prefs    = await SharedPreferences.getInstance();
    final token    = prefs.getString('auth_token') ?? '';
    final filename = "image_${_nextIndexToRequest.toString().padLeft(4, '0')}.jpg";

    try {
      final uri     = Uri.parse('http://187.124.25.127:3000/api/images/upload');
      final request = http.MultipartRequest('POST', uri);

      // Pass auth token and the current image index so the server can
      // associate the upload with the right session/user.
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['imageIndex']     = _nextIndexToRequest.toString();
      request.files.add(
        http.MultipartFile.fromBytes('image', _imageBuffer!, filename: filename),
      );

      final response = await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print("Uploaded $filename successfully");

        // Advance index and persist
        _nextIndexToRequest++;
        await prefs.setInt('aigls_next_index', _nextIndexToRequest);

        // ── KEY CHANGE: tell DataProvider the server has new data ──────────
        // This triggers an immediate re-fetch of activities/summary/quest
        // so the UI updates right after this image is processed, rather than
        // waiting for the next 65-second poll tick.
        await dataProvider?.onImageUploaded();

        // Request the next image from the camera
        await _requestImage(_nextIndexToRequest);
      } else {
        print("Upload failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Upload error: $e");
    }
  }
}