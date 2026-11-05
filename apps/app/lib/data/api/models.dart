// Model kontrak API (padanan DTO Rust `lq_types`).
//
// Semua `fromJson` bersifat toleran terhadap field null agar versi server
// lama/baru tetap kompatibel.

import 'package:flutter/material.dart';

enum ExerciseKind {
  multipleChoice,
  wordBank,
  typing,
  listening,
  pairMatching,
  fillInTheBlank,
  speech,
  story,
  characterWriting,
  unknown;

  static ExerciseKind parse(String? value) => switch (value) {
        'multiple_choice' => ExerciseKind.multipleChoice,
        'word_bank' => ExerciseKind.wordBank,
        'typing' => ExerciseKind.typing,
        'listening' => ExerciseKind.listening,
        'pair_matching' => ExerciseKind.pairMatching,
        'fill_in_the_blank' => ExerciseKind.fillInTheBlank,
        'speech' => ExerciseKind.speech,
        'story' => ExerciseKind.story,
        'character_writing' => ExerciseKind.characterWriting,
        _ => ExerciseKind.unknown,
      };

  String get apiValue => switch (this) {
        ExerciseKind.multipleChoice => 'multiple_choice',
        ExerciseKind.wordBank => 'word_bank',
        ExerciseKind.typing => 'typing',
        ExerciseKind.listening => 'listening',
        ExerciseKind.pairMatching => 'pair_matching',
        ExerciseKind.fillInTheBlank => 'fill_in_the_blank',
        ExerciseKind.speech => 'speech',
        ExerciseKind.story => 'story',
        ExerciseKind.characterWriting => 'character_writing',
        ExerciseKind.unknown => 'multiple_choice',
      };
}

enum NodeStatus { locked, current, completed }

class MatchingPair {
  const MatchingPair({required this.left, required this.right});

  final String left;
  final String right;

  factory MatchingPair.fromJson(Map<String, dynamic> json) => MatchingPair(
        left: json['left'] as String? ?? '',
        right: json['right'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'left': left, 'right': right};
}

class Exercise {
  const Exercise({
    required this.id,
    required this.kind,
    required this.position,
    required this.prompt,
    this.instruction,
    this.translation,
    this.audioUrl,
    this.options = const [],
    this.wordBank = const [],
    this.pairs = const [],
  });

  final String id;
  final ExerciseKind kind;
  final int position;
  final String prompt;
  final String? instruction;
  final String? translation;
  final String? audioUrl;
  final List<String> options;
  final List<String> wordBank;
  final List<MatchingPair> pairs;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String? ?? '',
        kind: ExerciseKind.parse(json['kind'] as String?),
        position: (json['position'] as num?)?.toInt() ?? 0,
        prompt: json['prompt'] as String? ?? '',
        instruction: json['instruction'] as String?,
        translation: json['translation'] as String?,
        audioUrl: json['audioUrl'] as String?,
        options: _strings(json['options']),
        wordBank: _strings(json['wordBank']),
        pairs: (json['pairs'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(MatchingPair.fromJson)
                .toList() ??
            const [],
      );

  static List<String> _strings(dynamic value) =>
      (value as List?)?.map((item) => item.toString()).toList() ?? const [];
}

class LessonNode {
  const LessonNode({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.position,
    required this.totalExercises,
    required this.status,
    required this.isMastered,
    this.lessonId,
    this.exercises = const [],
  });

  final String id;
  final String kind;
  final String title;
  final String description;
  final int position;
  final int totalExercises;
  final NodeStatus status;
  final bool isMastered;
  final String? lessonId;
  final List<Exercise> exercises;

  bool get isLocked => status == NodeStatus.locked;
  bool get isCompleted => status == NodeStatus.completed;

  factory LessonNode.fromJson(Map<String, dynamic> json) => LessonNode(
        id: json['id'] as String? ?? '',
        kind: json['kind'] as String? ?? 'lesson',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        totalExercises: (json['totalExercises'] as num?)?.toInt() ?? 0,
        status: switch (json['status'] as String?) {
          'completed' => NodeStatus.completed,
          'current' => NodeStatus.current,
          _ => NodeStatus.locked,
        },
        isMastered: json['isMastered'] as bool? ?? false,
        lessonId: json['lessonId'] as String?,
        exercises: (json['exercises'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(Exercise.fromJson)
                .toList() ??
            const [],
      );

  /// Bentuk yang dipakai kurikulum lokal (hasil caching offline).
  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'title': title,
        'description': description,
        'position': position,
        'totalExercises': totalExercises,
        'status': status.name,
        'isMastered': isMastered,
        'lessonId': lessonId,
        'exercises': exercises
            .map((e) => {
                  'id': e.id,
                  'kind': e.kind.apiValue,
                  'position': e.position,
                  'prompt': e.prompt,
                  'instruction': e.instruction,
                  'options': e.options,
                  'wordBank': e.wordBank,
                  'pairs': e.pairs.map((p) => p.toJson()).toList(),
                })
            .toList(),
      };
}

class UnitGuidebook {
  const UnitGuidebook({required this.summary, required this.grammarTips});

  final String summary;
  final List<String> grammarTips;

  factory UnitGuidebook.fromJson(Map<String, dynamic> json) => UnitGuidebook(
        summary: json['summary'] as String? ?? '',
        grammarTips: (json['grammarTips'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class LearningUnit {
  const LearningUnit({
    required this.id,
    required this.position,
    required this.title,
    required this.description,
    required this.themeColor,
    required this.guidebook,
    required this.nodes,
  });

  final String id;
  final int position;
  final String title;
  final String description;
  final String themeColor;
  final UnitGuidebook guidebook;
  final List<LessonNode> nodes;

  Color get color {
    final hex = themeColor.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return const Color(0xFF58CC02);
    return Color(0xFF000000 | value);
  }

  factory LearningUnit.fromJson(Map<String, dynamic> json) => LearningUnit(
        id: json['id'] as String? ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        themeColor: json['themeColor'] as String? ?? '#58CC02',
        guidebook: UnitGuidebook.fromJson(
            (json['guidebook'] as Map?)?.cast<String, dynamic>() ?? const {}),
        nodes: (json['nodes'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(LessonNode.fromJson)
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': position,
        'title': title,
        'description': description,
        'themeColor': themeColor,
        'guidebook': {'summary': guidebook.summary, 'grammarTips': guidebook.grammarTips},
        'nodes': nodes.map((n) => n.toJson()).toList(),
      };
}

class Course {
  const Course({
    required this.id,
    required this.fromLang,
    required this.toLang,
    required this.title,
    required this.version,
  });

  final String id;
  final String fromLang;
  final String toLang;
  final String title;
  final int version;

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String? ?? '',
        fromLang: json['fromLang'] as String? ?? 'en',
        toLang: json['toLang'] as String? ?? 'id',
        title: json['title'] as String? ?? '',
        version: (json['version'] as num?)?.toInt() ?? 1,
      );
}

class Curriculum {
  const Curriculum({required this.course, required this.units});

  final Course course;
  final List<LearningUnit> units;

  factory Curriculum.fromJson(Map<String, dynamic> json) => Curriculum(
        course: Course.fromJson((json['course'] as Map?)?.cast<String, dynamic>() ?? const {}),
        units: (json['units'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(LearningUnit.fromJson)
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'course': {
          'id': course.id,
          'fromLang': course.fromLang,
          'toLang': course.toLang,
          'title': course.title,
          'version': course.version,
        },
        'units': units.map((u) => u.toJson()).toList(),
      };
}
