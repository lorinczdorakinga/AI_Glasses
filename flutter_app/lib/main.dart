import 'package:flutter/material.dart';
import 'package:flutter_app/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'providers/ble_provider.dart'; // A Bluetooth provider importja

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // JAVÍTVA: MultiProvider-t használunk, hogy végtelen számú providert felvehessünk
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BleProvider()), // Itt indítjuk el a BLE Providert!
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Ez a függvény ellenőrzi, hogy van-e elmentett token
  Future<bool> _checkSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // Ezt a kulcsot használtad az AuthService-ben
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      
      // FutureBuilder-t használunk, hogy megvárjuk a cache olvasását
      home: FutureBuilder<bool>(
        future: _checkSavedToken(),
        builder: (context, snapshot) {
          // Amíg olvassa a memóriát (ez nagyon gyors), mutathatunk egy töltőt
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
            );
          }
          
          // Ha van token (true), irány a Dashboard. Ha nincs, irány a Login!
          final hasToken = snapshot.data ?? false;
          if (hasToken) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}