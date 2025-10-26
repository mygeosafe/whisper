import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/services/ai_service.dart';
import 'package:whispair_loopmind/features/auth/application/auth_controller.dart';
import 'package:whispair_loopmind/features/auth/domain/app_user.dart';
import 'package:whispair_loopmind/core/config/app_config.dart';
import '../../notes/application/notes_controller.dart';

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
  bool _isDeletingCloudData = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    AppUser? user;
    var isSigningOut = false;
    if (config.hasSupabaseConfig) {
      final authState = ref.watch(authStateProvider);
      final actionState = ref.watch(authActionControllerProvider);
      user = authState.value;
      isSigningOut = actionState.isLoading;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user != null)
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(user.email.isEmpty ? 'Signed in' : user.email),
              subtitle: const Text(
                'Your data is encrypted and stored in a dedicated Supabase project within the EU.',
              ),
            ),
          if (user != null) const Divider(height: 32),
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
          if (user != null) ...[
            FilledButton.icon(
              onPressed: isSigningOut
                  ? null
                  : () async {
                      try {
                        await ref.read(authActionControllerProvider.notifier).signOut();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sign-out failed: $e')),
                        );
                      }
                    },
              icon: const Icon(Icons.logout),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: isSigningOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign out securely'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _isDeletingCloudData
                  ? null
                  : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete all cloud data'),
                    content: const Text(
                      'This will permanently remove your notes and audio from Supabase and delete '
                      'the associated storage objects. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (!mounted) return;
                  setState(() => _isDeletingCloudData = true);
                  try {
                    await ref
                        .read(notesControllerProvider.notifier)
                        .deleteAllForCurrentUser();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All cloud data removed.')),
                    );
                  } catch (error, stackTrace) {
                    developer.log(
                      'Failed to erase Supabase data for the current user.',
                      name: 'SettingsPage',
                      error: error,
                      stackTrace: stackTrace,
                    );
                    if (!mounted) return;
                    final message = error is Exception
                        ? 'Could not remove your cloud data. ${error.toString()}'
                        : 'Could not remove your cloud data. Please try again.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  } finally {
                    if (!mounted) return;
                    setState(() => _isDeletingCloudData = false);
                  }
                }
              },
              icon: const Icon(Icons.delete_forever_outlined),
              label: _isDeletingCloudData
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Erasing…'),
                      ],
                    )
                  : const Text('Erase my data (GDPR)'),
            ),
            const SizedBox(height: 32),
          ],
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
