import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/models/diary_entry.dart';
import 'package:mindlog/models/mood.dart';
import 'package:mindlog/widgets/entry_card.dart';
import 'package:mindlog/widgets/mood_picker.dart';
import 'package:mindlog/widgets/mood_trend_chart.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  // Reset the surface after each test.
  tearDown(() => TestWidgetsFlutterBinding.instance.reset());

  group('MoodPicker', () {
    // Narrow widths combined with larger system font scales are the realistic
    // overflow trigger. The editor wraps the picker in 16px padding each side.
    for (final size in const [Size(320, 640), Size(360, 740), Size(411, 891)]) {
      for (final scale in const [1.0, 1.3, 1.6]) {
        testWidgets('selects every mood without overflow @ $size scale $scale',
            (tester) async {
          await tester.binding.setSurfaceSize(size);
          Mood selected = Mood.okay;
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StatefulBuilder(builder: (context, setState) {
                    return MoodPicker(
                      selected: selected,
                      onSelected: (m) => setState(() => selected = m),
                    );
                  }),
                ),
              ),
            ),
          ));
          for (final m in Mood.values) {
            await tester.tap(find.text(m.label));
            await tester.pumpAndSettle();
          }
        });
      }
    }
  });

  group('MoodTrendChart edge cases', () {
    testWidgets('empty data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      await tester.pumpWidget(_host(const MoodTrendChart(data: {})));
      await tester.pumpAndSettle();
    });

    testWidgets('single low-mood point', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      final today = DateTime.now();
      final day = DateTime(today.year, today.month, today.day);
      await tester.pumpWidget(_host(MoodTrendChart(data: {day: 1.0})));
      await tester.pumpAndSettle();
    });
  });

  group('EntryCard', () {
    testWidgets('renders for each mood incl. missing photo path',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      for (final m in Mood.values) {
        await tester.pumpWidget(_host(EntryCard(
          entry: DiaryEntry(
            title: 'Title ${m.label}',
            body: 'Body text',
            date: DateTime(2024, 1, 1),
            mood: m,
            photoPath: '/does/not/exist.jpg',
          ),
          onTap: () {},
        )));
        await tester.pumpAndSettle();
      }
    });
  });
}
