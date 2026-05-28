import 'package:flutter/material.dart';
import '../pages/bottom_menu/dashboard_page.dart';
import '../pages/bottom_menu/my_glasses_page.dart';
import '../pages/bottom_menu/progress_page.dart';
import '../pages/bottom_menu/user_settings_page.dart';
import '../pages/bottom_menu/nutrition_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // const eltávolítva — MyGlassesPage context.watch()-ot használ,
  // ezért nem lehet konstans lista eleme
  final List<Widget> _pages = [
    const DashboardPage(),
    const MyGlassesPage(),
    const ProgressPage(),
    const NutritionPage(),
    const UserSettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.visibility), label: 'Glasses'),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}