// Implementasi engine: FFI Rust atau fallback Dart murni.
//
// Urutan pemilihan (lihat `rust_lib.dart`):
//   1. `FFIEngine`  -> memanggil `liblq_bridge.so` (satu proses biner, SRS 3.3)
//   2. `PureDartEngine` -> porting 1:1 algoritma Rust, dipakai bila library
//      native tidak tersedia (mis. tes tanpa build native / web).

import 'dart:convert';

import 'frb_generated.dart';

/// Engine yang meneruskan ke biner Rust `lq_bridge`.
class FFIEngine implements BridgeEngine {
  FFIEngine({required this.invoke});

  /// Fungsi pengirim perintah ke library native.
  /// Kontrak: nama fungsi Rust + argumen JSON -> hasil JSON.
  final Future<String> Function(String function, Map<String, dynamic> args) invoke;

  Future<Map<String, dynamic>> _call(String function, Map<String, dynamic> args) async {
    final result = await invoke(function, args);
    return jsonDecode(result) as Map<String, dynamic>;
  }

  @override
  Future<AnswerEvaluation> evaluateAnswer({
    required String input,
    required String correctAnswer,
    List<String> acceptableAnswers = const [],
  }) async =>
      AnswerEvaluation.fromJson(await _call('evaluateAnswer', {
        'input': input,
        'correctAnswer': correctAnswer,
        'acceptableAnswers': acceptableAnswers,
      }));

  @override
  Future<int> computeXp({required double accuracy, required int maxCombo}) async =>
      (await _call('computeXp', {'accuracy': accuracy, 'maxCombo': maxCombo}))['value'] as int;

  @override
  Future<SrsCard> applyFsrsRating({required SrsCard card, required int rating}) async =>
      SrsCard.fromJson(await _call('applyFsrsRating', {
        'card': {
          'id': card.id,
          'userId': card.userId,
          'word': card.word,
          'translation': card.translation,
          'stability': card.stability,
          'difficulty': card.difficulty,
          'dueAt': card.dueAt.toIso8601String(),
          'lastReview': card.lastReview?.toIso8601String(),
          'reps': card.reps,
          'lapses': card.lapses,
        },
        'rating': rating,
      }));

  @override
  Future<double> recommendedIntervalDays(double stability) async =>
      ((await _call('recommendedIntervalDays', {'stability': stability}))['value'] as num).toDouble();

  @override
  Future<double> currentRetrievability({
    required double elapsedDays,
    required double stability,
  }) async =>
      ((await _call('currentRetrievability', {
        'elapsedDays': elapsedDays,
        'stability': stability
      }))['value'] as num)
          .toDouble();

  @override
  Future<String> normalize(String text) async =>
      (await _call('normalize', {'input': text}))['value'] as String;
}

/// Porting Dart dari `lq_core` — dipakai jika library native tidak termuat.
///
/// Algoritma, konstanta, dan ambang batas identik dengan versi Rust sehingga
/// hasil evaluasi tetap konsisten (termasuk saat offline).
class PureDartEngine implements BridgeEngine {
  static const double factorF = 19.0 / 81.0;
  static const double requestedRetention = 0.90;

  @override
  Future<String> normalize(String text) async => _normalize(text);

