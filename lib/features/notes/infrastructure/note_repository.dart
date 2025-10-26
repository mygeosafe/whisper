import '../domain/note.dart';

abstract class NoteRepository {
  Future<void> init();
  Future<List<Note>> loadAll();
  Future<Note?> getById(String id);
  Future<Note> save(Note note);
  Future<void> delete(String id);
  Future<void> deleteAllForCurrentUser();
}
