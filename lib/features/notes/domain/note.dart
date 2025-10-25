import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'note.g.dart';

@JsonSerializable()
class Note {
  Note({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.transcript,
    required this.summary,
    required this.reflections,
    required this.audioFile,
    required this.tags,
    required this.deviceId,
  });

  factory Note.empty() => Note(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        title: '',
        transcript: '',
        summary: '',
        reflections: const [],
        audioFile: '',
        tags: const [],
        deviceId: 'unknown',
      );

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

  final String id;
  final DateTime createdAt;
  final String title;
  final String transcript;
  final String summary;
  final List<String> reflections;
  final String audioFile;
  final List<String> tags;
  final String deviceId;

  Map<String, dynamic> toJson() => _$NoteToJson(this);

  Note copyWith({
    String? id,
    DateTime? createdAt,
    String? title,
    String? transcript,
    String? summary,
    List<String>? reflections,
    String? audioFile,
    List<String>? tags,
    String? deviceId,
  }) {
    return Note(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      reflections: reflections ?? this.reflections,
      audioFile: audioFile ?? this.audioFile,
      tags: tags ?? this.tags,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.title == title &&
        other.transcript == transcript &&
        other.summary == summary &&
        const ListEquality<String>().equals(other.reflections, reflections) &&
        other.audioFile == audioFile &&
        const ListEquality<String>().equals(other.tags, tags) &&
        other.deviceId == deviceId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        createdAt,
        title,
        transcript,
        summary,
        const ListEquality<String>().hash(reflections),
        audioFile,
        const ListEquality<String>().hash(tags),
        deviceId,
      );
}
