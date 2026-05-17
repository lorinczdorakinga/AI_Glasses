import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});
  @override State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  bool _isSubscribed   = false;
  bool _loading        = true;
  bool _paymentLoading = false;
  List<dynamic> _foodLog = [];

  final _mealController    = TextEditingController();
  final _calorieController = TextEditingController();
  String _mealType = 'breakfast';

  // ── Recipes ───────────────────────────────────────────────
  final Map<String, Map<String, dynamic>> _recipes = {
    'Blueberries + Greek yogurt': {
      'time': '5 min',
      'ingredients': ['1 cup Greek yogurt', '½ cup blueberries', '1 tsp honey', 'Optional: granola'],
      'steps': ['Add Greek yogurt to a bowl', 'Top with blueberries', 'Drizzle honey on top', 'Add granola if desired'],
    },
    'Salmon with quinoa': {
      'time': '25 min',
      'ingredients': ['1 salmon fillet', '½ cup quinoa', '1 cup water', 'Salt, pepper, lemon'],
      'steps': ['Cook quinoa in water for 15 min', 'Season salmon with salt and pepper', 'Pan fry salmon 4 min each side', 'Serve over quinoa with lemon'],
    },
    'Dark chocolate + almonds': {
      'time': '2 min',
      'ingredients': ['2 squares dark chocolate (70%+)', 'A handful of almonds'],
      'steps': ['Portion out almonds', 'Break chocolate into squares', 'Enjoy together as a snack'],
    },
    'Avocado toast': {
      'time': '10 min',
      'ingredients': ['2 slices bread', '1 ripe avocado', 'Salt, pepper, chili flakes', 'Optional: egg'],
      'steps': ['Toast the bread', 'Mash avocado with salt and pepper', 'Spread on toast', 'Add chili flakes on top'],
    },
    'Water + lemon before meals': {
      'time': '2 min',
      'ingredients': ['1 glass water', '½ lemon'],
      'steps': ['Squeeze lemon into water', 'Drink 15-30 min before eating', 'Helps digestion and reduces overeating'],
    },
    'Vegetable soup': {
      'time': '30 min',
      'ingredients': ['2 carrots', '2 celery stalks', '1 onion', '2 potatoes', 'Vegetable broth', 'Salt, pepper'],
      'steps': ['Chop all vegetables', 'Sauté onion for 3 min', 'Add vegetables and broth', 'Simmer 20 min until soft', 'Season and serve'],
    },
    'Apple instead of chips': {
      'time': '2 min',
      'ingredients': ['1 apple', 'Optional: 1 tbsp peanut butter'],
      'steps': ['Slice the apple', 'Dip in peanut butter if desired', 'Enjoy as a snack'],
    },
    'Herbal tea': {
      'time': '5 min',
      'ingredients': ['1 herbal tea bag', '1 cup hot water', 'Optional: honey'],
      'steps': ['Boil water', 'Steep tea bag for 3-5 min', 'Add honey if desired', 'Sip slowly'],
    },
    'Banana before workout': {
      'time': '1 min',
      'ingredients': ['1 banana'],
      'steps': ['Eat 30 min before workout', 'Provides quick energy and potassium'],
    },
    'Chicken + sweet potato': {
      'time': '35 min',
      'ingredients': ['1 chicken breast', '1 sweet potato', 'Olive oil', 'Salt, pepper, paprika'],
      'steps': ['Preheat oven to 200°C', 'Cut sweet potato into chunks', 'Season chicken and potato with spices', 'Roast for 25-30 min'],
    },
    'Protein shake': {
      'time': '3 min',
      'ingredients': ['1 scoop protein powder', '250ml milk or water', 'Optional: banana or peanut butter'],
      'steps': ['Add all ingredients to blender', 'Blend for 30 seconds', 'Drink immediately after workout'],
    },
    'Oats + peanut butter': {
      'time': '10 min',
      'ingredients': ['½ cup rolled oats', '1 cup milk', '1 tbsp peanut butter', '1 tsp honey'],
      'steps': ['Cook oats in milk for 5 min', 'Stir in peanut butter', 'Top with honey', 'Serve warm'],
    },
    'Shared salad bowl': {
      'time': '10 min',
      'ingredients': ['Mixed greens', 'Cherry tomatoes', 'Cucumber', 'Feta cheese', 'Olive oil', 'Lemon'],
      'steps': ['Wash and chop vegetables', 'Mix in a large bowl', 'Crumble feta on top', 'Dress with olive oil and lemon'],
    },
    'Hummus + veggies platter': {
      'time': '5 min',
      'ingredients': ['200g hummus', 'Carrots', 'Cucumber', 'Bell pepper', 'Celery'],
      'steps': ['Slice all vegetables into sticks', 'Arrange around hummus bowl', 'Serve and share'],
    },
    'Fruit skewers': {
      'time': '10 min',
      'ingredients': ['Strawberries', 'Grapes', 'Melon', 'Kiwi', 'Skewer sticks'],
      'steps': ['Cut fruit into bite-size pieces', 'Thread onto skewers alternating colors', 'Serve chilled'],
    },
    'Mixed nuts': {
      'time': '1 min',
      'ingredients': ['Almonds', 'Walnuts', 'Cashews', 'Hazelnuts'],
      'steps': ['Portion out a small handful', 'Mix varieties together', 'Enjoy as a snack'],
    },
    'Try a new cuisine today': {
      'time': 'Varies',
      'ingredients': ['Pick a cuisine you\'ve never tried', 'Find a local restaurant or recipe online'],
      'steps': ['Choose a cuisine (Thai, Ethiopian, Georgian...)', 'Find a simple recipe or restaurant', 'Enjoy the experience of trying something new'],
    },
    'Seasonal vegetables': {
      'time': '20 min',
      'ingredients': ['Whatever vegetables are in season', 'Olive oil', 'Garlic', 'Salt, pepper'],
      'steps': ['Chop vegetables into similar sizes', 'Toss with olive oil and garlic', 'Roast at 200°C for 15-20 min', 'Season and serve'],
    },
    'Homemade smoothie': {
      'time': '5 min',
      'ingredients': ['1 banana', '½ cup berries', '1 cup milk or yogurt', '1 tsp honey'],
      'steps': ['Add all ingredients to blender', 'Blend until smooth', 'Pour and enjoy immediately'],
    },
  };

  // ── Suggestions per goal ──────────────────────────────────
  final Map<String, List<String>> _suggestions = {
    'Focus':       ['Blueberries + Greek yogurt', 'Salmon with quinoa', 'Dark chocolate + almonds', 'Avocado toast'],
    'Consumption': ['Water + lemon before meals', 'Vegetable soup', 'Apple instead of chips', 'Herbal tea'],
    'Activity':    ['Banana before workout', 'Chicken + sweet potato', 'Protein shake', 'Oats + peanut butter'],
    'Social':      ['Shared salad bowl', 'Hummus + veggies platter', 'Fruit skewers', 'Mixed nuts'],
    'Explore':     ['Try a new cuisine today', 'Seasonal vegetables', 'Homemade smoothie', 'Mixed nuts'],
  };

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  @override
  void dispose() {
    _mealController.dispose();
    _calorieController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _checkSubscription() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/subscription/status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(res.body);
      setState(() => _isSubscribed = body['isSubscribed'] ?? false);
      if (_isSubscribed) await _loadFoodLog();
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadFoodLog() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/food/today'),
        headers: {'Authorization': 'Bearer $token'},
      );
      setState(() => _foodLog = jsonDecode(res.body));
    } catch (_) {}
  }

  Future<void> _subscribe() async {
    setState(() => _paymentLoading = true);
    try {
      final token = await _getToken();

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/subscription/create-payment-sheet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final body = jsonDecode(res.body);
      if (res.statusCode != 200) {
        _showError(body['error'] ?? 'Payment failed');
        return;
      }

      Stripe.publishableKey = body['publishableKey'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: body['setupIntent'],
          customerId:              body['customerId'],
          merchantDisplayName:     'AI Glasses App',
          style:                   ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final confirmRes = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/subscription/confirm'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (confirmRes.statusCode == 200) {
        await _checkSubscription();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Subscribed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError('Subscription confirmation failed');
      }
    } on StripeException catch (e) {
      if (e.error.code != FailureCode.Canceled) {
        _showError('Payment failed: ${e.error.localizedMessage}');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _paymentLoading = false);
    }
  }

  Future<void> _addMeal() async {
    if (_mealController.text.isEmpty) return;
    try {
      final token = await _getToken();
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/food'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'meal_name': _mealController.text.trim(),
          'calories':  int.tryParse(_calorieController.text) ?? 0,
          'meal_type': _mealType,
        }),
      );
      _mealController.clear();
      _calorieController.clear();
      await _loadFoodLog();
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }

  Future<void> _deleteMeal(int id) async {
    try {
      final token = await _getToken();
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/food/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      await _loadFoodLog();
    } catch (_) {}
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ── Add meal sheet ────────────────────────────────────────
  void _showAddMealSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Meal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _mealController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Meal name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _calorieController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Calories (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _mealType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['breakfast', 'lunch', 'dinner', 'snack']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _mealType = v!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recipe sheet ──────────────────────────────────────────
  void _showRecipe(String name, Map<String, dynamic>? recipe) {
    if (recipe == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: Colors.teal, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Time
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.grey, size: 18),
                  const SizedBox(width: 6),
                  Text(recipe['time'],
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              const Divider(height: 32),

              // Ingredients
              const Text('Ingredients',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...(recipe['ingredients'] as List<String>).map((ing) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Colors.teal, size: 10),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ing, style: const TextStyle(fontSize: 15))),
                  ],
                ),
              )),
              const Divider(height: 32),

              // Steps
              const Text('How to make it',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...(recipe['steps'] as List<String>).asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.teal, shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(fontSize: 15, height: 1.5)),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),

              // Add to log button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _mealController.text = name;
                    _showAddMealSheet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add to my log',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  int get _totalCalories =>
      _foodLog.fold(0, (sum, item) => sum + (item['calories'] as int? ?? 0));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }
    if (!_isSubscribed) return _buildLockScreen();
    return _buildNutritionScreen();
  }

  // ── Lock screen ───────────────────────────────────────────
  Widget _buildLockScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            const Text('Nutrition Premium',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Track your eating habits and get personalized meal suggestions based on your goal.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildFeatureRow(Icons.restaurant_menu, 'Daily food log'),
            _buildFeatureRow(Icons.lightbulb_outline, 'Meal suggestions for your goal'),
            _buildFeatureRow(Icons.bar_chart, 'Calorie tracking'),
            _buildFeatureRow(Icons.repeat, 'Cancel anytime'),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal, width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('15 RON',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal)),
                  SizedBox(width: 8),
                  Text('/ month', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _paymentLoading ? null : _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _paymentLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Subscribe Now',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // ── Nutrition screen (subscribed) ─────────────────────────
  Widget _buildNutritionScreen() {
    final todaySuggestions = _suggestions['Focus']!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nutrition',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.teal, size: 32),
                  onPressed: _showAddMealSheet,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Today\'s calories', style: TextStyle(fontSize: 16)),
                  Text('$_totalCalories kcal',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Today\'s log',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_foodLog.isEmpty)
              const Text('No meals logged yet. Tap + to add one!',
                  style: TextStyle(color: Colors.grey)),
            Expanded(
              child: ListView.separated(
                itemCount: _foodLog.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  // Suggestions section at the bottom
                  if (index == _foodLog.length) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text('Meal suggestions for your goal',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...todaySuggestions.map((s) => GestureDetector(
                          onTap: () => _showRecipe(s, _recipes[s]),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.teal.shade200),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.restaurant, color: Colors.teal, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(s, style: const TextStyle(fontSize: 15)),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    color: Colors.grey, size: 14),
                              ],
                            ),
                          ),
                        )),
                      ],
                    );
                  }

                  // Food log items
                  final meal = _foodLog[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meal['meal_name'],
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w500)),
                              Text(
                                '${meal['meal_type'].toString().toUpperCase()} · ${meal['calories']} kcal',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteMeal(meal['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}