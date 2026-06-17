import 'mood.dart';

/// A single journal entry. Persisted in the encrypted `entries` table.
class DiaryEntry {
  final int? id;
  final String title;
  final String body;
  final DateTime date;
  final Mood mood;

  /// Absolute path to an optional attached photo on the device.
  final String? photoPath;

  const DiaryEntry({
    this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.mood,
    this.photoPath,
  });

  DiaryEntry copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? date,
    Mood? mood,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'body': body,
        'date': date.millisecondsSinceEpoch,
        'mood': mood.score,
        'photo_path': photoPath,
      };

  factory DiaryEntry.fromMap(Map<String, Object?> map) => DiaryEntry(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        mood: Mood.fromScore(map['mood'] as int? ?? 3),
        photoPath: map['photo_path'] as String?,
      );
}
