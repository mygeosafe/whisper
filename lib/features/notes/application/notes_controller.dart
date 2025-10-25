import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/note.dart';
import '../infrastructure/local_note_repository.dart';

final notesControllerProvider = AsyncNotifierProvider<NotesController, List<Note>>(
  NotesController.new,
);

class NotesController extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final repository = ref.read(localNoteRepositoryProvider);
    final notes = await repository.loadAll();
    return notes;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(localNoteRepositoryProvider).loadAll());
  }

  Future<void> save(Note note) async {
    final repository = ref.read(localNoteRepositoryProvider);
    await repository.save(note);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(localNoteRepositoryProvider).delete(id);
    await refresh();
  }
}

final noteProvider = FutureProvider.family<Note?, String>((ref, id) async {
  final repository = ref.read(localNoteRepositoryProvider);
  return repository.getById(id);
});
