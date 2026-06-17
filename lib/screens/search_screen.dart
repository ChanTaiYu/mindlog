import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../models/mood.dart';
import '../providers/diary_provider.dart';
import '../widgets/entry_card.dart';
import 'diary_detail_screen.dart';

/// Search entries by free text and/or by mood ("show me entries when I felt
/// anxious").
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Mood? _mood;
  late Future<List<DiaryEntry>> _results = _run();

  Future<List<DiaryEntry>> _run() => context.read<DiaryProvider>().search(
        query: _controller.text,
        moodScore: _mood?.score,
      );

  void _refresh() => setState(() => _results = _run());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search entries')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => _refresh(),
              decoration: const InputDecoration(
                hintText: 'Search title or text…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChip(
                  label: const Text('Any mood'),
                  selected: _mood == null,
                  onSelected: (_) {
                    _mood = null;
                    _refresh();
                  },
                ),
                const SizedBox(width: 8),
                for (final m in Mood.values) ...[
                  FilterChip(
                    avatar: Text(m.emoji),
                    label: Text(m.label),
                    selected: _mood == m,
                    onSelected: (_) {
                      _mood = _mood == m ? null : m;
                      _refresh();
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<DiaryEntry>>(
              future: _results,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snap.data!;
                if (entries.isEmpty) {
                  return const Center(child: Text('No matching entries.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: entries.length,
                  itemBuilder: (context, i) => EntryCard(
                    entry: entries[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiaryDetailScreen(entry: entries[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
