import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/notes_controller.dart';
import '../domain/note.dart';

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  static const routeName = 'timeline';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesControllerProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(notesControllerProvider.notifier).refresh(),
      child: notes.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Capture your first idea with the pendant to see it here.'),
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final note = items[index];
              return _TimelineCard(note: note);
            },
          );
        },
        error: (error, stackTrace) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Something went wrong: $error'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snippet = note.summary.isEmpty
        ? (note.transcript.length > 120
            ? '${note.transcript.substring(0, 120)}…'
            : note.transcript)
        : note.summary;
    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/timeline/note/${note.id}'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled idea' : note.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                snippet,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: note.tags.isEmpty
                    ? [
                        Chip(
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          label: const Text('Draft'),
                        ),
                      ]
                    : note.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
