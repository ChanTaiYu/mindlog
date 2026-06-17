import 'package:flutter/material.dart';

/// The mood scale used across MindLog. [score] (1..5) drives charts and the
/// mood–productivity insight; [emoji]/[color] drive the UI.
enum Mood {
  awful('Awful', '😣', 1, Color(0xFFE57373)),
  bad('Bad', '🙁', 2, Color(0xFFFFB74D)),
  okay('Okay', '😐', 3, Color(0xFFFFD54F)),
  good('Good', '🙂', 4, Color(0xFF81C784)),
  great('Great', '😄', 5, Color(0xFF4DB6AC));

  const Mood(this.label, this.emoji, this.score, this.color);

  final String label;
  final String emoji;
  final int score;
  final Color color;

  static Mood fromScore(int score) =>
      Mood.values.firstWhere((m) => m.score == score, orElse: () => Mood.okay);
}
