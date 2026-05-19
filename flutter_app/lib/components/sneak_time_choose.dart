import 'package:flutter/material.dart';

Future<Duration?> showCustomSneakTimePicker(BuildContext context) async {
  double selectedHours = 12.0; // Alapértelmezett érték

  return showDialog<Duration>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fejléc
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Custom Time', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Nagy "Kijelző" doboz a kiválasztott órának
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.teal.shade100, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${selectedHours.toInt()}',
                          style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.teal.shade700, height: 1.0),
                        ),
                        Text(
                          'HOURS',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade600, letterSpacing: 3.0),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Egyedi Slider Dizájn
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.teal.shade600,
                      inactiveTrackColor: Colors.teal.shade100,
                      trackHeight: 10.0, // Vastagabb, tapinthatóbb sáv
                      thumbColor: Colors.teal.shade700,
                      overlayColor: Colors.teal.withValues(alpha: 0.2),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
                    ),
                    child: Slider(
                      value: selectedHours,
                      min: 1,
                      max: 48,
                      divisions: 47,
                      onChanged: (value) {
                        setState(() {
                          selectedHours = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Maximum 48h allowed', style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500)),
                  
                  const SizedBox(height: 32),
                  
                  // Fő megerősítő gomb
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context, Duration(hours: selectedHours.toInt()));
                      },
                      child: const Text('Confirm', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}