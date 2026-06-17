import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import 'diary_editor_screen.dart';

class DiaryDetailScreen extends StatelessWidget {
  const DiaryDetailScreen({super.key, required this.entry});

  final DiaryEntry entry;

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<DiaryProvider>().remove(entry.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMd().format(entry.date)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DiaryEditorScreen(existing: entry)),
              );
              if (context.mounted) Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Text(entry.mood.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 10),
              Text(entry.mood.label,
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(DateFormat.jm().format(entry.date),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          if (entry.title.isNotEmpty)
            Text(entry.title,
                style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (entry.photoPath != null && File(entry.photoPath!).existsSync()) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(entry.photoPath!), fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
          ],
          Text(entry.body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
