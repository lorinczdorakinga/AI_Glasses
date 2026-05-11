import 'package:flutter/material.dart';
import '../components/sneak_time_choose.dart';

// Ezt a függvényt kell meghívni a Dashboard-ról
void showSneakModeDialog(BuildContext context, {String glassesName = "Vision_8635"}) {
  showDialog(
    context: context,
    builder: (context) => _SneakModeDialogContent(glassesName: glassesName),
  );
}

class _SneakModeDialogContent extends StatefulWidget {
  final String glassesName;

  const _SneakModeDialogContent({required this.glassesName});

  @override
  State<_SneakModeDialogContent> createState() => _SneakModeDialogContentState();
}

class _SneakModeDialogContentState extends State<_SneakModeDialogContent> {
  bool _isTimeSelectionState = false;
  Duration? _selectedDuration;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 2), // A rajzod szerinti keret
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fejléc (Cím és X gomb)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Sneak mode',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Tartalom (Attól függően, melyik oldalon vagyunk)
            if (!_isTimeSelectionState)
              _buildInfoView()
            else
              _buildTimeSelectionView(),

            const SizedBox(height: 30),

            // Alsó gombok (Set sneak mode & Back)
            OutlinedButton(
              onPressed: () {
                if (!_isTimeSelectionState) {
                  // Átlépés a második állapotba
                  setState(() {
                    _isTimeSelectionState = true;
                  });
                } else {
                  // Véglegesítés a második oldalon
                  if (_selectedDuration != null) {
                    debugPrint('Sneak mode activated for: ${_selectedDuration!.inHours} hours');
                    // IDE JÖN A SNEAK MODE AKTIVÁLÁSA A BACKEND/HARDVER FELÉ
                    Navigator.pop(context); 
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.brown, width: 2), // Rajz szerinti szín
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text(
                'Set sneak mode',
                style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ),
            
            TextButton(
              onPressed: () {
                if (_isTimeSelectionState) {
                  // Vissza az első állapotba
                  setState(() {
                    _isTimeSelectionState = false;
                    _selectedDuration = null;
                  });
                } else {
                  // Ablak bezárása
                  Navigator.pop(context);
                }
              },
              child: const Text('back', style: TextStyle(fontSize: 18, color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }

  // Az első (Info) nézet
  Widget _buildInfoView() {
    return Text(
      'If you turn this on, your\n*${widget.glassesName}*\nwon\'t track you.',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 20),
    );
  }

  // A második (Időválasztó) nézet
  Widget _buildTimeSelectionView() {
    return Column(
      children: [
        _buildTimeOption('For 1h', const Duration(hours: 1)),
        _buildTimeOption('For 6h', const Duration(hours: 6)),
        _buildTimeOption('For 24h', const Duration(hours: 24)),
        _buildCustomTimeOption(),
      ],
    );
  }

  // Segédfüggvény az opciókhoz
  Widget _buildTimeOption(String text, Duration duration) {
    final isSelected = _selectedDuration == duration;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDuration = duration;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? Colors.teal : Colors.black, width: isSelected ? 2.5 : 1.5),
            color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }

  // A Custom opció gombja
  Widget _buildCustomTimeOption() {
    // Ha olyan duration van kiválasztva, ami nem az alap 3 (1, 6, 24), akkor a Custom aktív
    final isCustomSelected = _selectedDuration != null && 
        ![1, 6, 24].contains(_selectedDuration!.inHours);
        
    final displayText = isCustomSelected 
        ? 'Custom (${_selectedDuration!.inHours}h)' 
        : 'Custom';

    return InkWell(
      onTap: () async {
        final chosenDuration = await showCustomSneakTimePicker(context);
        if (chosenDuration != null) {
          setState(() {
            _selectedDuration = chosenDuration;
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isCustomSelected ? Colors.deepPurple : Colors.black, width: isCustomSelected ? 2.5 : 1.5),
          color: isCustomSelected ? Colors.deepPurple.withValues(alpha: (0.1)) : Colors.transparent,
        ),
        child: Text(
          displayText,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: isCustomSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}