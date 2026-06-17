import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/diary_entry.dart';
import '../models/mood.dart';
import '../providers/diary_provider.dart';
import '../widgets/mood_picker.dart';

/// Create or edit a diary entry, including mood selection and a photo
/// attachment captured from the camera or gallery.
class DiaryEditorScreen extends StatefulWidget {
  const DiaryEditorScreen({super.key, this.existing});

  final DiaryEntry? existing;

  @override
  State<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends State<DiaryEditorScreen> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _body =
      TextEditingController(text: widget.existing?.body ?? '');
  late Mood _mood = widget.existing?.mood ?? Mood.okay;
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  String? _photoPath;
  bool _busy = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photoPath = widget.existing?.photoPath;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 75);
    if (picked == null) return;
    // Copy into app documents so it survives the picker's temp cache.
    final dir = await getApplicationDocumentsDirectory();
    final name = 'photo_${DateTime.now().millisecondsSinceEpoch}'
        '${p.extension(picked.path)}';
    final saved = await File(picked.path).copy(p.join(dir.path, name));
    setState(() => _photoPath = saved.path);
  }

  void _photoSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = DateTime(
          picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  Future<void> _save() async {
    if (_body.text.trim().isEmpty && _title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something first.')),
      );
      return;
    }
    setState(() => _busy = true);
    final provider = context.read<DiaryProvider>();
    final entry = DiaryEntry(
      id: widget.existing?.id,
      title: _title.text.trim(),
      body: _body.text.trim(),
      date: _date,
      mood: _mood,
      photoPath: _photoPath,
    );
    if (_isEdit) {
      await provider.update(entry);
    } else {
      await provider.add(entry);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit entry' : 'New entry'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.check),
            tooltip: 'Save',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('How are you feeling?',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          MoodPicker(
            selected: _mood,
            onSelected: (m) => setState(() => _mood = m),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(DateFormat.yMMMMd().format(_date)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            minLines: 6,
            maxLines: 12,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'What happened today?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          if (_photoPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(_photoPath!), height: 180, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _photoSheet,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(_photoPath == null ? 'Add photo' : 'Change photo'),
          ),
        ],
      ),
    );
  }
}
