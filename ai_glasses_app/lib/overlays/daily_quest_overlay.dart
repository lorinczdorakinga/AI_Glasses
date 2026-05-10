import 'package:flutter/material.dart';

// Ezt a függvényt hívjuk meg a gombnyomásra
void showDailyQuestDialog(BuildContext context, {String? questText}) {
  showDialog(
    context: context,
    builder: (context) => _DailyQuestDialogContent(
      // Ha nem adunk meg szöveget, a rajzodon lévő dummy szöveget használja
      questText: questText ?? 'Go out to get\ngroceries but\nwithout your\nphone.',
    ),
  );
}

class _DailyQuestDialogContent extends StatelessWidget {
  final String questText;

  const _DailyQuestDialogContent({required this.questText});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bezáró X gomb a jobb felső sarokban
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            
            // "DAILY QUEST" cím sárga, dupla keretben (a rajzolt kiemelés imitálása)
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 30),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Text(
                  'DAILY QUEST',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),

            // A küldetés szövege (a rajzhoz hasonló narancsos-pirosas színnel)
            Text(
              questText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange, 
                height: 1.3,
              ),
            ),
            
            const SizedBox(height: 40),

            // "Accept quest" ovális gomb
            OutlinedButton(
              onPressed: () {
                debugPrint('Quest accepted!');
                // IDE JÖN A LOGIKA A KÜLDETÉS ELFOGADÁSÁRA
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black, width: 2),
                shape: const StadiumBorder(), // Teljesen lekerekített (ovális) forma
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                'Accept quest',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}