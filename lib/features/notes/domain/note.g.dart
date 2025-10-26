// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String,
      transcript: json['transcript'] as String,
      summary: json['summary'] as String,
      reflections: (json['reflections'] as List<dynamic>)
          .map((dynamic e) => e as String)
          .toList(),
      audioFile: json['audio_file'] as String? ?? json['audioFile'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>).map((dynamic e) => e as String).toList(),
      deviceId: json['device_id'] as String? ?? json['deviceId'] as String? ?? 'unknown',
      ownerId: json['owner_id'] as String? ?? json['ownerId'] as String? ?? '',
    );

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'title': instance.title,
      'transcript': instance.transcript,
      'summary': instance.summary,
      'reflections': instance.reflections,
      'audio_file': instance.audioFile,
      'tags': instance.tags,
      'device_id': instance.deviceId,
      'owner_id': instance.ownerId,
    };
