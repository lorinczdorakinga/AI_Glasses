## note: written by ClaudeAI and checked over by adam, seems correct and i fixed what i noticed to be wrong.

# AIGLS ESP32-S3 Camera — Dart/Flutter BLE Integration Guide

> This guide is written for a Flutter developer building an Android/iOS background app that connects to the **AIGLS** ESP32-S3 camera device, receives JPEG images over BLE, saves them locally, and manages the device's SD card index via a periodic reset command.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [BLE Architecture](#2-ble-architecture)
3. [Security & Pairing Model](#3-security--pairing-model)
4. [Binary Protocol Reference](#4-binary-protocol-reference)
5. [Device State Machine](#5-device-state-machine)
6. [Full Image Transfer Flow](#6-full-image-transfer-flow)
7. [Dart Implementation Guide](#7-dart-implementation-guide)
8. [Background Execution](#8-background-execution)
9. [SD Reset Schedule](#9-sd-reset-schedule)
10. [Error Handling Reference](#10-error-handling-reference)
11. [Platform-Specific Notes](#11-platform-specific-notes)
12. [Recommended Package Stack](#12-recommended-package-stack)

---

## 1. System Overview

The ESP32-S3 device ("AIGLS") wakes every **60 seconds** via deep sleep timer, captures a JPEG image at XGA resolution (1024×768), then enters one of two paths:

- **BLE client connected & authenticated** → transmits the image immediately over BLE, then sleeps.
- **No client within 20 seconds** → saves the image to SD card as `/%04d.jpg` (e.g. `/0042.jpg`), then sleeps.

The image index is a **circular counter from 0 to 9999**, stored in RTC memory (survives deep sleep, cleared on power loss or reset). The app must track which index it last successfully received and request the next one each cycle.

```
┌──────────────────────────────────────────────────────────────┐
│  ESP32-S3 wake cycle (~60 s period)                          │
│                                                              │
│  [TAKE_PICTURE] → [WAIT_FOR_CONNECTION] → [SEND] → [SLEEP]  │
│                           │                                  │
│                    (no BLE in 20 s)                         │
│                           ↓                                  │
│                    [SAVE_TO_SD] → [SLEEP]                    │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. BLE Architecture

The device exposes **two GATT services**:

### Image Service — `e86fa43c-5ae8-4663-abb2-889f09cfb822`

| Characteristic | UUID | Properties | Purpose |
|---|---|---|---|
| `ImgControl` | `8a80c26e-404c-4436-8877-bc643a7194c9` | **WRITE** | Client sends image request commands |
| `ImgStatus` | `13a56951-37c2-4517-98a6-353e7c5b299b` | **NOTIFY** | Device sends transfer status/metadata |
| `ImgData` | `13a56951-37c2-4517-98a6-353e7c5b299b` | **NOTIFY** | Device sends raw image chunks |

### Command Service — `6d22fa7b-4f6c-4bd7-962c-a343c00060a1`

| Characteristic | UUID | Properties | Purpose |
|---|---|---|---|
| `CmdChar` | `06e025b3-…` | **WRITE** | Client sends control commands (sleep, reset) |
| `BatChar` | `726530db-…` | **READ + NOTIFY** | Device sends battery percentage |

### MTU

The device requests an MTU of **512 bytes**. Each data chunk carries **396 bytes** of image data plus a 2-byte chunk header, totalling **398 bytes per notification**. Negotiate MTU ≥ 512 as early as possible after connection.

---

## 3. Security & Pairing Model

The device uses **BLE Secure Connections** with `DISPLAY_ONLY` I/O capability and a **static passkey of `123456`**.

- Security flags set: `bonding=true`, `MITM=true`, `SC=true`
- Authentication is required before the device allows any data to flow (`client_connected` flag)
- Pairing is handled by the **OS**, not the app — the user pairs from the system Bluetooth settings (note: atleast in windows - adam)
- Once bonded, subsequent reconnections are automatic and silent (the OS handles re-encryption)
- If authentication fails, the device kicks the client

**Your app must (probably - adam) NOT attempt pairing itself.** Simply connect to the already-bonded device. If the device is not yet paired, guide the user to OS Bluetooth settings. After bonding, your app connects normally and `onAuthenticationComplete` fires on the ESP32 side within a second or two of connection.

> **Important:** On Android, after pairing, you may still need to call `requestMtu(512)` explicitly before subscribing to notifications. On iOS, MTU negotiation happens automatically.

---

## 4. Binary Protocol Reference

All multi-byte integers are **big-endian**.

### 4.1 ImgControl (Client → Device, WRITE)

#### Request Image
Triggers the device to send a specific image index.

```
Byte 0:   'R' (0x52)
Byte 1-4: uint32 — requested image index (big-endian)

Total: 5 bytes
```

**Example — request image index 42:**
```dart
final cmd = Uint8List(5);
cmd[0] = 0x52; // 'R'
final bd = ByteData.view(cmd.buffer);
bd.setUint32(1, 42, Endian.big);
await imgControlChar.write(cmd, withoutResponse: false);
```

### 4.2 ImgStatus (Device → Client, NOTIFY)

Three distinct message types are identified by **byte 0**:

#### `'S'` — Transfer Start (12 bytes)
Sent before chunk delivery begins.

```
Byte 0:    'S' (0x53)
Byte 1-4:  uint32 — image index
Byte 5-8:  uint32 — total image size in bytes
Byte 9-10: uint16 — total number of chunks
Byte 11:   0x00 (reserved)

Total: 11 bytes written (12 allocated)
```

**Parse in Dart:**
```dart
void onStatusNotify(List<int> value) {
  if (value[0] == 0x53) { // 'S'
    final bd = ByteData.view(Uint8List.fromList(value).buffer);
    final index      = bd.getUint32(1, Endian.big);
    final totalBytes = bd.getUint32(5, Endian.big);
    final numChunks  = bd.getUint16(9, Endian.big);
    beginTransfer(index, totalBytes, numChunks);
  }
}
```

#### `'E'` — Transfer End (1 byte)
Sent after all chunks are delivered. Validate your assembled buffer against the expected size from the `'S'` message.

```
Byte 0: 'E' (0x45)
```

#### `'N'` — Not Available (9 bytes)
The requested index does not exist yet (it's beyond `latest_index`).

```
Byte 0:   'N' (0x4E)
Byte 1-4: uint32 — requested index (unavailable)
Byte 5-8: uint32 — latest_index (the highest index that exists)
```

When `requested_index == latest_index + 1`, the device interprets this as "client is caught up" and transitions to `GO_SLEEP`. Your app should handle `'N'` by updating its local idea of `latest_index` and waiting for the next wake cycle.

#### `'X'` — Error (6 bytes)

```
Byte 0:   'X' (0x58)
Byte 1-4: uint32 — index that caused the error
Byte 5:   uint8 — error code

Error codes:
  0 = File not found on SD
  1 = Memory allocation failure (ps_malloc failed)
  5 = Request timeout (no request received within 2 s)
```

### 4.3 ImgData (Device → Client, NOTIFY)

Each notification contains one chunk of image data.

```
Byte 0-1: uint16 — chunk sequence number (big-endian, 0-indexed)
Byte 2-N: raw JPEG bytes for this chunk (max 396 bytes)
```

**Reassembly in Dart:**
```dart
void onDataNotify(List<int> value) {
  if (value.length < 3) return;
  final bd = ByteData.view(Uint8List.fromList(value).buffer);
  final chunkIndex = bd.getUint16(0, Endian.big);
  final payload    = value.sublist(2);
  
  // Write payload into the correct offset of the accumulation buffer
  final offset = chunkIndex * 396;
  imageBuffer.setRange(offset, offset + payload.length, payload);
  receivedChunks++;
}
```

> **Do NOT rely on chunk ordering.** Although chunks are sent sequentially with a 20 ms inter-chunk delay, use the chunk index to write into the correct buffer offset so out-of-order delivery is handled correctly.

### 4.4 CmdChar (Client → Device, WRITE)

#### Sleep Command
```
Byte 0:   'S' (0x53)
Byte 1-4: uint32 — sleep duration in seconds (big-endian)

Total: 5 bytes
```

#### Reset Command
Deletes all images from the SD card, resets `latest_index` to 0, and restarts the device.

```
Byte 0: 'R' (0x52)

Total: 1 byte
```

**Example:**
```dart
await cmdChar.write([0x52], withoutResponse: false);
```

After sending `'R'`, the device will disconnect and reboot. Expect the connection to drop within ~200 ms. Your app should handle the disconnection event gracefully and reset its own local `nextIndexToRequest` to 0.

### 4.5 BatChar (Device → Client, READ + NOTIFY)

A single `uint8` (0–100) representing battery percentage. The current firmware always returns `16` (dummy value — battery management is not yet implemented).

---

## 5. Device State Machine

Understanding the firmware's state machine helps you write a correct client.

```
                    ┌─────────────────┐
         wake up    │  TAKE_PICTURE   │
         ──────────►│                 │
                    └────────┬────────┘
                             │ picture OK
                             ▼
                    ┌─────────────────┐   no BLE   ┌───────────────┐
                    │ WAIT_FOR_CONN   │  in 20  s  │  SAVE_TO_SD   │
                    │                 │────────────►│               │
                    └────────┬────────┘             └───────┬───────┘
                             │ authenticated                │
                             ▼                              ▼
                    ┌─────────────────┐            ┌───────────────┐
                    │      SEND       │            │   GO_SLEEP    │
                    │                 │───────────►│               │
                    └─────────────────┘  done/err  └───────┬───────┘
                                                           │
                                                     deep sleep
                                                    (~60 s - elapsed)
```

**Key behavioural points:**

- The device enters `SEND` state immediately after authentication. It does **not** proactively send an image; it waits for the client to write a request to `ImgControl`.
- If no request arrives within **2 seconds** of entering `SEND`, the device sends an `'X'` error with code `5` and loops back to `WAIT_FOR_CONNECTION`.
- The device sends `BatChar` notify on entry to `SEND` state (before any image request). (note: might want to change this -adam)
- Backlog images (from cycles where no client was connected) are stored on SD as `/%04d.jpg` and can be requested by index like any other image.

---

## 6. Full Image Transfer Flow

This is the complete conversation between app and device for one image.

```
APP                                      DEVICE
 │                                          │
 │── connect (already bonded via OS) ──────►│
 │                                          │  onAuthenticationComplete fires
 │◄─ BatChar NOTIFY (battery %) ───────────│
 │                                          │
 │  [subscribe to ImgStatus + ImgData]      │
 │                                          │
 │── Write ImgControl: R [index 4 bytes] ──►│
 │                                          │  Look up image (RAM or SD)
 │◄─ ImgStatus NOTIFY: S [meta 11 bytes] ──│  image found
 │                                          │
 │◄─ ImgData NOTIFY: [0x00,0x00, chunk0] ──│
 │◄─ ImgData NOTIFY: [0x00,0x01, chunk1] ──│  (20 ms between each)
 │◄─ ImgData NOTIFY: [0x00,0x02, chunk2] ──│
 │          … (N chunks total) …            │
 │◄─ ImgStatus NOTIFY: E ──────────────────│  all chunks sent
 │                                          │
 │  [assemble buffer, verify size, save]    │
 │                                          │
 │── Write ImgControl: R [index+1 4 bytes]─►│  request next
 │                                          │
 │◄─ ImgStatus NOTIFY: N [not available] ──│  caught up
 │                                          │
 │  [wait for next device wake cycle]       │  [GO_SLEEP → deep sleep]
```

**Delete-on-confirm:** When the device receives request for index `N`, it deletes the SD file for index `N-1` (if it was requesting N-1 previously). This means **you must only increment your request index after successfully saving an image locally.**

---

## 7. Dart Implementation Guide

### 7.1 Recommended Package 

Use **`flutter_blue_plus`** (`flutter_blue_plus: ^1.x`). It supports Android and iOS, handles MTU negotiation, and has a solid notification stream API.

```yaml
# pubspec.yaml
dependencies:
  flutter_blue_plus: ^1.32.0
  path_provider: ^2.1.0
  shared_preferences: ^2.2.0
```

### 7.2 Core State Model

```dart
class AiglsState {
  int nextIndexToRequest;   // persisted in SharedPreferences
  int? latestKnownIndex;    // from 'N' responses
  bool isTransferring;
  int expectedChunks;
  int expectedBytes;
  Uint8List? imageBuffer;
  int receivedChunks;
  int currentTransferIndex;
}
```

### 7.3 Connection Manager Skeleton

```dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AiglsManager {
  static const deviceName = 'AIGLS';

  // Service UUIDs
  static final imgServiceUuid    = Guid('e86fa43c-5ae8-4663-abb2-889f09cfb822');
  static final imgControlUuid    = Guid('8a80c26e-404c-4436-8877-bc643a7194c9');
  static final imgStatusUuid     = Guid('13a56951-37c2-4517-98a6-353e7c5b299b');
  static final imgDataUuid       = Guid('8fcc7c0e-a4c0-4f56-abcd-fb61e137aa7a');
  static final cmdServiceUuid    = Guid('6d22fa7b-4f6c-4bd7-962c-a343c00060a1');
  static final cmdCharUuid       = Guid('06e025b3-597e-4c94-87df-c4bd1b4e0b0e');
  static final batCharUuid       = Guid('726530db-8845-4241-a10e-e26f20b095d6');

  BluetoothDevice? _device;
  BluetoothCharacteristic? _imgControl;
  BluetoothCharacteristic? _imgStatus;
  BluetoothCharacteristic? _imgData;
  BluetoothCharacteristic? _cmdChar;

  int _nextIndex = 0;         // load from prefs on startup
  int _expectedChunks = 0;
  int _expectedBytes  = 0;
  Uint8List? _buffer;
  int _chunksReceived = 0;
  int _currentIndex   = 0;

  StreamSubscription? _statusSub;
  StreamSubscription? _dataSub;

  // Call after scanning or from a stored device ID
  Future<void> connect(BluetoothDevice device) async {
    _device = device;
    await device.connect(autoConnect: false, timeout: const Duration(seconds: 15));
    await device.requestMtu(512);           // Android only; iOS auto-negotiates
    await _discoverAndSubscribe();
  }

  Future<void> _discoverAndSubscribe() async {
    final services = await _device!.discoverServices();

    final imgSvc = services.firstWhere((s) => s.uuid == imgServiceUuid);
    _imgControl = imgSvc.characteristics.firstWhere((c) => c.uuid == imgControlUuid);
    _imgStatus  = imgSvc.characteristics.firstWhere((c) => c.uuid == imgStatusUuid);
    _imgData    = imgSvc.characteristics.firstWhere((c) => c.uuid == imgDataUuid);

    final cmdSvc = services.firstWhere((s) => s.uuid == cmdServiceUuid);
    _cmdChar = cmdSvc.characteristics.firstWhere((c) => c.uuid == cmdCharUuid);

    // Subscribe to notifications
    await _imgStatus!.setNotifyValue(true);
    await _imgData!.setNotifyValue(true);

    _statusSub = _imgStatus!.onValueReceived.listen(_onStatus);
    _dataSub   = _imgData!.onValueReceived.listen(_onData);

    // Give the device a moment after auth before sending first request
    await Future.delayed(const Duration(milliseconds: 500));
    await _requestImage(_nextIndex);
  }

  Future<void> _requestImage(int index) async {
    final cmd = Uint8List(5);
    cmd[0] = 0x52; // 'R'
    ByteData.view(cmd.buffer).setUint32(1, index, Endian.big);
    await _imgControl!.write(cmd, withoutResponse: false);
  }

  void _onStatus(List<int> value) {
    if (value.isEmpty) return;
    switch (value[0]) {
      case 0x53: // 'S' — start
        final bd      = ByteData.view(Uint8List.fromList(value).buffer);
        _currentIndex = bd.getUint32(1, Endian.big);
        _expectedBytes= bd.getUint32(5, Endian.big);
        _expectedChunks = bd.getUint16(9, Endian.big);
        _buffer       = Uint8List(_expectedBytes);
        _chunksReceived = 0;
        break;

      case 0x45: // 'E' — end
        _onTransferComplete();
        break;

      case 0x4E: // 'N' — not available
        final bd = ByteData.view(Uint8List.fromList(value).buffer);
        final latestOnDevice = bd.getUint32(5, Endian.big);
        _onNotAvailable(latestOnDevice);
        break;

      case 0x58: // 'X' — error
        final bd   = ByteData.view(Uint8List.fromList(value).buffer);
        final idx  = bd.getUint32(1, Endian.big);
        final code = value[5];
        _onError(idx, code);
        break;
    }
  }

  void _onData(List<int> value) {
    if (value.length < 3 || _buffer == null) return;
    final bd         = ByteData.view(Uint8List.fromList(value).buffer);
    final chunkIndex = bd.getUint16(0, Endian.big);
    final payload    = value.sublist(2);
    final offset     = chunkIndex * 396;
    if (offset + payload.length <= _buffer!.length) {
      _buffer!.setRange(offset, offset + payload.length, payload);
      _chunksReceived++;
    }
  }

  Future<void> _onTransferComplete() async {
    if (_buffer == null) return;
    if (_chunksReceived != _expectedChunks) {
      // Missing chunks — retry same index
      await Future.delayed(const Duration(milliseconds: 200));
      await _requestImage(_nextIndex);
      return;
    }
    await _saveImage(_currentIndex, _buffer!);
    _nextIndex = (_currentIndex + 1) % 10000;
    await _persistNextIndex(_nextIndex);
    // Request the next image — if not available, device will reply 'N'
    await _requestImage(_nextIndex);
  }

  void _onNotAvailable(int latestOnDevice) {
    // We are caught up. Device will sleep. Disconnect cleanly.
    // Reconnection happens at the next device wake cycle (handled by autoConnect or a background scan).
    _device?.disconnect();
  }

  void _onError(int index, int code) {
    // Back off and retry after a short delay
    Future.delayed(const Duration(seconds: 1), () => _requestImage(_nextIndex));
  }

  Future<void> _saveImage(int index, Uint8List data) async {
    // Use path_provider to get app documents directory
    // Save as img_NNNN.jpg
    // Notify UI / update database
  }

  Future<void> sendReset() async {
    await _cmdChar!.write([0x52], withoutResponse: false);
    // Device will disconnect and reboot; reset local index
    _nextIndex = 0;
    await _persistNextIndex(0);
  }

  Future<void> _persistNextIndex(int index) async {
    // SharedPreferences.getInstance() then setInt('nextIndex', index)
  }

  void dispose() {
    _statusSub?.cancel();
    _dataSub?.cancel();
    _device?.disconnect();
  }
}
```

### 7.4 Scanning for the Device

Since pairing is handled by the OS, you can scan by device name and connect directly. After the first manual pairing, subsequent connections can use the device's address/ID stored in your app:

```dart
// Find paired device (already bonded)
final bonded = await FlutterBluePlus.bondedDevices; // Android only
final device = bonded.firstWhere((d) => d.platformName == 'AIGLS');
await manager.connect(device);

// Or scan (works on both platforms)
FlutterBluePlus.startScan(withNames: ['AIGLS'], timeout: const Duration(seconds: 10));
FlutterBluePlus.scanResults.listen((results) {
  for (final r in results) {
    if (r.device.platformName == 'AIGLS') {
      FlutterBluePlus.stopScan();
      manager.connect(r.device);
    }
  }
});
```

---

## 8. Background Execution

Both Android and iOS aggressively limit background BLE work. Here is the practical approach for each platform.

### 8.1 Android

Use a **Foreground Service** with a persistent notification. This keeps your process alive indefinitely while the user sees "AIGLS — listening for images" in the notification bar.

```dart
// Use flutter_foreground_task or workmanager for the service scaffold
// Key permissions in AndroidManifest.xml:
```

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<service
    android:name=".AiglsForegroundService"
    android:foregroundServiceType="connectedDevice"
    android:exported="false" />

<receiver android:name=".BootReceiver" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
</receiver>
```

The `FOREGROUND_SERVICE_CONNECTED_DEVICE` type (Android 14+) is specifically designed for BLE-connected device services and avoids battery optimisation restrictions.

**Strategy:** The foreground service runs a loop:
1. Scan for AIGLS device.
2. Connect when found (device advertises for 200 s after each wake).
3. Pull all available images.
4. Disconnect. Wait for the next advertisement (poll every ~25 s, or use `autoConnect`).

### 8.2 iOS

iOS does not allow persistent background threads. Instead:

**Use Core Bluetooth's state restoration.** When your app is killed by the OS, iOS can relaunch it in the background when a connected BLE peripheral sends a notification.

Required in `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

Required in your Flutter AppDelegate / native code:
```swift
// Restore the central manager with a restoration identifier
let centralManager = CBCentralManager(
    delegate: self,
    queue: nil,
    options: [CBCentralManagerOptionRestoreIdentifierKey: "com.yourapp.aigls"]
)
```

**Strategy on iOS:**
- Connect with `autoConnect: true` so iOS reconnects when the device is in range.
- The `ImgStatus` or `ImgData` notification arriving while backgrounded relaunches your app.
- You have ~30 seconds of background execution time per notification burst; that is enough to receive and save a single image given the ~20 ms inter-chunk delay and typical image sizes.
- For larger images or longer processing, call `beginBackgroundTask` at the start of transfer.

### 8.3 Background Execution Summary

| | Android | iOS |
|---|---|---|
| Mechanism | Foreground Service | Core Bluetooth State Restoration |
| Persistent process | ✅ Yes | ❌ No — relaunched on notify |
| BLE scan in background | ✅ Yes | ⚠️ Only for known peripherals (use `autoConnect`) |
| Time limit | None (foreground service) | ~30 s per background task |
| User-visible | Persistent notification required | None (silent) |

---

## 9. SD Reset Schedule

To prevent the SD card's circular index from wrapping and overwriting images, and to keep SD card health, send a reset every **24–48 hours**.

**Logic:**
```dart
Future<void> checkAndReset() async {
  final prefs = await SharedPreferences.getInstance();
  final lastReset = prefs.getInt('lastResetEpoch') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  
  const resetIntervalSeconds = 36 * 60 * 60; // 36 hours
  
  if (now - lastReset > resetIntervalSeconds) {
    await manager.sendReset();
    await prefs.setInt('lastResetEpoch', now);
    // Also reset local nextIndex since device clears its counter
    await prefs.setInt('nextIndex', 0);
  }
}
```

**Call `checkAndReset()` at the start of each BLE session, before requesting any images.** The sequence should be:

1. Connect & subscribe.
2. Check if reset is due → if yes, send `'R'` to `CmdChar`, wait for disconnect, reconnect on next device wake.
3. If no reset needed, begin requesting images from `nextIndexToRequest`.

**Important:** After a reset, the device deletes all SD files and restarts with `latest_index = 0`. Your app must also reset its `nextIndexToRequest` to `0` so they stay in sync.

---

## 10. Error Handling Reference

| Situation | Device Response | App Action |
|---|---|---|
| Requested index not on SD | `'X'` code 0 | Skip index: `nextIndex++`, request next |
| Memory alloc failure | `'X'` code 1 | Retry same index after 1 s |
| No request in 2 s | `'X'` code 5 | Re-send the same request immediately |
| Index beyond latest | `'N'` | Update `latestKnownIndex`, disconnect, wait |
| Client disconnected mid-transfer | — | On reconnect, retry `_nextIndex` (not yet confirmed) |
| Missing chunks (`chunksReceived != expectedChunks`) | — | Re-request same index |
| `latest_index` wrapped (> 9999 → 0) | — | Handle with modular arithmetic: `(index + 1) % 10000` |

---

## 11. Platform-Specific Notes

### Android
- Call `FlutterBluePlus.setLogLevel(LogLevel.warning)` in production.
- After `connect()`, always call `device.requestMtu(512)` before service discovery.
- On Android 12+ (`API 31+`), `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` are runtime permissions — request them before scanning.
- Some Android devices impose a **maximum of 7 concurrent GATT connections** system-wide. You only need one here, so this is not an issue.
- Samsung and Xiaomi devices apply aggressive battery optimisation. Guide users to disable battery optimisation for your app.

### iOS
- MTU is negotiated automatically; do not call `requestMtu`.
- iOS enforces a maximum notification payload of **~182 bytes for older iPhones**, but modern iPhones (XS and later) support up to 512 bytes (data length extension). If you see truncated chunks, your device's effective MTU may be smaller — the chunk header is still 2 bytes and payload will be whatever MTU-3 allows.
- You cannot scan for peripherals by name alone in background on iOS; you must scan by **service UUID**. Ensure you register `IMG_SERVICE_UUID` as the scan filter.
- State restoration requires your `CBCentralManager` to be created with the same restoration identifier every app launch.

---

## 12. Recommended Package Stack

| Package | Purpose |
|---|---|
| `flutter_blue_plus` | BLE central role, Android + iOS |
| `flutter_foreground_task` | Android foreground service scaffold |
| `shared_preferences` | Persisting `nextIndex` and `lastResetEpoch` |
| `path_provider` | Getting the correct documents/external storage path |
| `permission_handler` | Runtime permission requests (Bluetooth, storage) |
| `workmanager` | Optional: periodic background tasks on Android for reconnection attempts |

---

## Appendix: Example Python Bleak Receiver (Reference)

If you have Python test code using `bleak`, the equivalent mapping is:

| Bleak concept | Flutter/Dart equivalent |
|---|---|
| `BleakClient(address)` | `FlutterBluePlus.connect(device)` |
| `client.start_notify(uuid, handler)` | `characteristic.setNotifyValue(true)` + `.onValueReceived.listen(handler)` |
| `client.write_gatt_char(uuid, data)` | `characteristic.write(data)` |
| `asyncio.sleep(0.5)` after connect | `Future.delayed(const Duration(milliseconds: 500))` |
| Reassembly loop on queue | `_onData` callback writing into `_buffer` at indexed offset |

The key difference is that `bleak` is poll-driven (you can `await` inside the notify handler) whereas Flutter's BLE stack is event-driven — keep `_onStatus` and `_onData` non-async and fast; do disk I/O in `_onTransferComplete`.
