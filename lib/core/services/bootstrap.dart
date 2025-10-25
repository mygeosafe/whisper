import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai/services/ai_service.dart';
import '../../features/ble/services/ble_service.dart';
import '../../features/notes/infrastructure/local_note_repository.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final notes = ref.read(localNoteRepositoryProvider);
  await notes.init();
  await ref.read(bleServiceProvider).ensurePermissions();
  await ref.read(aiServiceProvider).warmup();
});
