import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/secure_storage_service.dart';

/// App preferences: theme mode and the daily reminder.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage);

  final SecureStorageService _storage;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _reminderEnabled = false;
  bool get reminderEnabled => _reminderEnabled;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay get reminderTime => _reminderTime;

  Future<void> load() async {
    final theme = await _storage.readSetting('theme');
    _themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _reminderEnabled = (await _storage.readSetting('reminder_on')) == 'true';
    final h = int.tryParse(await _storage.readSetting('reminder_h') ?? '');
    final m = int.tryParse(await _storage.readSetting('reminder_m') ?? '');
    if (h != null && m != null) {
      _reminderTime = TimeOfDay(hour: h, minute: m);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.writeSetting('theme', mode.name);
    notifyListeners();
  }

  Future<bool> setReminderEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return false;
      await NotificationService.instance
          .scheduleDailyReminder(_reminderTime.hour, _reminderTime.minute);
    } else {
      await NotificationService.instance.cancelReminder();
    }
    _reminderEnabled = enabled;
    await _storage.writeSetting('reminder_on', enabled.toString());
    notifyListeners();
    return true;
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    await _storage.writeSetting('reminder_h', time.hour.toString());
    await _storage.writeSetting('reminder_m', time.minute.toString());
    if (_reminderEnabled) {
      await NotificationService.instance
          .scheduleDailyReminder(time.hour, time.minute);
    }
    notifyListeners();
  }
}
