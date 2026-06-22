import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/diary_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (m) {
              if (m != null) settings.setThemeMode(m);
            },
            child: const Column(
              children: [
                RadioListTile(
                    value: ThemeMode.system, title: Text('Match system')),
                RadioListTile(value: ThemeMode.light, title: Text('Light')),
                RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('Daily reminder'),
          SwitchListTile(
            title: const Text('Remind me to journal'),
            subtitle: Text('Every day at ${settings.reminderTime.format(context)}'),
            value: settings.reminderEnabled,
            onChanged: (v) async {
              final ok = await settings.setReminderEnabled(v);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Notification permission denied.')),
                );
              }
            },
          ),
          ListTile(
            enabled: settings.reminderEnabled,
            leading: const Icon(Icons.schedule),
            title: const Text('Reminder time'),
            trailing: Text(settings.reminderTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: settings.reminderTime,
              );
              if (picked != null) await settings.setReminderTime(picked);
            },
          ),
          const Divider(),
          const _SectionHeader('Security'),
          SwitchListTile(
            title: const Text('Biometric unlock'),
            subtitle: Text(auth.biometricAvailable
                ? 'Use fingerprint or face to unlock'
                : 'No biometrics enrolled on this device'),
            value: auth.biometricEnabled,
            onChanged: auth.biometricAvailable
                ? (v) async {
                    final ok = await auth.setBiometricEnabled(v);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not change biometric setting.')),
                      );
                    }
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change passcode'),
            onTap: () => _changePasscode(context),
          ),
          const Divider(),
          const _SectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Load sample data'),
            subtitle: const Text('Reset to ~2 weeks of demo entries & tasks'),
            onTap: () async {
              final diaryProvider = context.read<DiaryProvider>();
              final taskProvider = context.read<TaskProvider>();
              final messenger = ScaffoldMessenger.of(context);
              await auth.db.seedSampleData();
              await diaryProvider.load();
              await taskProvider.load();
              messenger.showSnackBar(
                const SnackBar(content: Text('Sample data loaded.')),
              );
            },
          ),
          const Divider(),
          const AboutListTile(
            applicationName: 'MindLog',
            applicationVersion: '1.0.0',
            icon: Icon(Icons.shield_moon),
            child: Text('A private, encrypted journal, mood tracker and '
                'task planner.'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePasscode(BuildContext context) async {
    final oldC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Change passcode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pinField(oldC, 'Current passcode'),
              const SizedBox(height: 8),
              _pinField(newC, 'New passcode'),
              const SizedBox(height: 8),
              _pinField(confirmC, 'Confirm new passcode'),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (newC.text.trim().length < 4) {
                  setState(() => error = 'New passcode needs 4+ digits.');
                  return;
                }
                if (newC.text != confirmC.text) {
                  setState(() => error = 'New passcodes do not match.');
                  return;
                }
                final ok = await context
                    .read<AuthProvider>()
                    .changePasscode(oldC.text.trim(), newC.text.trim());
                if (!ok) {
                  setState(() => error = 'Current passcode is incorrect.');
                  return;
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passcode changed.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinField(TextEditingController c, String label) => TextField(
        controller: c,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 8,
        decoration: InputDecoration(labelText: label, counterText: ''),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1,
            ),
      ),
    );
  }
}
