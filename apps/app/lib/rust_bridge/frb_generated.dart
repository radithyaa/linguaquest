// Dolther Rust -> Dart untuk `crates/lq_bridge`.
//
// File ini adalah padanan manual dari kode yang digenerate
// `flutter_rust_bridge_codegen generate`. Tipe di bawah harus identik dengan
// struktur `#[derive(...)]` pada crate `lq_bridge` / `lq_types`.
//
// >>> Regenerasi otomatis:
// >>>   dart run flutter_rust_bridge_codegen:frontend --rust-input crates/lq_bridge/src/api.rs
//
// Nama fungsi dan tipe sengaja sama persis dengan versi generator sehingga
// hasil generate dapat menimpa file ini tanpa mengubah kode fitur.

import 'dart:async';

/// Status evaluasi jawaban (padanan `EvaluationStatus` di Rust).
enum EvaluationStatus { correct, typoWarning, incorrect }

/// Hasil evaluasi satu jawaban (padanan `AnswerEvaluation`).
class AnswerEvaluation {
  const AnswerEvaluation({
    required this.status,
    required this.canonicalAnswer,
    required this.distance,
  });

  final EvaluationStatus status;
  final String canonicalAnswer;
  final int distance;

  bool get isCorrect =>
      status == EvaluationStatus.correct || status == EvaluationStatus.typoWarning;

  factory AnswerEvaluation.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status'] as String?) {
      'correct' => EvaluationStatus.correct,
      'typo_warning' => EvaluationStatus.typoWarning,
      _ => EvaluationStatus.incorrect,
    };
    return AnswerEvaluation(
      status: status,
      canonicalAnswer: (json['canonicalAnswer'] as String?) ?? '',
      distance: (json['distance'] as num?)?.toInt() ?? -1,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status == EvaluationStatus.typoWarning
            ? 'typo_warning'
            : status.name,
        'canonicalAnswer': canonicalAnswer,
        'distance': distance,
      };
}

/// Kartu SRS (padanan `SrsCard`).
class SrsCard {
  const SrsCard({
    required this.id,
    required this.userId,
    required this.word,
    required this.translation,
    required this.stability,
    required this.difficulty,
    required this.dueAt,
    this.lastReview,
    required this.reps,
    required this.lapses,
  });

  final String id;
  final String userId;
  final String word;
  final String translation;
  final double stability;
  final double difficulty;
  final DateTime dueAt;
  final DateTime? lastReview;
  final int reps;
  final int lapses;

  factory SrsCard.fromJson(Map<String, dynamic> json) => SrsCard(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        word: json['word'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
        stability: (json['stability'] as num?)?.toDouble() ?? 0,
        difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0,
        dueAt: DateTime.tryParse(json['dueAt'] as String? ?? '') ?? DateTime.now(),
        lastReview: DateTime.tryParse((json['lastReview'] as String?) ?? ''),
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        lapses: (json['lapses'] as num?)?.toInt() ?? 0,
      );
}

/// Statistik pengguna (padanan `UserStats`).
class UserStats {
  const UserStats({
    required this.userId,
    required this.totalXp,
    required this.level,
    required this.streak,
    required this.longestStreak,
    required this.hearts,
    required this.gems,
    required this.freezesAvailable,
    required this.dailyGoalXp,
    required this.xpToday,
    required this.nextHeartSeconds,
  });

  final String userId;
  final int totalXp;
  final int level;
  final int streak;
  final int longestStreak;
  final int hearts;
  final int gems;
  final int freezesAvailable;
  final int dailyGoalXp;
  final int xpToday;
  final int nextHeartSeconds;

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        userId: json['userId'] as String? ?? '',
        totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
        hearts: (json['hearts'] as num?)?.toInt() ?? 0,
        gems: (json['gems'] as num?)?.toInt() ?? 0,
        freezesAvailable: (json['freezesAvailable'] as num?)?.toInt() ?? 0,
        dailyGoalXp: (json['dailyGoalXp'] as num?)?.toInt() ?? 0,
        xpToday: (json['xpToday'] as num?)?.toInt() ?? 0,
        nextHeartSeconds: (json['nextHeartSeconds'] as num?)?.toInt() ?? 0,
      );
}

/// Tipe rating FSRS 4.5 (1 = Again ... 4 = Easy).
enum FsrsRating { again, hard, good, easy }

extension FsrsRatingValue on FsrsRating {
  int get value => index + 1;
}

/// Kelas RustApi — pembungkus fungsi FFI dengan fallback Dart murni.
///
/// Di Android/iOS/Desktop fungsi diteruskan ke biner Rust `liblq_bridge.so`.
/// [engine] menunjuk implementasi engine yang dipilih saat runtime.
class RustApi {
  RustApi({required this.engine});

  /// Engine hasil `RustLib.init()` (lihat `rust_bridge/rust_lib.dart`).
  final BridgeEngine engine;

  /// Evaluasi jawaban: normalisasi NFKD + toleransi typo Levenshtein <= 2.
  Future<AnswerEvaluation> evaluateAnswer({
    required String input,
    required String correctAnswer,
    List<String> acceptableAnswers = const [],
  }) =>
      engine.evaluateAnswer(
        input: input,
        correctAnswer: correctAnswer,
        acceptableAnswers: acceptableAnswers,
      );

  /// Perhitungan XP: base + akurasi + combo (SRS 9.1).
  Future<int> computeXp({required double accuracy, required int maxCombo}) =>
      engine.computeXp(accuracy: accuracy, maxCombo: maxCombo);

  /// Terapkan rating FSRS pada kartu lokal.
  Future<SrsCard> applyFsrsRating({required SrsCard card, required FsrsRating rating}) =>
      engine.applyFsrsRating(card: card, rating: rating.value);

  /// Interval (hari) yang direkomendasikan untuk target retensi 90%.
  Future<double> recommendedIntervalDays(double stability) =>
      engine.recommendedIntervalDays(stability);

  /// Retrievability saat ini (0..1) berdasarkan SRS 9.3.
  Future<double> currentRetrievability({required double elapsedDays, required double stability}) =>
      engine.currentRetrievability(elapsedDays: elapsedDays, stability: stability);

  /// Normalisasi teks (fitur Utilitas UI).
  Future<String> normalize(String text) => engine.normalize(text);
}

/// Kontrak engine: dipenuhi `FFIEngine` (Rust) dan `PureDartEngine` (fallback).
abstract class BridgeEngine {
  Future<AnswerEvaluation> evaluateAnswer({
    required String input,
    required String correctAnswer,
    List<String> acceptableAnswers,
  });

  Future<int> computeXp({required double accuracy, required int maxCombo});

  Future<SrsCard> applyFsrsRating({required SrsCard card, required int rating});

  Future<double> recommendedIntervalDays(double stability);

  Future<double> currentRetrievability({
    required double elapsedDays,
    required double stability,
  });

  Future<String> normalize(String text);
}
