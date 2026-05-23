import 'package:flutter/material.dart';

class DailyActivity {
  final String time;
  final String description;
  final bool isGood;
  DailyActivity({required this.time, required this.description, required this.isGood});
}

void showActivityListDialog(BuildContext context, List<DailyActivity> activities) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's Activity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 16),
              Flexible( 
                child: RawScrollbar( 
                  thumbColor: Colors.teal.shade200,
                  radius: const Radius.circular(8),
                  thickness: 4,
                  child: ListView.separated(
                    shrinkWrap: true, 
                    physics: const BouncingScrollPhysics(),
                    itemCount: activities.length, // Most már közvetlenül a kapott listát használja
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: activity.isGood ? Colors.teal : Colors.red.shade400),
                            ),
                            const SizedBox(width: 16),
                            Text(activity.time, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(activity.description, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}