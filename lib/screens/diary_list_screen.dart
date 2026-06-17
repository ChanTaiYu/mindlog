import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/diary_provider.dart';
import '../widgets/entry_card.dart';
import 'diary_detail_screen.dart';
import 'diary_editor_screen.dart';

class DiaryListScreen extends StatelessWidget {
  const DiaryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DiaryEditorScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.entries.isEmpty
              ? const _EmptyDiary()
              : RefreshIndicator(
                  onRefresh: () => provider.load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                    itemCount: provider.entries.length,
                    itemBuilder: (context, i) {
                      final entry = provider.entries[i];
                      return EntryCard(
                        entry: entry,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DiaryDetailScreen(entry: entry),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 64),
            const SizedBox(height: 16),
            Text('No entries yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Tap “New entry” to write your first journal entry.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
