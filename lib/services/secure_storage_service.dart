import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper over [FlutterSecureStorage] (Android Keystore / iOS Keychain
/// backed). Holds the passcode salt, a verifier, the biometric flag and — when
/// biometric unlock is enabled — the wrapped database key.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _kSalt = 'passcode_salt';
  static const _kVerifier = 'passcode_verifier';
  static const _kBiometric = 'biometric_enabled';
  static const _kDbKey = 'db_key';

  Future<String?> readSalt() => _storage.read(key: _kSalt);
  Future<void> writeSalt(String value) =>
      _storage.write(key: _kSalt, value: value);

  Future<String?> readVerifier() => _storage.read(key: _kVerifier);
  Future<void> writeVerifier(String value) =>
      _storage.write(key: _kVerifier, value: value);

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _kBiometric)) == 'true';
  Future<void> setBiometricEnabled(bool value) =>
      _storage.write(key: _kBiometric, value: value.toString());

  Future<String?> readDbKey() => _storage.read(key: _kDbKey);
  Future<void> writeDbKey(String value) =>
      _storage.write(key: _kDbKey, value: value);
  Future<void> deleteDbKey() => _storage.delete(key: _kDbKey);

  // Generic, non-secret app settings (reminder time, theme) kept in the same
  // encrypted store for simplicity.
  Future<String?> readSetting(String key) => _storage.read(key: 'set_$key');
  Future<void> writeSetting(String key, String value) =>
      _storage.write(key: 'set_$key', value: value);

  Future<void> wipe() => _storage.deleteAll();
}
