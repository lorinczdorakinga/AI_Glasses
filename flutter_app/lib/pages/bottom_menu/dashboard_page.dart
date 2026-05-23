import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import '../../overlays/sneak_mode_overlay.dart';
import '../../overlays/daily_quest_overlay.dart';
import '../../overlays/activity_list_overlay.dart';
import '../../components/good_pulsing_sphere.dart';
import '../../components/bad_pulsing_sphere.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/login_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  String _currentGoal = 'focus';
  int _currentLevel = 1;
  int _completedQuests = 0;

  late ConfettiController _confettiController;

  final List<DailyActivity> todayActivities = [
    DailyActivity(time: "7:08", description: "energiaital", isGood: false),
    DailyActivity(time: "7:56", description: "séta, kávé helyett", isGood: true),
    DailyActivity(time: "8:10", description: "cigaretta", isGood: false),
    DailyActivity(time: "8:39", description: "tanulás", isGood: true),
    DailyActivity(time: "9:10", description: "veszekedés a buszsofőrrel", isGood: false),
  ];

  List <DailyActivity> _todayActivities = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final response = await http.get(
        Uri.parse('http://187.124.25.127:3000/api/auth/settings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final goal = data['goal'] ?? 'focus';
        final levels = data['levels'] ?? {};
        
        final rawActivities = data['activities'] as List<dynamic>? ?? [];
        List<DailyActivity> fetchedActivities = rawActivities.map((item) => DailyActivity(
          time: item['time'] ?? '00:00',
          description: item['description'] ?? 'Unknown activity',
          isGood: item['isGood'] ?? false,
        )).toList();

        // ÚJ: A MOCK LOGIKA ITT VAN! Ha a backend üreset küld, betöltjük a teszt adatokat.
        if (fetchedActivities.isEmpty) {
          fetchedActivities = [
            DailyActivity(time: "7:08", description: "energiaital", isGood: false),
            DailyActivity(time: "7:56", description: "séta, kávé helyett", isGood: true),
            DailyActivity(time: "8:10", description: "cigaretta", isGood: false),
            DailyActivity(time: "8:39", description: "tanulás", isGood: true),
            DailyActivity(time: "9:10", description: "veszekedés a buszsofőrrel", isGood: false),
          ];
        }

        setState(() {
          _currentGoal = goal;
          _currentLevel = levels[goal] ?? 1;
          _completedQuests = data['completedQuests'] ?? 0;
          _todayActivities = fetchedActivities; // Ezt használja majd a gömb logikája is!
          _isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await context.read<AuthProvider>().logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.teal));

    // Számolás az ÚJ listából
    int goodCount = _todayActivities.where((a) => a.isGood).length;
    int badCount = _todayActivities.where((a) => !a.isGood).length;
    bool showGoodSphere = goodCount >= badCount;
    double progressValue = _completedQuests / 5.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA), // Elegáns, világos háttér
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  // PRÉMIUM FEJLÉC KÁRTYA
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
                        // ANIMÁLT XP SÁV
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
                  
                  // ANIMÁLT GÖMB
                  GestureDetector(
                    // Átadjuk az új listát a felugró ablaknak
                    onTap: () => showActivityListDialog(context, _todayActivities), 
                    child: Hero(
                      tag: 'sphere',
                      child: showGoodSphere ? const GoodPulsingSphere() : const BadPulsingSphere(),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // PRÉMIUM DAILY QUEST GOMB
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
                              _fetchDashboardData();
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