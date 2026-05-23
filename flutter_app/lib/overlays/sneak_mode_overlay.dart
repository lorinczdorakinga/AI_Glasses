import 'package:flutter/material.dart';
import '../components/sneak_time_choose.dart';

void showSneakModeDialog(BuildContext context, {String glassesName = "Vision_8635"}) {
  showDialog(context: context, builder: (context) => _SneakModeDialogContent(glassesName: glassesName));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sneak Mode', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
            const SizedBox(height: 24),
            if (!_isTimeSelectionState) _buildInfoView() else _buildTimeSelectionView(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (!_isTimeSelectionState) {
                    setState(() => _isTimeSelectionState = true);
                  } else if (_selectedDuration != null) {
                    Navigator.pop(context); 
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Set sneak mode', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (_isTimeSelectionState) {
                  setState(() { _isTimeSelectionState = false; _selectedDuration = null; });
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Back', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoView() {
    return Column(
      children: [
        Icon(Icons.visibility_off, size: 64, color: Colors.teal.shade300),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 18, color: Colors.black87, height: 1.4),
            children: [
              const TextSpan(text: 'If you turn this on, your\n'),
              TextSpan(text: widget.glassesName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              const TextSpan(text: '\nwon\'t track you.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelectionView() {
    return Column(
      children: [
        _buildTimeOption('For 1 Hour', const Duration(hours: 1)),
        _buildTimeOption('For 6 Hours', const Duration(hours: 6)),
        _buildTimeOption('For 24 Hours', const Duration(hours: 24)),
        _buildCustomTimeOption(),
      ],
    );
  }

  Widget _buildTimeOption(String text, Duration duration) {
    final isSelected = _selectedDuration == duration;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedDuration = duration),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Colors.teal.shade50 : Colors.white,
          ),
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: isSelected ? Colors.teal.shade800 : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildCustomTimeOption() {
    final isCustomSelected = _selectedDuration != null && ![1, 6, 24].contains(_selectedDuration!.inHours);
    final displayText = isCustomSelected ? 'Custom (${_selectedDuration!.inHours}h)' : 'Custom';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final chosenDuration = await showCustomSneakTimePicker(context);
        if (chosenDuration != null) setState(() => _selectedDuration = chosenDuration);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: isCustomSelected ? Colors.teal : Colors.grey.shade300, width: isCustomSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isCustomSelected ? Colors.teal.shade50 : Colors.white,
        ),
        child: Text(displayText, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: isCustomSelected ? Colors.teal.shade800 : Colors.black87, fontWeight: isCustomSelected ? FontWeight.bold : FontWeight.w500)),
      ),
    );
  }
}