import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/models/diary_entry.dart';
import 'package:mindlog/models/mood.dart';
import 'package:mindlog/models/task.dart';
import 'package:mindlog/services/crypto_util.dart';

void main() {
  group('Mood', () {
    test('fromScore maps to the right mood', () {
      expect(Mood.fromScore(1), Mood.awful);
      expect(Mood.fromScore(5), Mood.great);
      expect(Mood.fromScore(99), Mood.okay); // fallback
    });
  });

  group('DiaryEntry serialization', () {
    test('round-trips through a map', () {
      final entry = DiaryEntry(
        id: 7,
        title: 'Hello',
        body: 'World',
        date: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        mood: Mood.good,
        photoPath: '/tmp/a.jpg',
      );
      final restored = DiaryEntry.fromMap(entry.toMap());
      expect(restored.id, entry.id);
      expect(restored.title, entry.title);
      expect(restored.body, entry.body);
      expect(restored.date, entry.date);
      expect(restored.mood, entry.mood);
      expect(restored.photoPath, entry.photoPath);
    });
  });

  group('Task', () {
    test('toggle via copyWith sets and clears completedAt', () {
      final t = Task(title: 'x', createdAt: DateTime(2024));
      final done = t.copyWith(done: true, completedAt: DateTime(2024, 1, 2));
      expect(done.done, isTrue);
      expect(done.completedAt, isNotNull);

      final undone = done.copyWith(done: false, clearCompletedAt: true);
      expect(undone.done, isFalse);
      expect(undone.completedAt, isNull);
    });
  });

  group('CryptoUtil (PBKDF2 security layer)', () {
    test('derivation is deterministic for same password + salt', () {
      final salt = utf8.encode('static-salt-16by');
      final a = CryptoUtil.pbkdf2('1234', salt, iterations: 1000);
      final b = CryptoUtil.pbkdf2('1234', salt, iterations: 1000);
      expect(a, equals(b));
      expect(a.length, 32);
    });

    test('different passwords derive different keys', () {
      final salt = utf8.encode('static-salt-16by');
      final a = CryptoUtil.pbkdf2('1234', salt, iterations: 1000);
      final b = CryptoUtil.pbkdf2('9999', salt, iterations: 1000);
      expect(CryptoUtil.toHex(a) == CryptoUtil.toHex(b), isFalse);
    });

    test('verifier accepts matching key, rejects wrong key', () {
      final salt = utf8.encode('static-salt-16by');
      final key = CryptoUtil.pbkdf2('1234', salt, iterations: 1000);
      final wrong = CryptoUtil.pbkdf2('0000', salt, iterations: 1000);
      final v = CryptoUtil.verifier(key);
      expect(CryptoUtil.constantTimeEquals(CryptoUtil.verifier(key), v), isTrue);
      expect(
          CryptoUtil.constantTimeEquals(CryptoUtil.verifier(wrong), v), isFalse);
    });
  });
}
