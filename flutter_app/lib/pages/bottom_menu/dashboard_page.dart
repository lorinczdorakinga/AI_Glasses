import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../overlays/sneak_mode_overlay.dart';
import '../../overlays/daily_quest_overlay.dart';
import '../../overlays/activity_list_overlay.dart';
import '../../components/good_pulsing_sphere.dart';
import '../../components/bad_pulsing_sphere.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart'; // Fontos: beimportáltuk a DataProvider-t
import '../../screens/login_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoadingSettings = true;
  String _currentGoal = 'focus';
  int _currentLevel = 1;
  int _completedQuests = 0;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _fetchSettingsData(); 
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Ez most már KIZÁRÓLAG a /api/auth/settings adatokat kéri le, a JSON fájlokat a DataProvider intézi!
  Future<void> _fetchSettingsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final settingsResponse = await http.get(
        Uri.parse('http://187.124.25.127:3000/api/auth/settings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (settingsResponse.statusCode == 200) {
        final data = json.decode(settingsResponse.body);
        final goal = data['goal'] ?? 'focus';
        final levels = data['levels'] ?? {};

        setState(() {
          _currentGoal = goal;
          _currentLevel = levels[goal] ?? 1;
          _completedQuests = data['completedQuests'] ?? 0;
          _isLoadingSettings = false;
        });
      } else if (settingsResponse.statusCode == 401 || settingsResponse.statusCode == 403) {
        await context.read<AuthProvider>().logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      } else {
        setState(() => _isLoadingSettings = false);
      }
    } catch (e) {
      print("Hálózati hiba: $e");
      if (mounted) setState(() => _isLoadingSettings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Felolvassuk a json fájlokból betöltött adatokat a DataProviderből
    final data = context.watch<DataProvider>();

    if (_isLoadingSettings) return const Center(child: CircularProgressIndicator(color: Colors.teal));

    // 2. Kiszámoljuk a gömb színét a szerverről jövő json lista alapján
    int goodCount = data.activities.where((a) => a.score).length;
    int badCount = data.activities.where((a) => !a.score).length;
    bool showGoodSphere = goodCount >= badCount;
    
    double progressValue = _completedQuests / 5.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level $_currentLevel',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentGoal.toUpperCase(),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.teal.shade600, letterSpacing: 1.5),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.remove_red_eye_rounded, size: 28, color: Colors.teal.shade700),
                                onPressed: () => showSneakModeDialog(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text('$_currentLevel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 1), blurRadius: 3)],
                                    ),
                                    child: Stack(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 800),
                                          curve: Curves.easeOutCubic,
                                          width: constraints.maxWidth * progressValue,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [Colors.teal.shade300, Colors.teal.shade700]),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('${_currentLevel + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // ── IDE KERÜLT ÁT A LISTA MEGNYITÁSA ─────────────────
                  GestureDetector(
                    onTap: data.activities.isEmpty
                        ? null // Ha üres a json, nem csinál semmit a kattintásra
                        : () {
                            // Átalakítjuk a Provider adatait a felugró ablak számára
                            List<DailyActivity> mappedActivities = data.activities.map((e) {
                              final hour = e.timestamp.hour.toString().padLeft(2, '0');
                              final min  = e.timestamp.minute.toString().padLeft(2, '0');
                              return DailyActivity(
                                time: '$hour:$min',
                                description: e.activity,
                                isGood: e.score,
                              );
                            }).toList();
                            
                            showActivityListDialog(context, mappedActivities);
                          },
                    child: Hero(
                      tag: 'sphere',
                      child: showGoodSphere ? const GoodPulsingSphere() : const BadPulsingSphere(),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  Container(
                    width: double.infinity,
                    height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]),
                      boxShadow: [
                        BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          showDailyQuestDialog(
                            context, 
                            onQuestCompleted: (isLevelUp) {
                              _fetchSettingsData();
                              if (isLevelUp) {
                                _confettiController.play();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 LEVELED UP! Congrats. You are one step ahead.'), 
                                    backgroundColor: Colors.purple,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'DAILY QUEST',
                              style: TextStyle(fontSize: 20, letterSpacing: 2.0, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.teal, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.amber],
              ),
            ),
          ],
        ),
      ),
    );
  }
}