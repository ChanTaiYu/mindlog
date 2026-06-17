import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';

enum AuthStatus { loading, needsSetup, locked, unlocked }

/// Owns the lock state of the app and the shared, unlocked [DatabaseService].
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService auth,
    required DatabaseService db,
  })  : _auth = auth,
        _db = db;

  final AuthService _auth;
  final DatabaseService _db;

  DatabaseService get db => _db;

  AuthStatus _status = AuthStatus.loading;
  AuthStatus get status => _status;

  bool _biometricAvailable = false;
  bool get biometricAvailable => _biometricAvailable;

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;

  String? _currentKey;

  Future<void> init() async {
    _biometricAvailable = await _auth.canUseBiometrics();
    _biometricEnabled = await _auth.isBiometricEnabled();
    _status = await _auth.isPasscodeSet()
        ? AuthStatus.locked
        : AuthStatus.needsSetup;
    notifyListeners();
  }

  Future<bool> setupPasscode(String code) async {
    final key = await _auth.setupPasscode(code);
    final ok = await _db.open(key);
    if (ok) {
      _currentKey = key;
      _status = AuthStatus.unlocked;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> unlockWithPasscode(String code) async {
    final key = await _auth.verifyPasscode(code);
    if (key == null) return false;
    final ok = await _db.open(key);
    if (ok) {
      _currentKey = key;
      _status = AuthStatus.unlocked;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> unlockWithBiometrics() async {
    final key = await _auth.unlockWithBiometrics();
    if (key == null) return false;
    final ok = await _db.open(key);
    if (ok) {
      _currentKey = key;
      _status = AuthStatus.unlocked;
      notifyListeners();
    }
    return ok;
  }

  Future<void> lock() async {
    await _db.close();
    _currentKey = null;
    _status = AuthStatus.locked;
    notifyListeners();
  }

  Future<bool> changePasscode(String oldCode, String newCode) async {
    final newKey = await _auth.changePasscode(oldCode, newCode);
    if (newKey == null) return false;
    await _db.rekey(newKey);
    _currentKey = newKey;
    return true;
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      if (_currentKey == null || !_biometricAvailable) return false;
      // Prompt once to confirm the user can authenticate before enabling.
      await _auth.enableBiometric(_currentKey!);
    } else {
      await _auth.disableBiometric();
    }
    _biometricEnabled = enabled;
    notifyListeners();
    return true;
  }
}
