import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/application/ai_models.dart';
import '../../ai/services/ai_service.dart';
import '../../audio/application/audio_capture_controller.dart';
import '../../notes/application/notes_controller.dart';
import '../../notes/domain/note.dart';

final loopMindControllerProvider =
    StateNotifierProvider<LoopMindController, LoopMindState>(
  (ref) => LoopMindController(ref),
);

class LoopMindState {
  const LoopMindState({
    required this.captureState,
    this.currentNote,
    this.insights,
    this.error,
  });

  final AudioCaptureState captureState;
  final Note? currentNote;
  final LoopMindInsights? insights;
  final Object? error;

  LoopMindState copyWith({
    AudioCaptureState? captureState,
    Note? currentNote,
    LoopMindInsights? insights,
    Object? error,
  }) {
    return LoopMindState(
      captureState: captureState ?? this.captureState,
      currentNote: currentNote ?? this.currentNote,
      insights: insights ?? this.insights,
      error: error ?? this.error,
    );
  }
}

class LoopMindController extends StateNotifier<LoopMindState> {
  LoopMindController(this._ref)
      : super(LoopMindState(captureState: const AudioCaptureState.idle()));

  final Ref _ref;

  Future<void> startCapture() async {
    try {
      await _ref.read(audioCaptureControllerProvider.notifier).start();
      state = state.copyWith(
        captureState: const AudioCaptureState(status: AudioCaptureStatus.recording),
      );
    } catch (error) {
      state = state.copyWith(error: error);
    }
  }

  Future<void> stopCapture() async {
    try {
      await _ref.read(audioCaptureControllerProvider.notifier).stop();
      final captureValue =
          _ref.read(audioCaptureControllerProvider.notifier).state.value;
      if (captureValue != null) {
        state = state.copyWith(captureState: captureValue);
        if (captureValue.opusPath != null) {
          await _processAudio(captureValue);
        }
      }
    } catch (error) {
      state = state.copyWith(error: error);
    }
  }

  Future<void> _processAudio(AudioCaptureState capture) async {
    final ai = _ref.read(aiServiceProvider);
    final transcript = await ai.transcribeAudio(capture.opusPath!);
    final insights = await ai.summarise(transcript);
    final note = Note(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      title: insights.summary,
      transcript: transcript,
      summary: insights.summary,
      reflections: insights.prompts,
      audioFile: capture.opusPath!,
      tags: const ['captured'],
      deviceId: 'Whispair-LoopMind',
    );
    await _ref.read(notesControllerProvider.notifier).save(note);
    state = state.copyWith(
      currentNote: note,
      insights: insights,
    );
  }

  void reset() {
    _ref.read(audioCaptureControllerProvider.notifier).reset();
    state = LoopMindState(captureState: const AudioCaptureState.idle());
  }
}
