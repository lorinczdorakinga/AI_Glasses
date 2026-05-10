import 'package:flutter/material.dart';
import 'pages/bottom_menu/dashboard_page.dart';
import 'pages/bottom_menu/my_glasses_page.dart';
import 'pages/bottom_menu/progress_page.dart';
import 'pages/bottom_menu/user_settings_page.dart';

void main() {
  runApp(const AiGlassesApp());
}

class AiGlassesApp extends StatelessWidget {
  const AiGlassesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Glasses',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // A négy képernyő listája
  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    MyGlassesPage(),
    ProgressPage(),
    UserSettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Hogy a 4 ikon ne ugráljon
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility),
            label: 'Glasses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radar), // Vagy Icons.track_changes
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}
