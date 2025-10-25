import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/services/ai_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  static const routeName = 'settings';

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool localOnly = true;
  bool autoSync = false;
  String? apiKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: localOnly,
            onChanged: (value) => setState(() => localOnly = value),
            title: const Text('Local-only mode'),
            subtitle: const Text('Disable cloud sync and keep all data encrypted locally.'),
          ),
          SwitchListTile(
            value: autoSync,
            onChanged: (value) => setState(() => autoSync = value),
            title: const Text('Enable cloud sync (beta)'),
            subtitle: const Text('Manual uploads to Supabase/Firebase when enabled.'),
          ),
          const Divider(height: 32),
          TextField(
            decoration: const InputDecoration(
              labelText: 'OpenAI API key',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => apiKey = value,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              final key = apiKey;
              if (key != null && key.isNotEmpty) {
                ref.read(aiServiceProvider).configure(apiKey: key);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI services configured.')),
                );
              }
            },
            icon: const Icon(Icons.key),
            label: const Text('Save API key'),
          ),
        ],
      ),
    );
  }
}
