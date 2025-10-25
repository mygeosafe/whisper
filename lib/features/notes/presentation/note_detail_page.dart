import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/notes_controller.dart';
import '../domain/note.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  const NoteDetailPage({super.key, required this.noteId});

  static const routeName = 'note-detail';

  final String noteId;

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _transcriptController;
  late final TextEditingController _summaryController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _transcriptController = TextEditingController();
    _summaryController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final note = await ref.read(noteProvider(widget.noteId).future);
    if (!mounted || note == null) return;
    setState(() {
      _titleController.text = note.title;
      _transcriptController.text = note.transcript;
      _summaryController.text = note.summary;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _transcriptController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncNote = ref.watch(noteProvider(widget.noteId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoopMind Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ref
                  .read(notesControllerProvider.notifier)
                  .delete(widget.noteId);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () async {
              final existing = await ref
                  .read(noteProvider(widget.noteId).future) ??
                  Note.empty().copyWith(id: widget.noteId);
              final updated = existing.copyWith(
                title: _titleController.text,
                transcript: _transcriptController.text,
                summary: _summaryController.text,
              );
              await ref.read(notesControllerProvider.notifier).save(updated);
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: asyncNote.when(
        data: (note) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _transcriptController,
                decoration: const InputDecoration(
                  labelText: 'Transcript',
                  border: OutlineInputBorder(),
                ),
                minLines: 8,
                maxLines: 18,
              ),
              const SizedBox(height: 16),
              if (note != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reflection prompts',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...note.reflections.map(
                      (prompt) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• $prompt'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Failed to load note: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
