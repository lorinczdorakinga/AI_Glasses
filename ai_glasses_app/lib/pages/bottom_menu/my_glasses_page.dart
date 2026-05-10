import 'package:flutter/material.dart';

class MyGlassesPage extends StatelessWidget {
  const MyGlassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'You have no glasses connected to your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 60),
            
            // Bind device gomb
            OutlinedButton(
              onPressed: () {
                // Ide jön majd a Bluetooth keresés indítása
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.pinkAccent, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Bind device',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                ),
              ),
            ),
            
            const SizedBox(height: 80),
            
            // Radar / Sugárzó ikon
            const Icon(
              Icons.sensors, // Ez hasonlít a legjobban a rajzolt radarodra
              size: 80,
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}