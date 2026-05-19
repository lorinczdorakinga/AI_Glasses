import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void showDailyQuestDialog(BuildContext context, {String? questText, required Function(bool) onQuestCompleted}) {
  showDialog(
    context: context,
    builder: (context) => _DailyQuestDialogContent(
      questText: questText ?? 'Go out to get\ngroceries but\nwithout your\nphone.',
      onQuestCompleted: onQuestCompleted,
    ),
  );
}

class _DailyQuestDialogContent extends StatefulWidget {
  final String questText;
  final Function(bool) onQuestCompleted;

  const _DailyQuestDialogContent({required this.questText, required this.onQuestCompleted});
  @override
  State<_DailyQuestDialogContent> createState() => _DailyQuestDialogContentState();
}

class _DailyQuestDialogContentState extends State<_DailyQuestDialogContent> {
  bool _isLoading = false;

  Future<void> _acceptQuest() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final response = await http.post(
        Uri.parse('http://187.124.25.127:3000/api/auth/quest/complete'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        widget.onQuestCompleted(data['levelUp'] ?? false);
        Navigator.pop(context); 
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(20)),
              child: Text('DAILY QUEST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade700, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 24),
            Text(
              widget.questText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.3),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _acceptQuest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : const Text('Accept quest', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}