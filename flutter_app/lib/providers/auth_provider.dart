import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  UserModel? _user;
  bool       _loading = false;
  String?    _error;

  UserModel? get user    => _user;
  bool       get loading => _loading;
  String?    get error   => _error;
  bool       get isLoggedIn => _user != null;

  Future<bool> register(String name, String email, String password) async {
    return _run(() async {
      final data  = await _service.register(name: name, email: email, password: password);
      _user       = UserModel.fromJson(data['user']);
      await _service.saveToken(data['token']);
    });
  }

  // ÚJ: Bekerült a rememberMe paraméter
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    return _run(() async {
      // Továbbadjuk a paramétert az AuthService-nek
      final data = await _service.login(
        email: email, 
        password: password, 
        rememberMe: rememberMe, 
      );
      _user = UserModel.fromJson(data['user']);
      
      // FONTOS: Kivettük a korábbi 'await _service.saveToken(data['token']);' sort!
      // Az AuthService-ed már önállóan kezeli a token mentését a rememberMe alapján.
    });
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  // Shared loading/error wrapper
  Future<bool> _run(Future<void> Function() fn) async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      await fn();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}