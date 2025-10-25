import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../domain/note.dart';

final localNoteRepositoryProvider = Provider<LocalNoteRepository>((ref) {
  return LocalNoteRepository(
    secureStorage: const FlutterSecureStorage(),
  );
});

class LocalNoteRepository {
  LocalNoteRepository({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  static const _boxName = 'notes';
  static const _keyName = 'notes_key_v1';

  final FlutterSecureStorage _secureStorage;
  Box<Map<dynamic, dynamic>>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    final key = await _obtainEncryptionKey();
    _box = await Hive.openBox<Map<dynamic, dynamic>>(
      _boxName,
      encryptionCipher: HiveAesCipher(key),
    );
  }

  ValueListenable<Box<Map<dynamic, dynamic>>> listenable() {
    final box = _box;
    if (box == null) {
      throw StateError('Repository not initialised');
    }
    return box.listenable();
  }

  Future<List<Note>> loadAll() async {
    final box = _box;
    if (box == null) return [];
    return box.values
        .map((entry) => Note.fromJson(Map<String, dynamic>.from(entry)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Note?> getById(String id) async {
    final box = _box;
    if (box == null) return null;
    final data = box.get(id);
    if (data == null) return null;
    return Note.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> save(Note note) async {
    final box = _box;
    if (box == null) {
      throw StateError('Repository not initialised');
    }
    await box.put(note.id, note.toJson());
  }

  Future<void> delete(String id) async {
    final box = _box;
    if (box == null) {
      throw StateError('Repository not initialised');
    }
    await box.delete(id);
  }

  Future<List<int>> _obtainEncryptionKey() async {
    final encoded = await _secureStorage.read(key: _keyName);
    if (encoded != null) {
      return base64Url.decode(encoded);
    }
    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(255));
    await _secureStorage.write(key: _keyName, value: base64UrlEncode(key));
    return key;
  }

}
