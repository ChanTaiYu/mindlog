import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Pure cryptographic helpers, kept free of plugins so they can be unit tested.
class CryptoUtil {
  CryptoUtil._();

  static const int defaultIterations = 60000;

  /// PBKDF2-HMAC-SHA256 key derivation.
  static Uint8List pbkdf2(
    String password,
    List<int> salt, {
    int iterations = defaultIterations,
    int keyLength = 32,
  }) {
    final hmac = Hmac(sha256, utf8.encode(password));
    const hLen = 32;
    final blocks = (keyLength / hLen).ceil();
    final output = BytesBuilder();

    for (var i = 1; i <= blocks; i++) {
      final block = <int>[...salt, ..._intToBytes(i)];
      var u = hmac.convert(block).bytes;
      final t = List<int>.from(u);
      for (var c = 1; c < iterations; c++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      output.add(t);
    }
    return Uint8List.fromList(output.toBytes().sublist(0, keyLength));
  }

  static String toHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static String verifier(Uint8List key) =>
      sha256.convert([...key, ...utf8.encode('mindlog-verifier')]).toString();

  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static List<int> _intToBytes(int value) => [
        (value >> 24) & 0xff,
        (value >> 16) & 0xff,
        (value >> 8) & 0xff,
        value & 0xff,
      ];
}
