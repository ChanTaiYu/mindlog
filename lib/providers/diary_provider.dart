import 'package:flutter/foundation.dart';

import '../models/diary_entry.dart';
import '../models/mood.dart';
import '../services/database_service.dart';

/// Exposes diary entries plus the mood analytics used by the dashboard.
class DiaryProvider extends ChangeNotifier {
  DiaryProvider(this._db);

  final DatabaseService _db;

  List<DiaryEntry> _entries = [];
  List<DiaryEntry> get entries => _entries;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _entries = await _db.getEntries();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(DiaryEntry entry) async {
    await _db.insertEntry(entry);
    await load();
  }

  Future<void> update(DiaryEntry entry) async {
    await _db.updateEntry(entry);
    await load();
  }

  Future<void> remove(int id) async {
    await _db.deleteEntry(id);
    await load();
  }

  Future<List<DiaryEntry>> search({String? query, int? moodScore}) =>
      _db.getEntries(query: query, moodScore: moodScore);

  Future<List<DiaryEntry>> onThisDay() => _db.onThisDay(DateTime.now());

  Future<Map<DateTime, double>> moodTrend(int days) => _db.moodTrend(days);

  Future<Map<Mood, int>> moodDistribution() => _db.moodDistribution();
}
