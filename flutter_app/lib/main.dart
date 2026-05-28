import 'package:flutter/material.dart';
import 'package:flutter_app/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'providers/ble_provider.dart';
import 'providers/data_provider.dart'; // NEW

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Create both providers up front so we can wire them together.
  final bleProvider  = BleProvider();
  final dataProvider = DataProvider();

  // Inject DataProvider into BleImageService so it can call onImageUploaded()
  // after each successful camera image upload.
  bleProvider.init(dataProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: bleProvider),
        ChangeNotifierProvider.value(value: dataProvider), // NEW
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: FutureBuilder<bool>(
        future: _checkSavedToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
            );
          }
          return (snapshot.data ?? false) ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}