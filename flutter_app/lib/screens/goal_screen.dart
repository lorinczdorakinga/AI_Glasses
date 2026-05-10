import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'home_screen.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});
  @override State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  String? _selectedGoal;
  String? _selectedTime;
  bool    _loading = false;

  final List<Map<String, String>> _goals = [
    {
      'name': 'Focus',
      'description': 'Train your attention and get more done. Less distraction, more deep work. Build the habit of being fully present in what you do.',
    },
    {
      'name': 'Consumption',
      'description': 'This goal makes you use your time wisely. Less scrolling. Less binge watching. A reminder to take control of your own life and to not just go through it in spectator mode.',
    },
    {
      'name': 'Activity',
      'description': 'Move more, sit less. Whether it\'s a walk, a workout, or just stretching — this goal keeps you accountable to your body.',
    },
    {
      'name': 'Social',
      'description': 'Invest in your relationships. Reach out, show up, be present with the people who matter. Quality time over screen time.',
    },
    {
      'name': 'Explore',
      'description': 'Try new things. Read something different, visit a new place, learn a skill. Keep life interesting and growing.',
    },
  ];

  Future<void> _save() async {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a goal')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a summary time')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/goals'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'goal':         _selectedGoal,
          'summary_time': _selectedTime,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        final body = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['error'] ?? 'Something went wrong')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to server')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context:      context,
      initialTime:  now,
      builder: (context, child) {
        // Force 24-hour (military) time
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final hour   = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() => _selectedTime = '$hour:$minute');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Select your goal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Goal list
              Expanded(
                child: ListView.separated(
                  itemCount: _goals.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal     = _goals[index];
                    final isSelected = _selectedGoal == goal['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedGoal = goal['name']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.indigo : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected ? Colors.indigo.shade50 : Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['name']!,
                              style: TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.indigo : Colors.black87,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 8),
                              Text(
                                goal['description']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:    Colors.indigo.shade700,
                                  height:   1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Time picker
              Text(
                'When would you like to get notified of your daily summary?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border:        Border.all(color: Colors.grey.shade300),
                    borderRadius:  BorderRadius.circular(12),
                    color:         Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime ?? 'Select a timestamp',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedTime != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width:  double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}