import 'package:flutter/material.dart';
import '../../overlays/sneak_mode_overlay.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Felső sor: Szint és Szem ikon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Level 12 - Consumer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.visibility, size: 32),
                    onPressed: () {
                      showSneakModeDialog(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Tapasztalati pont (XP) sáv
            Row(
              children: [
                const Text('12', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.7, // 70%-os töltöttség
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
                const Text('13', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            
            const Spacer(),

            // A középső nagy "Gömb" (Később ide jöhet a Rive animáció)
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.teal,
                  width: 3,
                ),
                // Opcionális háttérszín a gömbnek:
                // color: Colors.teal.withOpacity(0.1),
              ),
            ),

            const Spacer(),

            // Daily Quest gomb (A rajzon lévő sárgás kiemeléssel)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextButton(
                onPressed: () {
                  // Ide jön a napi küldetés megnyitása
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'DAILY QUEST',
                    style: TextStyle(
                      fontSize: 22,
                      letterSpacing: 2.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}