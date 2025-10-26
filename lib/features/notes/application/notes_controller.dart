import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/note.dart';
import 'package:whispair_loopmind/features/auth/application/auth_controller.dart';
import 'package:whispair_loopmind/core/config/app_config.dart';
import '../infrastructure/supabase_note_repository.dart';

final notesControllerProvider = AsyncNotifierProvider<NotesController, List<Note>>(
  NotesController.new,
);

class NotesController extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final config = ref.watch(appConfigProvider);
    if (!config.hasSupabaseConfig) {
      final repository = ref.read(noteRepositoryProvider);
      return repository.loadAll();
    }

    final authState = ref.watch(authStateProvider);
    if (authState.isLoading) {
      return [];
    }
    final user = authState.value;
    if (user == null) {
      return [];
    }
    final repository = ref.read(noteRepositoryProvider);
    final notes = await repository.loadAll();
    return notes;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final config = ref.read(appConfigProvider);
    final repository = ref.read(noteRepositoryProvider);
    if (!config.hasSupabaseConfig) {
      state = AsyncData(await repository.loadAll());
      return;
    }
    final authState = ref.read(authStateProvider);
    if (authState.isLoading) {
      state = const AsyncData([]);
      return;
    }
    final user = authState.value;
    if (user == null) {
      state = const AsyncData([]);
      return;
    }
    state = AsyncData(await repository.loadAll());
  }

  Future<Note> save(Note note) async {
    final repository = ref.read(noteRepositoryProvider);
    final saved = await repository.save(note);
    await refresh();
    return saved;
  }

  Future<void> delete(String id) async {
    await ref.read(noteRepositoryProvider).delete(id);
    await refresh();
  }

  Future<void> deleteAllForCurrentUser() async {
    await ref.read(noteRepositoryProvider).deleteAllForCurrentUser();
    await refresh();
  }
}

final noteProvider = FutureProvider.family<Note?, String>((ref, id) async {
  final repository = ref.read(noteRepositoryProvider);
  return repository.getById(id);
});
