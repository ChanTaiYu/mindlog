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

  /// Resets the data and populates a full fortnight of varied entries and
  /// tasks, so the dashboard chart and the Insights page show rich data.
  /// Re-running it replaces the demo data rather than piling up duplicates.
  Future<void> seedSampleData() async {
    final db = _require;
    await db.delete('entries');
    await db.delete('tasks');

    final now = DateTime.now();
    DateTime dayAt(int ago, int hour) =>
        DateTime(now.year, now.month, now.day, hour)
            .subtract(Duration(days: ago));

    // Mood + content for each of the last 14 days (i = 0 → 13 days ago).
    const moods = [3, 4, 2, 5, 3, 1, 4, 3, 5, 2, 4, 3, 5, 4];
    const titles = [
      'Slow start', 'Good momentum', 'Rough patch', 'Great catch-up',
      'Steady day', 'Tough one', 'Back on track', 'Ordinary day',
      'Breakthrough', 'Recovering', 'Weekend reset', 'Quiet focus',
      'Wonderful day', 'Productive Monday',
    ];
    const bodies = [
      'Took a while to get going but got there.',
      'Crossed off a lot from my list today.',
      'Deadline stress got to me a bit.',
      'Met an old friend for coffee — felt recharged.',
      'Nothing special, kept things ticking over.',
      'Felt low and unmotivated all day.',
      'Small wins added up nicely.',
      'A normal, uneventful day.',
      'Finally solved the bug I was stuck on!',
      'Took it slow and rested in the evening.',
      'Tidied the flat and cooked properly.',
      'Deep work with no distractions.',
      'Everything just clicked today.',
      'Cleared my inbox and went for a run.',
    ];
    for (var i = 0; i < 14; i++) {
      await insertEntry(DiaryEntry(
        title: titles[i],
        body: bodies[i],
        date: dayAt(13 - i, 20),
        mood: Mood.fromScore(moods[i]),
      ));
    }
    // A couple of extra same-day entries for variety.
    await insertEntry(DiaryEntry(
        title: 'Quick note',
        body: 'A short afternoon thought.',
        date: dayAt(2, 14),
        mood: Mood.good));
    await insertEntry(DiaryEntry(
        title: 'Evening walk',
        body: 'Cleared my head outside.',
        date: dayAt(5, 19),
        mood: Mood.great));

    // Completed tasks spread across the fortnight drive the insight chart.
    const completedPerDay = [1, 2, 0, 3, 1, 1, 2, 0, 2, 1, 3, 1, 2, 2];
    for (var i = 0; i < 14; i++) {
      for (var k = 0; k < completedPerDay[i]; k++) {
        await insertTask(Task(
          title: 'Task ${i + 1}.${k + 1}',
          done: true,
          createdAt: dayAt(13 - i, 9),
          completedAt: dayAt(13 - i, 18),
        ));
      }
    }
    // A few open tasks for today.
    for (final t in ['Reply to emails', 'Plan tomorrow', 'Read 20 pages']) {
      await insertTask(
          Task(title: t, done: false, createdAt: dayAt(0, 8)));
    }
  }
}
