import 'package:flutter/material.dart';

Future<Duration?> showCustomSneakTimePicker(BuildContext context) async {
  double selectedHours = 12.0; // Alapértelmezett érték

  return showDialog<Duration>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Custom time', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${selectedHours.toInt()} hours',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: selectedHours,
                  min: 1,
                  max: 48,
                  divisions: 47,
                  activeColor: Colors.teal,
                  onChanged: (value) {
                    setState(() {
                      selectedHours = value;
                    });
                  },
                ),
                const Text('Maximum 48h allowed', style: TextStyle(color: Colors.grey)),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.black)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context, Duration(hours: selectedHours.toInt()));
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
}