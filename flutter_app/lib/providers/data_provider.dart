import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ActivityEntry {
  final String activity;
  final bool score;
  final String reason;
  final DateTime timestamp;
  final String displayTime; // ÚJ: Előre formázott, biztonságos időpont a UI-nak

  const ActivityEntry({
    required this.activity,
    required this.score,
    required this.reason,
    required this.timestamp,
    required this.displayTime,
  });

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime = DateTime.now();
    String formattedTime = "--:--";

    // Több kulccsal is próbálkozunk, hátha a JSON-ben máshogy szerepel
    var ts = json['timestamp'] ?? json['time'] ?? json['date'];
    
    if (ts != null) {
      String tsStr = ts.toString().trim();
      
      // ESET 1: A szerver csak egy rövid időt küld, pl. "14:30" vagy "07:08"
      if (tsStr.length <= 5 && tsStr.contains(':')) {
        formattedTime = tsStr;
        final parts = tsStr.split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          parsedTime = DateTime(now.year, now.month, now.day, int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
        }
      } 
      // ESET 2: UNIX timestamp jön (számként)
      else if (ts is int) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(ts > 9999999999 ? ts : ts * 1000);
        final local = parsedTime.toLocal();
        formattedTime = "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
      }
      // ESET 3: Teljes dátum string, pl. "2026-05-23T07:08:00Z"
      else {
        // A replaceAll biztosítja, hogy a szóközöket T-re cserélje, ha hiányozna
        parsedTime = DateTime.tryParse(tsStr.replaceAll(' ', 'T')) ?? DateTime.now();
        final local = parsedTime.toLocal();
        formattedTime = "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
      }
    }

    return ActivityEntry(
      activity:  json['activity']?.toString() ?? 'Unknown',
      score:     json['score'] == true || json['score'] == 'true',
      reason:    json['reason']?.toString() ?? '',
      timestamp: parsedTime,
      displayTime: formattedTime,
    );
  }
}

class DailySummary {
  final String summary;
  final double focus;
  final double consumption;
  final double activity;
  final double social;
  final double explore;

  const DailySummary({
    required this.summary,
    required this.focus,
    required this.consumption,
    required this.activity,
    required this.social,
    required this.explore,
  });

  factory DailySummary.empty() => const DailySummary(
        summary: '',
        focus: 0, consumption: 0, activity: 0, social: 0, explore: 0,
      );

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }
    return DailySummary(
      summary:     json['summary']     as String? ?? '',
      focus:       _d(json['focus']),
      consumption: _d(json['consumption']),
      activity:    _d(json['activity']),
      social:      _d(json['social']),
      explore:     _d(json['explore']),
    );
  }

  double radarValue(String key) {
    final map = {
      'focus':       focus,
      'consumption': consumption,
      'activity':    activity,
      'social':      social,
      'explore':     explore,
    };
    return ((map[key] ?? 0) / 100 * 5).clamp(0, 5);
  }
}

class DailyQuest {
  final String questText;
  final bool completed;

  const DailyQuest({required this.questText, required this.completed});

  factory DailyQuest.empty() => const DailyQuest(questText: '', completed: false);

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      questText: json['quest'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

class DataProvider with ChangeNotifier {
  static const String _rawUrl = 'http://187.124.25.127:3000/memory/raw_memory.json';
  static const String _compressedUrl = 'http://187.124.25.127:3000/memory/compressed_memory.json';

  List<ActivityEntry> activities = [];
  DailySummary summary = DailySummary.empty();
  DailyQuest quest = DailyQuest.empty();
  int batteryPercent = 0;   

  bool isLoading = false;
  String? lastError;
  DateTime? lastRefreshed;

  Timer? _pollTimer;
  bool _disposed = false;

  DataProvider() {
    _loadFromCache();   
    fetchAll();         
    _pollTimer = Timer.periodic(const Duration(seconds: 65), (_) => fetchAll());
  }

  Future<void> onImageUploaded() => fetchAll();

  Future<void> fetchAll() async {
    if (_disposed) return;
    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      final prefs   = await SharedPreferences.getInstance();
      final token   = prefs.getString('auth_token') ?? '';
      final headers = {'Authorization': 'Bearer $token'};

      final rawResult        = await _fetchList(_rawUrl, headers);
      final compressedResult = await _fetchRawObject(_compressedUrl, headers);
      final questResult      = await _fetchRawObject('http://187.124.25.127:3000/api/auth/quest', headers);

      if (_disposed) return;

      if (rawResult != null) activities = rawResult;
      if (compressedResult != null) summary = DailySummary.fromJson(compressedResult);
      if (questResult != null) quest = DailyQuest.fromJson(questResult);

      lastRefreshed = DateTime.now();
      _saveToCache();
    } catch (e) {
      lastError = e.toString();
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<List<ActivityEntry>?> _fetchList(String url, Map<String, String> headers) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null' || body == '[]') return [];
        final decoded = json.decode(body);
        if (decoded is List) {
          return decoded.map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _fetchRawObject(String url, Map<String, String> headers) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null' || body == '{}') return null;
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return null;
  }

  void _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cache_raw',
        json.encode(activities.map((e) => {
          'activity':  e.activity,
          'score':     e.score,
          'reason':    e.reason,
          'timestamp': e.timestamp.toIso8601String(),
          'time':      e.displayTime, // Ezt a biztonság kedvéért kimentjük
        }).toList()),
      );
      await prefs.setString(
        'cache_compressed',
        json.encode({
          'summary':     summary.summary,
          'focus':       summary.focus,
          'consumption': summary.consumption,
          'activity':    summary.activity,
          'social':      summary.social,
          'explore':     summary.explore,
        }),
      );
      await prefs.setString(
        'cache_quest',
        json.encode({'quest': quest.questText, 'completed': quest.completed}),
      );
    } catch (_) {}
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawStr = prefs.getString('cache_raw');
      if (rawStr != null) {
        final decoded = json.decode(rawStr);
        if (decoded is List) {
          activities = decoded.map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>)).toList();
        }
      }

      final compStr = prefs.getString('cache_compressed');
      if (compStr != null) {
        final decoded = json.decode(compStr);
        if (decoded is Map<String, dynamic>) summary = DailySummary.fromJson(decoded);
      }

      final questStr = prefs.getString('cache_quest');
      if (questStr != null) {
        final decoded = json.decode(questStr);
        if (decoded is Map<String, dynamic>) quest = DailyQuest.fromJson(decoded);
      }

      if (activities.isNotEmpty || summary.summary.isNotEmpty) {
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}