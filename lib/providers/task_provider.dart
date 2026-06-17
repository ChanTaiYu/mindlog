import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/database_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(this._db);

  final DatabaseService _db;

  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  int get openCount => _tasks.where((t) => !t.done).length;
  int get doneCount => _tasks.where((t) => t.done).length;

  Future<void> load() async {
    _tasks = await _db.getTasks();
    notifyListeners();
  }

  Future<void> add(String title) async {
    await _db.insertTask(Task(title: title.trim(), createdAt: DateTime.now()));
    await load();
  }

  Future<void> toggle(Task task) async {
    final now = DateTime.now();
    await _db.updateTask(task.copyWith(
      done: !task.done,
      completedAt: !task.done ? now : null,
      clearCompletedAt: task.done,
    ));
    await load();
  }

  Future<void> remove(int id) async {
    await _db.deleteTask(id);
    await load();
  }

  Future<Map<DateTime, int>> completedPerDay(int days) =>
      _db.tasksCompletedPerDay(days);
}
