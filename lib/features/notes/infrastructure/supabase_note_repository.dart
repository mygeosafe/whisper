import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:whispair_loopmind/core/config/app_config.dart';
import 'package:whispair_loopmind/core/services/supabase.dart';
import 'package:whispair_loopmind/features/auth/application/auth_controller.dart';
import 'package:whispair_loopmind/features/notes/domain/note.dart';

import 'local_note_repository.dart';
import 'note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabaseConfig) {
    return ref.watch(localNoteRepositoryProvider);
  }
  ref.watch(authStateProvider); // rebuild when auth changes
  final client = ref.watch(supabaseClientProvider);
  return SupabaseNoteRepository(
    client: client,
    storageBucket: config.supabaseStorageBucket,
  );
});

class SupabaseNoteRepository implements NoteRepository {
  SupabaseNoteRepository({required SupabaseClient client, required String storageBucket})
      : _client = client,
        _storageBucket = storageBucket;

  final SupabaseClient _client;
  final String _storageBucket;

  @override
  Future<void> init() async {
    // Supabase does not require explicit initialisation here.
  }

  @override
  Future<List<Note>> loadAll() async {
    final userId = _requireUserId();
    final response = await _client
        .from('notes')
        .select<Map<String, dynamic>>()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    final notes = <Note>[];
    for (final row in response) {
      notes.add(_mapRowToNote(row));
    }
    return notes;
  }

  @override
  Future<Note?> getById(String id) async {
    final userId = _requireUserId();
    final response = await _client
        .from('notes')
        .select<Map<String, dynamic>>()
        .eq('owner_id', userId)
        .eq('id', id)
        .maybeSingle();
    if (response == null) {
      return null;
    }
    return _mapRowToNote(response);
  }

  @override
  Future<Note> save(Note note) async {
    final userId = _requireUserId();
    var audioPath = note.audioFile;
    if (audioPath.isNotEmpty && !_isSupabaseStorageReference(audioPath)) {
      final uploaded = await _maybeUploadAudio(audioPath, userId, note.id);
      if (uploaded != null) {
        audioPath = uploaded;
      }
    }

    final payload = {
      'id': note.id,
      'owner_id': userId,
      'created_at': note.createdAt.toIso8601String(),
      'title': note.title,
      'transcript': note.transcript,
      'summary': note.summary,
      'reflections': note.reflections,
      'audio_storage_path': audioPath,
      'tags': note.tags,
      'device_id': note.deviceId,
    };

    final response = await _client
        .from('notes')
        .upsert(payload, onConflict: 'id')
        .select<Map<String, dynamic>>()
        .single();

    return _mapRowToNote(response);
  }

  @override
  Future<void> delete(String id) async {
    final userId = _requireUserId();
    final note = await getById(id);
    if (note != null && note.audioFile.isNotEmpty) {
      final path = note.audioFile;
      try {
        await _client.storage.from(_storageBucket).remove([path]);
      } catch (error, stackTrace) {
        debugPrint('Failed to remove audio file $path: $error\n$stackTrace');
      }
    }
    await _client.from('notes').delete().eq('owner_id', userId).eq('id', id);
  }

  @override
  Future<void> deleteAllForCurrentUser() async {
    final userId = _requireUserId();
    try {
      final files = await _client.storage.from(_storageBucket).list(path: 'audio/$userId');
      if (files.isNotEmpty) {
        final paths = files.map((file) => 'audio/$userId/${file.name}').toList();
        await _client.storage.from(_storageBucket).remove(paths);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to purge storage objects for $userId: $error\n$stackTrace');
    }
    await _client.from('notes').delete().eq('owner_id', userId);
  }

  Future<String?> _maybeUploadAudio(String filePath, String userId, String noteId) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }
    final originalFileName = p.basename(file.path);
    final extension = p.extension(originalFileName);
    final uniqueFileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final storagePath = 'audio/$userId/$noteId/$uniqueFileName';
    final storage = _client.storage.from(_storageBucket);
    await storage.upload(
      storagePath,
      file,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
        contentType: 'audio/opus',
      ),
    );
    // Delete the local file to avoid retaining personal data unnecessarily.
    try {
      await file.delete();
    } catch (error) {
      debugPrint('Failed to delete local audio file after upload: $error');
    }
    return storagePath;
  }

  Note _mapRowToNote(Map<String, dynamic> data) {
    final json = {
      'id': data['id'],
      'createdAt': data['created_at'],
      'title': data['title'] ?? '',
      'transcript': data['transcript'] ?? '',
      'summary': data['summary'] ?? '',
      'reflections': List<String>.from(data['reflections'] ?? const <String>[]),
      'audio_file': data['audio_storage_path'] ?? '',
      'tags': List<String>.from(data['tags'] ?? const <String>[]),
      'device_id': data['device_id'] ?? 'unknown',
      'owner_id': data['owner_id'] ?? '',
    };
    final note = Note.fromJson(json);
    return note;
  }

  String _requireUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }
    return user.id;
  }

  bool _isSupabaseStorageReference(String path) {
    if (path.startsWith('audio/')) {
      return true;
    }
    final uri = Uri.tryParse(path);
    if (uri == null || !uri.hasScheme) {
      return false;
    }
    return path.contains('/storage/v1/object/');
  }
}
