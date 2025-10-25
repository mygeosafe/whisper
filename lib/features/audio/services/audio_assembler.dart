import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opus_dart/opus_dart.dart' as opus;
import 'package:path_provider/path_provider.dart';

final audioAssemblerProvider = Provider<AudioAssembler>((ref) {
  return AudioAssembler();
});

class AudioAssembler {
  static const _sampleRate = 8000;
  static const _channels = 1;

  Future<File> assembleWav(List<Uint8List> chunks) async {
    final bytes = Uint8List.fromList(chunks.expand((chunk) => chunk).toList());
    final buffer = BytesBuilder();
    buffer.add(_buildHeader(bytes.length));
    buffer.add(bytes);
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/note_${DateTime.now().millisecondsSinceEpoch}.wav');
    await file.writeAsBytes(buffer.toBytes(), flush: true);
    return file;
  }

  List<int> _buildHeader(int byteLength) {
    final totalDataLen = byteLength + 36;
    final byteRate = _sampleRate * _channels * 2;
    final header = BytesBuilder();
    header.add(ascii.encode('RIFF'));
    header.add(_int32ToBytes(totalDataLen));
    header.add(ascii.encode('WAVE'));
    header.add(ascii.encode('fmt '));
    header.add(_int32ToBytes(16));
    header.add(_int16ToBytes(1));
    header.add(_int16ToBytes(_channels));
    header.add(_int32ToBytes(_sampleRate));
    header.add(_int32ToBytes(byteRate));
    header.add(_int16ToBytes((_channels * 16) ~/ 8));
    header.add(_int16ToBytes(16));
    header.add(ascii.encode('data'));
    header.add(_int32ToBytes(byteLength));
    return header.toBytes();
  }

  Future<File> encodeOpus(File wavFile) async {
    final wavData = await wavFile.readAsBytes();
    final encoder = opus.OpusEncoder(
      opus.Application.voip,
      _sampleRate,
      _channels,
    );
    final frameSize = encoder.frameSize;
    final input = Uint8List.fromList(wavData.sublist(44));
    final output = BytesBuilder();
    for (var i = 0; i < input.length; i += frameSize * 2) {
      final end = (i + frameSize * 2).clamp(0, input.length).toInt();
      final frame = input.sublist(i, end);
      if (frame.length < frameSize * 2) {
        break;
      }
      final encoded = encoder.encode(frame, frameSize);
      output.add(encoded);
    }
    final directory = await getApplicationSupportDirectory();
    final opusFile = File('${directory.path}/${wavFile.uri.pathSegments.last.replaceAll('.wav', '.opus')}');
    await opusFile.writeAsBytes(output.takeBytes(), flush: true);
    return opusFile;
  }

  List<int> _int16ToBytes(int value) => Uint8List(2)
    ..buffer.asByteData().setInt16(0, value, Endian.little);

  List<int> _int32ToBytes(int value) => Uint8List(4)
    ..buffer.asByteData().setInt32(0, value, Endian.little);
}
