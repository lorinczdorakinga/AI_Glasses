import 'package:flutter/material.dart';

class SettingsDialogs {
  
  // 1. USERNAME MÓDOSÍTÁS
  static void showChangeUsername(BuildContext context, {required Function(String) onSubmit}) {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Change Username'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'New Username',
                hintText: 'e.g. Creator99',
                errorText: errorText,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  if (controller.text.trim().length < 3) {
                    setState(() => errorText = 'Must be at least 3 characters');
                    return;
                  }
                  Navigator.pop(ctx);
                  onSubmit(controller.text.trim());
                },
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // 2. EMAIL MÓDOSÍTÁS
  static void showChangeEmail(BuildContext context, {required Function(String) onSubmit}) {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Change Email'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'New Email Address',
                hintText: 'example@email.com',
                errorText: errorText,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  final email = controller.text.trim();
                  if (!email.contains('@') || !email.contains('.')) {
                    setState(() => errorText = 'Enter a valid email address');
                    return;
                  }
                  Navigator.pop(ctx);
                  onSubmit(email);
                },
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // 3. JELSZÓ MÓDOSÍTÁS
  static void showChangePassword(BuildContext context, {required Function(String) onSubmit}) {
    final controller = TextEditingController();
    String? errorText;
    bool isObscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Change Password'),
            content: TextField(
              controller: controller,
              obscureText: isObscure,
              decoration: InputDecoration(
                labelText: 'New Password',
                errorText: errorText,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => isObscure = !isObscure),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  if (controller.text.length < 6) {
                    setState(() => errorText = 'Must be at least 6 characters');
                    return;
                  }
                  Navigator.pop(ctx);
                  onSubmit(controller.text.trim());
                },
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

// 4. GOAL (CÉL) MÓDOSÍTÁS - Interaktív, kinyíló kártyás dizájnnal
  static void showChangeGoal(
    BuildContext context, {
    required String currentGoal,
    required Function(String) onSubmit,
  }) {
    // A kártyákhoz tartozó adatok
    final List<Map<String, String>> goals = [
      {
        'name': 'focus', // A szerver felé kisbetűvel megy
        'title': 'Focus',
        'description': 'Train your attention and get more done. Less distraction, more deep work. Build the habit of being fully present in what you do.',
      },
      {
        'name': 'consumption',
        'title': 'Consumption',
        'description': 'This goal makes you use your time wisely. Less scrolling. Less binge watching. A reminder to take control of your own life and to not just go through it in spectator mode.',
      },
      {
        'name': 'activity',
        'title': 'Activity',
        'description': 'Move more, sit less. Whether it\'s a walk, a workout, or just stretching — this goal keeps you accountable to your body.',
      },
      {
        'name': 'social',
        'title': 'Social',
        'description': 'Invest in your relationships. Reach out, show up, be present with the people who matter. Quality time over screen time.',
      },
      {
        'name': 'explore',
        'title': 'Explore',
        'description': 'Try new things. Read something different, visit a new place, learn a skill. Keep life interesting and growing.',
      },
    ];

    // Megkeressük az alapértelmezetten kiválasztott célt
    String selectedValue = goals.any((g) => g['name'] == currentGoal) ? currentGoal : 'focus';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Margó a képernyő szélétől
            backgroundColor: Colors.white,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8, // Ne lógjon ki a képernyőről
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select your goal',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  
                  // A lista görgethető része
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true, // Csak akkora legyen, amekkora kell
                      physics: const BouncingScrollPhysics(),
                      itemCount: goals.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        final isSelected = selectedValue == goal['name'];
                        
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedValue = goal['name']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.teal.shade500 : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              color: isSelected ? Colors.teal.shade50 : Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      goal['title']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.teal.shade800 : Colors.black87,
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: Colors.teal.shade600, size: 22),
                                  ],
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    goal['description']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.teal.shade900,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Mégse és Mentés gombok alul
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade300, width: 2),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (selectedValue != currentGoal) {
                              onSubmit(selectedValue);
                            }
                          },
                          child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 5. ÚJ: START OVER (LVL 0) - Piros, figyelmeztető dizájn
  static void showStartOver(BuildContext context, {required String currentGoal, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Progression?'),
        content: Text('This will instantly reset your ${currentGoal.toUpperCase()} level back to 0. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 6. ÚJ: LOGOUT ÉS DELETE ACCOUNT MEGERŐSÍTÉS
  static void showDestructiveAction(
    BuildContext context, {
    required String title,
    required String content,
    required String buttonText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(buttonText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}