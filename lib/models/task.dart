/// A to-do item. Persisted in the encrypted `tasks` table. [completedAt] is set
/// when the task is checked off and is used by the mood–productivity insight.
class Task {
  final int? id;
  final String title;
  final bool done;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({
    this.id,
    required this.title,
    this.done = false,
    required this.createdAt,
    this.completedAt,
  });

  Task copyWith({
    int? id,
    String? title,
    bool? done,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'done': done ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
      };

  factory Task.fromMap(Map<String, Object?> map) => Task(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        done: (map['done'] as int? ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        completedAt: map['completed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int),
      );
}
