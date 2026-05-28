import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Models ────────────────────────────────────────────────────────────────────

/// One entry from raw_memory.json.
/// File is a JSON array, each element looks like:
///   { "activity": "reading at desk", "score": true, "reason": "...", "timestamp": "..." }
class ActivityEntry {
  final String activity;   // max 5 words
  final bool score;        // true = aligned with user's goal
  final String reason;     // one sentence explanation
  final DateTime timestamp;

  const ActivityEntry({
    required this.activity,
    required this.score,
    required this.reason,
    required this.timestamp,
  });

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    return ActivityEntry(
      activity:  json['activity']  as String? ?? '',
      score:     json['score']     as bool?   ?? false,
      reason:    json['reason']    as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// The single object inside compressed_memory.json:
///   { "summary": "...", "focus": 72, "consumption": 35,
///     "activity": 60, "social": 20, "explore": 45 }
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

  /// Converts 0-100 server values → 0-5 scale for fl_chart RadarChart.
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

/// Quest — served from your existing /api/auth/quest endpoint.
/// Shape: { "quest": "...", "completed": false }
class DailyQuest {
  final String questText;
  final bool completed;

  const DailyQuest({required this.questText, required this.completed});

  factory DailyQuest.empty() =>
      const DailyQuest(questText: '', completed: false);

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      questText: json['quest'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

class DataProvider with ChangeNotifier {
  // Direct HTTP access to the raw JSON files on the server.
  // The server must serve /root/smart_glasses/ as static files, or you add
  // two tiny GET endpoints that just read and return those files.
  // Simplest: in your Node.js server add:
  //   app.use('/memory', express.static('/root/smart_glasses'));
  // Then these URLs work as-is:
  static const String _rawUrl =
      'http://187.124.25.127:3000/memory/raw_memory.json';
  static const String _compressedUrl =
      'http://187.124.25.127:3000/memory/compressed_memory.json';

  // ── Public state ──────────────────────────────────────────────────────────
  List<ActivityEntry> activities = [];
  DailySummary summary = DailySummary.empty();
  DailyQuest quest = DailyQuest.empty();
  int batteryPercent = 0;   // written directly by BleImageService via BLE notify

  bool isLoading = false;
  String? lastError;
  DateTime? lastRefreshed;

  // ── Private ───────────────────────────────────────────────────────────────
  Timer? _pollTimer;
  bool _disposed = false;

  DataProvider() {
    _loadFromCache();   // show cached data instantly on startup
    fetchAll();         // then hit the server
    // Poll every 65 s (camera wakes every 60 s, so we're always slightly behind
    // the upload, meaning a new image will already be processed when we poll)
    _pollTimer = Timer.periodic(const Duration(seconds: 65), (_) => fetchAll());
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Called by BleImageService immediately after a successful image upload
  /// so the UI updates without waiting for the next poll tick.
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

      // Fetch both memory files + quest endpoint in parallel
      final rawResult        = await _fetchList(_rawUrl, headers);
      final compressedResult = await _fetchRawObject(_compressedUrl, headers);
      final questResult      = await _fetchRawObject(
          'http://187.124.25.127:3000/api/auth/quest', headers);

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

  // ── Fetch helpers ─────────────────────────────────────────────────────────

  /// GETs a URL that returns a JSON array and parses it into ActivityEntry list.
  /// raw_memory.json is a bare array: [ {...}, {...}, ... ]
  Future<List<ActivityEntry>?> _fetchList(
      String url, Map<String, String> headers) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        // Handle empty file gracefully
        if (body.isEmpty || body == 'null' || body == '[]') return [];

        final decoded = json.decode(body);
        if (decoded is List) {
          return decoded
              .map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return null;
  }

  /// GETs a URL that returns a JSON object → raw Map (caller does fromJson).
  Future<Map<String, dynamic>?> _fetchRawObject(
      String url, Map<String, String> headers) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null' || body == '{}') return null;
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return null;
  }

  // ── Cache ─────────────────────────────────────────────────────────────────

  void _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save raw list as a JSON array string
      await prefs.setString(
        'cache_raw',
        json.encode(activities.map((e) => {
          'activity':  e.activity,
          'score':     e.score,
          'reason':    e.reason,
          'timestamp': e.timestamp.toIso8601String(),
        }).toList()),
      );
      // Save compressed as a JSON object string
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
          activities = decoded
              .map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      final compStr = prefs.getString('cache_compressed');
      if (compStr != null) {
        final decoded = json.decode(compStr);
        if (decoded is Map<String, dynamic>) {
          summary = DailySummary.fromJson(decoded);
        }
      }

      final questStr = prefs.getString('cache_quest');
      if (questStr != null) {
        final decoded = json.decode(questStr);
        if (decoded is Map<String, dynamic>) {
          quest = DailyQuest.fromJson(decoded);
        }
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