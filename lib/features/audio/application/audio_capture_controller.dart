import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ble/services/ble_service.dart';
import '../services/audio_assembler.dart';

final audioCaptureControllerProvider = AsyncNotifierProvider<
    AudioCaptureController, AudioCaptureState>(AudioCaptureController.new);

enum AudioCaptureStatus { idle, recording, processing, completed, failed }

class AudioCaptureState {
  const AudioCaptureState({
    required this.status,
    this.wavPath,
    this.opusPath,
  });

  const AudioCaptureState.idle() : this(status: AudioCaptureStatus.idle);

  final AudioCaptureStatus status;
  final String? wavPath;
  final String? opusPath;

  AudioCaptureState copyWith({
    AudioCaptureStatus? status,
    String? wavPath,
    String? opusPath,
  }) {
    return AudioCaptureState(
      status: status ?? this.status,
      wavPath: wavPath ?? this.wavPath,
      opusPath: opusPath ?? this.opusPath,
    );
  }
}

class AudioCaptureController extends AsyncNotifier<AudioCaptureState> {
  final List<Uint8List> _buffer = [];
  StreamSubscription<Uint8List>? _streamSub;

  @override
  Future<AudioCaptureState> build() async {
    return const AudioCaptureState.idle();
  }

  Future<void> start() async {
    state = AsyncData(
      const AudioCaptureState(status: AudioCaptureStatus.recording),
    );
    final ble = ref.read(bleServiceProvider);
    await ble.startScan();
    await _streamSub?.cancel();
    _streamSub = ble.pcmStream.listen(_buffer.add);
  }

  Future<void> stop() async {
    state = AsyncData(
      const AudioCaptureState(status: AudioCaptureStatus.processing),
    );
    try {
      final assembler = ref.read(audioAssemblerProvider);
      final wav = await assembler.assembleWav(List<Uint8List>.from(_buffer));
      final opus = await assembler.encodeOpus(wav);
      _buffer.clear();
      state = AsyncData(
        AudioCaptureState(
          status: AudioCaptureStatus.completed,
          wavPath: wav.path,
          opusPath: opus.path,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void reset() {
    _buffer.clear();
    _streamSub?.cancel();
    state = AsyncData(
      const AudioCaptureState(status: AudioCaptureStatus.idle),
    );
  }
}
