import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:local_auth/local_auth.dart';

import 'crypto_util.dart';
import 'secure_storage_service.dart';

/// Result of a successful unlock: the hex SQLCipher key used to open the
/// encrypted database.
typedef DbKey = String;

/// Implements MindLog's security policy (LO3):
///  * passcode → 256-bit key via PBKDF2-HMAC-SHA256 with a random salt,
///  * the derived key is the SQLCipher key (data encrypted at rest by default),
///  * optional biometric unlock releases a Keystore-stored copy of that key.
class AuthService {
  AuthService({SecureStorageService? storage, LocalAuthentication? localAuth})
      : _storage = storage ?? SecureStorageService(),
        _localAuth = localAuth ?? LocalAuthentication();

  final SecureStorageService _storage;
  final LocalAuthentication _localAuth;

  Future<bool> isPasscodeSet() async =>
      (await _storage.readSalt()) != null &&
      (await _storage.readVerifier()) != null;

  /// Creates a brand new passcode, returning the freshly derived db key.
  Future<DbKey> setupPasscode(String passcode) async {
    final salt = _randomBytes(16);
    final key = CryptoUtil.pbkdf2(passcode, salt);
    await _storage.writeSalt(base64Encode(salt));
    await _storage.writeVerifier(CryptoUtil.verifier(key));
    return CryptoUtil.toHex(key);
  }

  /// Verifies [passcode] against the stored verifier. Returns the db key on
  /// success, or null on a wrong passcode.
  Future<DbKey?> verifyPasscode(String passcode) async {
    final saltB64 = await _storage.readSalt();
    final stored = await _storage.readVerifier();
    if (saltB64 == null || stored == null) return null;
    final key = CryptoUtil.pbkdf2(passcode, base64Decode(saltB64));
    if (CryptoUtil.constantTimeEquals(CryptoUtil.verifier(key), stored)) {
      return CryptoUtil.toHex(key);
    }
    return null;
  }

  /// Re-keys: validates the old passcode and writes a new salt/verifier.
  /// Returns the new db key (the same key the encrypted DB must be re-keyed to).
  Future<DbKey?> changePasscode(String oldCode, String newCode) async {
    if (await verifyPasscode(oldCode) == null) return null;
    final newKey = await setupPasscode(newCode);
    if (await isBiometricEnabled()) {
      await enableBiometric(newKey);
    }
    return newKey;
  }

  // --- Biometrics ---------------------------------------------------------

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() => _storage.isBiometricEnabled();

  /// Stores the db key behind the OS keystore and flags biometric unlock on.
  Future<void> enableBiometric(DbKey key) async {
    await _storage.writeDbKey(key);
    await _storage.setBiometricEnabled(true);
  }

  Future<void> disableBiometric() async {
    await _storage.deleteDbKey();
    await _storage.setBiometricEnabled(false);
  }

  /// Prompts for biometrics and, on success, returns the stored db key.
  Future<DbKey?> unlockWithBiometrics() async {
    if (!await isBiometricEnabled()) return null;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock MindLog',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (!ok) return null;
      return _storage.readDbKey();
    } catch (_) {
      return null;
    }
  }

  // --- Crypto helpers -----------------------------------------------------

  Uint8List _randomBytes(int n) {
    final rnd = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => rnd.nextInt(256)));
  }
}
