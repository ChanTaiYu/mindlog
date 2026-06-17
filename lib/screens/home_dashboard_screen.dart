import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/entry_card.dart';
import '../widgets/mood_trend_chart.dart';
import '../widgets/quote_card.dart';
import 'diary_detail_screen.dart';
import 'diary_editor_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryProvider>();
    final tasks = context.watch<TaskProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        await diary.load();
        await tasks.load();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(_greeting(),
              style: Theme.of(context).textTheme.headlineSmall),
          Text(DateFormat.yMMMMEEEEd().format(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          const QuoteCard(),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(
                label: 'Entries',
                value: diary.entries.length.toString(),
                icon: Icons.book,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Open tasks',
                value: tasks.openCount.toString(),
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mood this week',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FutureBuilder<Map<DateTime, double>>(
                    // keyed by entry count so it refreshes after edits
                    key: ValueKey('trend_${diary.entries.length}'),
                    future: diary.moodTrend(7),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return MoodTrendChart(data: snap.data!, days: 7);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<DiaryEntry>>(
            key: ValueKey('otd_${diary.entries.length}'),
            future: diary.onThisDay(),
            builder: (context, snap) {
              final entries = snap.data ?? const [];
              if (entries.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, size: 20),
                      const SizedBox(width: 8),
                      Text('On this day',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final e in entries)
                    EntryCard(
                      entry: e,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DiaryDetailScreen(entry: e)),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiaryEditorScreen()),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Write a new entry'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
