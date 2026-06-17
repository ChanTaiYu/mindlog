import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// First-run screen: choose and confirm a passcode that protects (and encrypts)
/// all data.
class SetupPasscodeScreen extends StatefulWidget {
  const SetupPasscodeScreen({super.key});

  @override
  State<SetupPasscodeScreen> createState() => _SetupPasscodeScreenState();
}

class _SetupPasscodeScreenState extends State<SetupPasscodeScreen> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final a = _first.text.trim();
    final b = _second.text.trim();
    if (a.length < 4) {
      setState(() => _error = 'Use at least 4 digits.');
      return;
    }
    if (a != b) {
      setState(() => _error = 'Passcodes do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await context.read<AuthProvider>().setupPasscode(a);
    if (!ok && mounted) {
      setState(() {
        _busy = false;
        _error = 'Could not create the secure store. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_moon, size: 64),
                const SizedBox(height: 16),
                Text('Welcome to MindLog',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Create a passcode. Your entries are encrypted on this device '
                  'and tied to this code.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _first,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: 'Passcode',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _second,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 8,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm passcode',
                    counterText: '',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create passcode'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