  static String _normalize(String input) {
    final decomposed = input.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final rune in decomposed.runes) {
      final char = String.fromCharCode(rune);
      // Pembersihan tanda baca ASCII (setara `nfkd + filter(is_ascii_punctuation)`).
      if (char.codeUnitAt(0) < 0x80 && _asciiPunctuation.contains(char)) continue;
      buffer.write(char);
    }
    return buffer.toString().trim();
  }

  static const String _asciiPunctuation = r'''!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~''';

  static int levenshtein(String a, String b) {
    final aChars = a.runes.toList();
    final bChars = b.runes.toList();
    var previous = List<int>.generate(bChars.length + 1, (i) => i);
    var current = List<int>.filled(bChars.length + 1, 0);
    for (var i = 1; i <= aChars.length; i++) {
      current[0] = i;
      for (var j = 1; j <= bChars.length; j++) {
        final cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;
        current[j] = [deletion, insertion, substitution].reduce((x, y) => x < y ? x : y);
      }
      final swap = previous;
      previous = current;
      current = swap;
    }
    return previous[bChars.length];
  }

  @override
  Future<AnswerEvaluation> evaluateAnswer({
    required String input,
    required String correctAnswer,
    List<String> acceptableAnswers = const [],
  }) async {
    final normInput = _normalize(input);
    final normCorrect = _normalize(correctAnswer);

    if (normInput == normCorrect) {
      return AnswerEvaluation(
          status: EvaluationStatus.correct, canonicalAnswer: correctAnswer, distance: 0);
    }
    for (final alternative in acceptableAnswers) {
      if (normInput == _normalize(alternative)) {
        return AnswerEvaluation(
            status: EvaluationStatus.correct, canonicalAnswer: correctAnswer, distance: 0);
      }
    }
    final distance = levenshtein(normInput, normCorrect);
    if (distance > 0 && distance <= 2 && normCorrect.length >= 4) {
      return AnswerEvaluation(
          status: EvaluationStatus.typoWarning, canonicalAnswer: correctAnswer, distance: distance);
    }
    return AnswerEvaluation(
        status: EvaluationStatus.incorrect, canonicalAnswer: correctAnswer, distance: -1);
  }

  @override
  Future<int> computeXp({required double accuracy, required int maxCombo}) async {
    final accuracyBonus = accuracy >= 1.0
        ? 5
        : accuracy >= 0.9
            ? 3
            : 0;
    final comboBonus = ((maxCombo ~/ 5) * 2).clamp(0, 6);
    return 10 + accuracyBonus + comboBonus;
  }

  @override
  Future<SrsCard> applyFsrsRating({required SrsCard card, required int rating}) async {
    final now = DateTime.now();
    final elapsedDays = card.lastReview == null
        ? 0.0
        : now.difference(card.lastReview!).inMinutes / 1440.0;
    final retrievability = card.reps == 0
        ? 1.0
        : (1 + factorF * (elapsedDays / card.stability)).reciprocalSafe();

    final delta = switch (rating) {
      1 => 0.8,
      2 => 0.3,
      4 => -0.4,
      _ => 0.0,
    };
    final difficulty = (card.difficulty + delta).clamp(1.0, 10.0);

    double stability;
    var lapses = card.lapses;
    if (card.reps == 0) {
      stability = switch (rating) { 1 => 0.6, 2 => 1.2, 3 => 2.5, _ => 4.0 };
    } else {
      stability = switch (rating) {
        1 => (card.stability * 0.4).clamp(0.5, double.infinity),
        2 => card.stability * (1 + 0.15 * (1 - retrievability)),
        3 => card.stability * (1 + 0.35 * (1 - retrievability)),
        _ => card.stability * (1 + 0.60 * (1 - retrievability)) * 1.3,
      };
      if (rating == 1) lapses += 1;
      stability = stability.clamp(0.1, 3650.0);
    }

    final days = ((stability / factorF) * ((1 / requestedRetention) - 1)).clamp(1.0, 3650.0);
    return SrsCard(
      id: card.id,
      userId: card.userId,
      word: card.word,
      translation: card.translation,
      stability: stability,
      difficulty: difficulty,
      dueAt: now.add(Duration(seconds: (days * 86400).round())),
      lastReview: now,
      reps: card.reps + 1,
      lapses: lapses,
    );
  }

  @override
  Future<double> recommendedIntervalDays(double stability) async {
    if (stability <= 0) return 1.0;
    return (stability / factorF) * ((1 / requestedRetention) - 1);
  }

  @override
  Future<double> currentRetrievability({
    required double elapsedDays,
    required double stability,
  }) async {
    if (stability <= 0) return 0.0;
    return (1 + factorF * (elapsedDays / stability)).reciprocalSafe();
  }
}

extension on double {
  /// 1/x tanpa menghasilkan `Infinity` untuk nilai tak hingga.
  double reciprocalSafe() => isInfinite || this == 0 ? 0.0 : 1 / this;
}
