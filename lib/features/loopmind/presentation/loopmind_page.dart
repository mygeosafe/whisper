import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/application/audio_capture_controller.dart';
import '../../notes/domain/note.dart';
import '../application/loopmind_controller.dart';

class LoopMindPage extends ConsumerWidget {
  const LoopMindPage({super.key});

  static const routeName = 'loopmind';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loopMindControllerProvider);
    final controller = ref.read(loopMindControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoopMind'),
        actions: [
          IconButton(
            onPressed: controller.reset,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset session',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BleStatusBanner(state.captureState.status),
            const SizedBox(height: 24),
            _CaptureControls(state.captureState.status, controller),
            const SizedBox(height: 24),
            Expanded(
              child: _LoopMindResults(
                note: state.currentNote,
                captureState: state.captureState,
              ),
            ),
            if (state.error != null)
              Text('Error: ${state.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
    );
  }
}

class _BleStatusBanner extends StatelessWidget {
  const _BleStatusBanner(this.status);

  final AudioCaptureStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = switch (status) {
      AudioCaptureStatus.recording => colorScheme.primaryContainer,
      AudioCaptureStatus.processing => colorScheme.tertiaryContainer,
      AudioCaptureStatus.completed => colorScheme.secondaryContainer,
      _ => colorScheme.surfaceVariant,
    };
    final label = switch (status) {
      AudioCaptureStatus.recording => 'Recording from pendant…',
      AudioCaptureStatus.processing => 'Processing audio locally…',
      AudioCaptureStatus.completed => 'Capture complete',
      AudioCaptureStatus.failed => 'Capture failed',
      AudioCaptureStatus.idle => 'Pendant ready',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureControls extends StatelessWidget {
  const _CaptureControls(this.status, this.controller);

  final AudioCaptureStatus status;
  final LoopMindController controller;

  @override
  Widget build(BuildContext context) {
    final isRecording = status == AudioCaptureStatus.recording;
    final isIdle = status == AudioCaptureStatus.idle;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isRecording ? controller.stopCapture : controller.startCapture,
            icon: Icon(isRecording ? Icons.stop : Icons.mic),
            label: Text(isRecording ? 'Stop capture' : 'Start capture'),
          ),
        ),
        const SizedBox(width: 12),
        if (!isIdle)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.reset,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Discard'),
            ),
          ),
      ],
    );
  }
}

class _LoopMindResults extends StatelessWidget {
  const _LoopMindResults({required this.note, required this.captureState});

  final Note? note;
  final AudioCaptureState captureState;

  @override
  Widget build(BuildContext context) {
    if (captureState.status == AudioCaptureStatus.processing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (note == null) {
      return const _Placeholder();
    }
    return ListView(
      children: [
        Text('Summary', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(note!.summary, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Text('Reflection prompts',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...note!.reflections.map(
          (prompt) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(prompt),
            ),
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none,
              size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Press “Start capture” to pull audio from your pendant. Once processed, LoopMind will surface a summary and reflective prompts to refine your idea.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
