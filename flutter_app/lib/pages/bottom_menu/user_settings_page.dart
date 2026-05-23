import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/login_screen.dart';
import '../../components/modern_settings_tile.dart'; 
import '../../widgets/settings_dialogs.dart'; 

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  String _username = 'Loading...';
  String _currentGoal = 'focus';
  bool _isLoading = true;

  Map<String, int> _levels = {
    'focus': 1, 'consumption': 1, 'activity': 1, 'social': 1, 'explore': 1,
  };

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  // --- HÁLÓZATI HÍVÁSOK ---

  Future<void> _loadUserSettings() async {
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
        final fetchedLevels = data['levels'] ?? {};
        setState(() {
          _username = data['username'] ?? 'User';
          _currentGoal = data['goal'] ?? 'focus';
          _levels = {
            'focus': fetchedLevels['focus'] ?? 1,
            'consumption': fetchedLevels['consumption'] ?? 1,
            'activity': fetchedLevels['activity'] ?? 1,
            'social': fetchedLevels['social'] ?? 1,
            'explore': fetchedLevels['explore'] ?? 1,
          };
          _isLoading = false;
        });
      } else {
        setState(() { _username = "Error loading"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings({String? newGoal, String? resetLevelForGoal}) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final response = await http.put(
        Uri.parse('http://187.124.25.127:3000/api/auth/settings'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
           'goal': ?newGoal,
           'resetLevelForGoal': ?resetLevelForGoal,
        }),
      );
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        _loadUserSettings(); 
        _showSuccess('Glasses progression updated!');
      } else {
        setState(() => _isLoading = false);
        _showError('Failed to update settings.');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCredentials({String? newEmail, String? newPassword, String? newUsername}) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final response = await http.put(
        Uri.parse('http://187.124.25.127:3000/api/auth/credentials'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
           'email': ?newEmail,
           'password': ?newPassword,
           'username': ?newUsername,
        }),
      );
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        if (newUsername != null) setState(() => _username = newUsername);
        setState(() => _isLoading = false);
        _showSuccess('Profile successfully updated!');
      } else {
        setState(() => _isLoading = false);
        _showError('Failed to update credentials.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Network error.');
      }
    }
  }
  
  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final response = await http.delete(
        Uri.parse('http://187.124.25.127:3000/api/auth/account'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        await context.read<AuthProvider>().logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      } else {
        setState(() => _isLoading = false);
        _showError('Failed to delete account.');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _performLogout() async {
    setState(() => _isLoading = true);
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.teal));
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  void _showMockFeedback(String title) => _showSuccess('Demo Action: $title clicked');

  // --- UI ÉPÍTÉS ---

  @override
  Widget build(BuildContext context) {
    int currentLevel = _levels[_currentGoal] ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profil Fejléc
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade700,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                            ),
                            child: const CircleAvatar(radius: 36, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 40, color: Colors.white)),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_username, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text('Level $currentLevel — ${_currentGoal.toUpperCase()}', style: TextStyle(fontSize: 14, color: Colors.teal.shade100, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    const Text('Profile Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    
                    // BEKÖTÖTT GOMBOK - Most már a Change Goal is az újat használja!
                    ModernSettingsTile(
                      title: 'Change Username', 
                      icon: Icons.badge, 
                      onTap: () => SettingsDialogs.showChangeUsername(context, onSubmit: (val) => _updateCredentials(newUsername: val)),
                    ),
                    ModernSettingsTile(
                      title: 'Change Password', 
                      icon: Icons.lock_outline, 
                      onTap: () => SettingsDialogs.showChangePassword(context, onSubmit: (val) => _updateCredentials(newPassword: val)),
                    ),
                    ModernSettingsTile(
                      title: 'Change Email', 
                      icon: Icons.email_outlined, 
                      onTap: () => SettingsDialogs.showChangeEmail(context, onSubmit: (val) => _updateCredentials(newEmail: val)),
                    ),
                    ModernSettingsTile(
                      title: 'Change Goal', 
                      icon: Icons.track_changes, 
                      onTap: () => SettingsDialogs.showChangeGoal(
                        context, 
                        currentGoal: _currentGoal, 
                        onSubmit: (newGoal) => _updateSettings(newGoal: newGoal),
                      ),
                    ),
                    ModernSettingsTile(
                      title: 'Change Summary Time', 
                      icon: Icons.access_time, 
                      onTap: () => _showMockFeedback('Change summary time'),
                    ),
                    ModernSettingsTile(
                      title: 'Start Over (Lvl 0)', 
                      icon: Icons.refresh, 
                      onTap: () => SettingsDialogs.showStartOver(
                        context, 
                        currentGoal: _currentGoal, 
                        onConfirm: () => _updateSettings(resetLevelForGoal: _currentGoal),
                      ),
                    ),
                    ModernSettingsTile(
                      title: 'View Badges', 
                      icon: Icons.workspace_premium, 
                      onTap: () => _showMockFeedback('View badges'),
                    ),
                    
                    const SizedBox(height: 30),
                    const Text('Glasses Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    ModernSettingsTile(
                      title: 'Forget Device', 
                      icon: Icons.bluetooth_disabled, 
                      onTap: () => _showMockFeedback('Forget device'),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Veszélyes műveletek (Piros ikonnal) - Modern UI-ba csomagolva
                    ModernSettingsTile(
                      title: 'Log Out', 
                      icon: Icons.logout, 
                      isDestructive: true,
                      onTap: () => SettingsDialogs.showDestructiveAction(
                        context,
                        title: 'Log Out',
                        content: 'Are you sure you want to log out from your account?',
                        buttonText: 'Log Out',
                        onConfirm: _performLogout,
                      ),
                    ),
                    ModernSettingsTile(
                      title: 'Delete Account', 
                      icon: Icons.delete_forever, 
                      isDestructive: true,
                      onTap: () => SettingsDialogs.showDestructiveAction(
                        context,
                        title: 'Delete Account',
                        content: 'Are you absolutely sure you want to permanently delete your account? This action CANNOT be undone.',
                        buttonText: 'Delete Forever',
                        onConfirm: _deleteAccount,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}