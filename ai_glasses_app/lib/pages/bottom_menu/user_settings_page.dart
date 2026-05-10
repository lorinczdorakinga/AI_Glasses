import 'package:flutter/material.dart';

class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Felső profil szekció
          Row(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '*username*',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.visibility),
                      const SizedBox(width: 8),
                      const Icon(Icons.battery_4_bar),
                      const SizedBox(width: 4),
                      const Text('41%', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Profile Settings szekció
          const Text('Profile settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSettingsButton('Change password'),
          _buildSettingsButton('Change email'),
          _buildSettingsButton('Change goal'),
          _buildSettingsButton('Change summary time'),
          _buildSettingsButton('Start over (Lvl 0)'),
          _buildSettingsButton('View badges'),
          
          const SizedBox(height: 40),

          // Glasses Settings szekció
          const Text('Glasses settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSettingsButton('Forget device'),
        ],
      ),
    );
  }

  // Segédfüggvény a gombok gyors generálásához
  Widget _buildSettingsButton(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            // Gomb funkciója
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}