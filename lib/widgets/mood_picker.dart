import 'package:flutter/material.dart';

import '../models/mood.dart';

/// Horizontal row of selectable mood faces. Each chip takes an equal share of
/// the available width (via [Expanded]) and its content scales down to fit, so
/// the row never overflows on narrow screens or at large system font sizes.
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.selected, required this.onSelected});

  final Mood? selected;
  final ValueChanged<Mood> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final mood in Mood.values)
          Expanded(
            child: _MoodChip(
              mood: mood,
              selected: mood == selected,
              onTap: () => onSelected(mood),
            ),
          ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? mood.color.withValues(alpha: 0.25) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? mood.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 2),
            // Scale the label down rather than overflow the chip.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                mood.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
