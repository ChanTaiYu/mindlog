import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/diary_entry.dart';
import '../models/mood.dart';
import '../models/task.dart';

/// Encrypted (SQLCipher) data access layer. The database is opened with the
/// passcode-derived key, so all journal data is encrypted at rest by default.
class DatabaseService {
  Database? _db;

  bool get isOpen => _db != null;

  /// Opens the encrypted database with [key]. Returns false if the key is wrong
  /// (SQLCipher cannot decrypt), which doubles as a passcode check.
  Future<bool> open(String key) async {
    if (_db != null) return true;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'mindlog.db');
    try {
      _db = await openDatabase(
        path,
        password: key,
        version: 1,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
      );
      // Force a read so a bad key surfaces immediately.
      await _db!.rawQuery('SELECT count(*) FROM sqlite_master');
      return true;
    } catch (_) {
      _db = null;
      return false;
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Re-encrypts the open database with a new key (used on passcode change).
  Future<void> rekey(String newKey) async {
    await _db?.rawQuery("PRAGMA rekey = '$newKey'");
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        date INTEGER NOT NULL,
        mood INTEGER NOT NULL,
        photo_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');
    await db.execute('CREATE INDEX idx_entries_date ON entries(date)');
    await db.execute('CREATE INDEX idx_entries_mood ON entries(mood)');
  }

  Database get _require {
    final db = _db;
    if (db == null) {
      throw StateError('Database is locked. Unlock the app first.');
    }
    return db;
  }

  // --- Diary entries ------------------------------------------------------

  Future<List<DiaryEntry>> getEntries({String? query, int? moodScore}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (query != null && query.trim().isNotEmpty) {
      where.add('(title LIKE ? OR body LIKE ?)');
      args..add('%$query%')..add('%$query%');
    }
    if (moodScore != null) {
      where.add('mood = ?');
      args.add(moodScore);
    }
    final rows = await _require.query(
      'entries',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
    );
    return rows.map(DiaryEntry.fromMap).toList();
  }

  /// Entries created on the same month/day as [day] in previous years.
  Future<List<DiaryEntry>> onThisDay(DateTime day) async {
    final rows = await _require.query('entries', orderBy: 'date DESC');
    return rows
        .map(DiaryEntry.fromMap)
        .where((e) =>
            e.date.month == day.month &&
            e.date.day == day.day &&
            e.date.year != day.year)
        .toList();
  }

  Future<int> insertEntry(DiaryEntry e) =>
      _require.insert('entries', e.toMap());

  Future<int> updateEntry(DiaryEntry e) => _require
      .update('entries', e.toMap(), where: 'id = ?', whereArgs: [e.id]);

  Future<int> deleteEntry(int id) =>
      _require.delete('entries', where: 'id = ?', whereArgs: [id]);

  /// Average mood score per day for the last [days] days (for the trend chart).
  Future<Map<DateTime, double>> moodTrend(int days) async {
    final since = DateTime.now()
        .subtract(Duration(days: days - 1))
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final rows = await _require.query(
      'entries',
      where: 'date >= ?',
      whereArgs: [since.millisecondsSinceEpoch],
    );
    final byDay = <DateTime, List<int>>{};
    for (final r in rows.map(DiaryEntry.fromMap)) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      byDay.putIfAbsent(d, () => []).add(r.mood.score);
    }
    return {
      for (final e in byDay.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };
  }

  /// Count of entries per mood (for the dashboard distribution).
  Future<Map<Mood, int>> moodDistribution() async {
    final rows = await _require.rawQuery(
      'SELECT mood, COUNT(*) c FROM entries GROUP BY mood',
    );
    return {
      for (final r in rows)
        Mood.fromScore(r['mood'] as int): r['c'] as int,
    };
  }

  // --- Tasks --------------------------------------------------------------

  Future<List<Task>> getTasks() async {
    final rows = await _require
        .query('tasks', orderBy: 'done ASC, created_at DESC');
    return rows.map(Task.fromMap).toList();
  }

  Future<int> insertTask(Task t) => _require.insert('tasks', t.toMap());

  Future<int> updateTask(Task t) =>
      _require.update('tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);

  Future<int> deleteTask(int id) =>
      _require.delete('tasks', where: 'id = ?', whereArgs: [id]);

  /// Tasks completed per day for the last [days] days (for the insight chart).
  Future<Map<DateTime, int>> tasksCompletedPerDay(int days) async {
    final since = DateTime.now()
        .subtract(Duration(days: days - 1))
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final rows = await _require.query(
      'tasks',
      where: 'completed_at IS NOT NULL AND completed_at >= ?',
      whereArgs: [since.millisecondsSinceEpoch],
    );
    final byDay = <DateTime, int>{};
    for (final t in rows.map(Task.fromMap)) {
      final c = t.completedAt!;
      final d = DateTime(c.year, c.month, c.day);
      byDay[d] = (byDay[d] ?? 0) + 1;
    }
    return byDay;
  }

  // --- Test data ----------------------------------------------------------

  Future<int> entryCount() async {
    final r = await _require.rawQuery('SELECT COUNT(*) c FROM entries');
    return r.first['c'] as int;
  }

  /// Populates a fortnight of varied entries and tasks for demos/VIVA.
  Future<void> seedSampleData() async {
    final now = DateTime.now();
    final samples = <(int, Mood, String, String)>[
      (0, Mood.good, 'Productive Monday', 'Cleared my inbox and went for a run.'),
      (1, Mood.okay, 'Steady day', 'Nothing special, kept things ticking over.'),
      (2, Mood.great, 'Great catch-up', 'Met an old friend for coffee — felt recharged.'),
      (3, Mood.bad, 'Rough patch', 'Deadline stress got to me a bit today.'),
      (4, Mood.okay, 'Recovering', 'Took it slow and rested in the evening.'),
      (6, Mood.good, 'Weekend reset', 'Tidied the flat and cooked properly.'),
      (8, Mood.great, 'Breakthrough', 'Finally solved the bug I was stuck on!'),
      (10, Mood.awful, 'Tough one', 'Felt low and unmotivated all day.'),
      (12, Mood.good, 'Back on track', 'Small wins added up nicely.'),
    ];
    for (final (ago, mood, title, body) in samples) {
      final d = now.subtract(Duration(days: ago, hours: 3));
      await insertEntry(DiaryEntry(
          title: title, body: body, date: d, mood: mood));
    }
    final tasks = <(int, bool, int)>[
      // (createdDaysAgo, done, completedDaysAgo)
      (0, false, 0),
      (1, true, 0),
      (2, true, 2),
      (3, true, 3),
      (8, true, 8),
      (10, true, 10),
    ];
    for (final (created, done, completedAgo) in tasks) {
      await insertTask(Task(
        title: 'Sample task ($created d ago)',
        done: done,
        createdAt: now.subtract(Duration(days: created)),
        completedAt:
            done ? now.subtract(Duration(days: completedAgo, hours: 2)) : null,
      ));
    }
  }
}
