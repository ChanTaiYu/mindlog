import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/mood.dart';
import '../providers/diary_provider.dart';
import '../providers/task_provider.dart';

/// Combines mood (from diary) and tasks completed to surface how mood relates
/// to productivity — MindLog's signature insight.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const _days = 14;

  late Future<_InsightData> _future = _load();

  Future<_InsightData> _load() async {
    final diary = context.read<DiaryProvider>();
    final tasks = context.read<TaskProvider>();
    final mood = await diary.moodTrend(_days);
    final done = await tasks.completedPerDay(_days);
    return _InsightData(mood: mood, done: done);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when entries/tasks change.
    context.watch<DiaryProvider>();
    context.watch<TaskProvider>();
    _future = _load();

    return FutureBuilder<_InsightData>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Mood & productivity',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Last $_days days',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline),
                    const SizedBox(width: 12),
                    Expanded(child: Text(data.insightText())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tasks completed per day',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Bar colour reflects that day’s average mood.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: _ProductivityChart(data: data, days: _days)),
            const SizedBox(height: 16),
            const _Legend(),
          ],
        );
      },
    );
  }
}

class _InsightData {
  _InsightData({required this.mood, required this.done});

  final Map<DateTime, double> mood; // day → avg mood score
  final Map<DateTime, int> done; // day → tasks completed

  String insightText() {
    final goodDays = <int>[];
    final otherDays = <int>[];
    mood.forEach((day, score) {
      final tasks = done[day] ?? 0;
      if (score >= 4) {
        goodDays.add(tasks);
      } else {
        otherDays.add(tasks);
      }
    });
    if (goodDays.isEmpty || otherDays.isEmpty) {
      return 'Keep logging your mood and checking off tasks — once you have a '
          'mix of good and tougher days, MindLog will show how they connect.';
    }
    final goodAvg = goodDays.reduce((a, b) => a + b) / goodDays.length;
    final otherAvg = otherDays.reduce((a, b) => a + b) / otherDays.length;
    if (goodAvg > otherAvg) {
      return 'On your better-mood days you complete about '
          '${goodAvg.toStringAsFixed(1)} tasks, versus '
          '${otherAvg.toStringAsFixed(1)} on tougher days — a good mood and '
          'getting things done go hand in hand for you.';
    } else if (otherAvg > goodAvg) {
      return 'Interestingly, you finish more tasks on tougher days '
          '(${otherAvg.toStringAsFixed(1)}) than on good ones '
          '(${goodAvg.toStringAsFixed(1)}). Productivity might be your way of '
          'lifting your mood.';
    }
    return 'Your productivity stays steady regardless of mood — nice '
        'consistency!';
  }
}

class _ProductivityChart extends StatelessWidget {
  const _ProductivityChart({required this.data, required this.days});

  final _InsightData data;
  final int days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));

    var maxY = 1.0;
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      final count = (data.done[key] ?? 0).toDouble();
      if (count > maxY) maxY = count;
      final moodScore = data.mood[key];
      final color = moodScore != null
          ? Mood.fromScore(moodScore.round()).color
          : scheme.outlineVariant;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: color,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY + 1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 24,
              getTitlesWidget: (v, _) =>
                  Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 20,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= days) return const SizedBox.shrink();
                if (i % 2 != 0) return const SizedBox.shrink();
                final day = start.add(Duration(days: i));
                return Text(DateFormat.Md().format(day),
                    style: const TextStyle(fontSize: 9));
              },
            ),
          ),
        ),
        barGroups: groups,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final m in Mood.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: m.color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 4),
              Text(m.label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}
