// Controller alur utama:
//  - autentikasi (login/registrasi/tamu)
//  - kurikulum (online + cache lokal)
//  - sesi pelajaran (mulai, evaluasi via Rust, selesai, antrean offline)
//  - latihan FSRS, quest, liga, toko
//  - sinkronisasi antrean offline

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/api/api_client.dart';
import '../data/api/models.dart';
import '../data/local/local_store.dart';
import '../data/models/app_models.dart';
import '../rust_bridge/frb_generated.dart';
import 'providers.dart';

const _uuid = Uuid();

class CurriculumSnapshot {
  const CurriculumSnapshot({
    required this.curriculum,
    required this.fromCache,
    required this.courseId,
  });

  final Curriculum curriculum;
  final bool fromCache;
  final String courseId;
}

class SessionController extends StateNotifier<AsyncValue<void>> {
  SessionController(this.ref) : super(const AsyncValue.data(null)) {
    _restore();
  }

  final Ref ref;

  ApiClient get _api => ref.read(apiProvider);
  LocalStore? get _store => ref.read(localStoreProvider);
  RustApi get _rust => ref.read(rustApiProvider);

  Future<void> _restore() async {
    await _api.restoreSession();
    if (_api.isAuthenticated) {
      ref.invalidate(profileProvider);
      await refreshServerInfo();
    }
  }

  // --------------------------------------------------------------- server

  Future<void> refreshServerInfo() async {
    try {
      final health = await _api.health();
      ref.read(serverInfoProvider.notifier).state = ServerInfo(
        online: true,
        database: health['database'] as String? ?? '?',
        redis: health['redis'] as String? ?? '?',
        message: 'Terhubung ke ${_api.baseUrl}',
      );
    } on ApiException catch (error) {
      ref.read(serverInfoProvider.notifier).state = ServerInfo(
        online: false,
        database: '-',
        redis: '-',
        message: error.detail,
      );
    }
  }

  // ---------------------------------------------------------------- auth

  Future<bool> login(String email, String password) =>
      _guard(() async {
        await _api.login(email: email, password: password);
        await refreshServerInfo();
        ref.invalidate(profileProvider);
      });

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _guard(() async {
        await _api.register(email: email, password: password, displayName: displayName);
        await refreshServerInfo();
        ref.invalidate(profileProvider);
      });

  Future<bool> continueAsGuest() =>
      _guard(() async {
        await _api.guestLogin();
        await refreshServerInfo();
        ref.invalidate(profileProvider);
      });

  Future<bool> upgradeGuest({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _guard(() async {
        await _api.upgradeGuest(email: email, password: password, displayName: displayName);
        ref.invalidate(profileProvider);
      });

  Future<void> logout() async {
    await _api.logout();
    ref.read(statsProvider.notifier).state = StatsState.empty;
    ref.invalidate(profileProvider);
  }

  // ----------------------------------------------------------- kurikulum

  Future<CurriculumSnapshot> loadCurriculum() async {
    List<Course> courses = const [];
    try {
      courses = await _api.courses();
    } on ApiException catch (error) {
      if (!error.canWorkOffline) rethrow;
    }

    if (courses.isEmpty) {
      final cachedId = await _store?.lastCourseId();
      final cached = cachedId == null ? null : await _store?.readCurriculum(cachedId);
      if (cached != null) {
        return CurriculumSnapshot(curriculum: cached, fromCache: true, courseId: cached.course.id);
      }
      throw ApiException(
        statusCode: 0,
        code: 'NO_CURRICULUM',
        title: 'Kurikulum Tidak Tersedia',
        detail: 'Server belum memiliki kurikulum dan tidak ada cache lokal.',
      );
    }

    final course = courses.first;
    try {
      final curriculum = await _api.curriculum(course.id);
      await _store?.cacheCurriculum(curriculum);
      return CurriculumSnapshot(curriculum: curriculum, fromCache: false, courseId: course.id);
    } on ApiException catch (error) {
      final cached = await _store?.readCurriculum(course.id);
      if (cached != null) {
        return CurriculumSnapshot(curriculum: cached, fromCache: true, courseId: course.id);
      }
      if (!error.canWorkOffline) rethrow;
      rethrow;
    }
  }

  // -------------------------------------------------------------- sesi

  /// Memulai sesi: server menerbitkan nonce + soal. Bila offline, soal diambil
  /// dari cache kurikulum dan sesi berjalan lokal.
  Future<StartedSession> startSession(LessonNode node) async {
    try {
      final session = await _api.startSession(node.id);
      if (session.exercises.isEmpty) {
        return _offlineSessionFromNode(node);
      }
      return session;
    } on HeartsExhaustedException {
      rethrow;
    } on ApiException catch (error) {
      if (error.canWorkOffline || error.code == 'NODE_LOCKED') {
        return _offlineSessionFromNode(node);
      }
      rethrow;
    }
  }

  StartedSession _offlineSessionFromNode(LessonNode node) => StartedSession(
        sessionId: '',
        lessonId: node.lessonId ?? '',
        nodeId: node.id,
        exercises: node.exercises,
        hearts: ref.read(statsProvider).hearts,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

  /// Evaluasi jawaban secara instan memakai mesin `lq_core` (Rust/FFI).
  Future<AnswerEvaluation> evaluate(Exercise exercise, String answer) async {
    if (exercise.kind == ExerciseKind.pairMatching) {
      final submitted = answer
          .split('|')
          .where((pair) => pair.contains('='))
          .map((pair) => pair.trim().toLowerCase())
          .toSet();
      final expected = exercise.pairs
          .map((pair) => '${pair.left.trim()}=${pair.right.trim()}'.toLowerCase())
          .toSet();
      final correct = expected.isNotEmpty && expected.every(submitted.contains);
      return AnswerEvaluation(
        status: correct ? EvaluationStatus.correct : EvaluationStatus.incorrect,
        canonicalAnswer: exercise.pairs.map((p) => '${p.left}=${p.right}').join('|'),
        distance: correct ? 0 : -1,
      );
    }
    if (exercise.kind == ExerciseKind.speech) {
      // Jawaban berasal dari transkripsi STT server; bandingkan dengan engine.
      return _rust.evaluateAnswer(input: answer, correctAnswer: exercise.prompt);
    }

    // Untuk `word_bank` dan `fill_in_the_blank`, `prompt` adalah kalimat sumber
    // dan `translation` berisi kunci jawaban; server tetap menjadi validator
    // final saat sesi diselesaikan.
    final expected = switch (exercise.kind) {
      ExerciseKind.wordBank || ExerciseKind.fillInTheBlank =>
        exercise.translation ?? exercise.prompt,
      _ => exercise.prompt,
    };
    return _rust.evaluateAnswer(input: answer, correctAnswer: expected);
  }

  /// Menyelesaikan sesi. Bila server tidak terjangkau, jawaban disimpan ke
  /// antrean offline dan progress lokal diperbarui sementara.
  Future<SessionSummary> completeSession({
    required StartedSession session,
    required List<Map<String, dynamic>> answers,
    required DateTime startedAt,
  }) async {
    final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
    final clientOpId = _uuid.v4();

    try {
      final summary = await _api.completeSession(
        sessionId: session.sessionId.isEmpty ? null : session.sessionId,
        clientOpId: clientOpId,
        nodeId: session.nodeId,
        startedAt: startedAt,
        durationMs: durationMs,
        answers: answers,
      );
      ref.read(statsProvider.notifier).state = summary.stats;
      ref.invalidate(profileProvider);
      return summary;
    } on ApiException catch (error) {
      if (!error.canWorkOffline) rethrow;

      final offline = OfflineSession(
        clientOpId: clientOpId,
        nodeId: session.nodeId,
        lessonId: session.lessonId,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        durationMs: durationMs,
        answers: answers
            .map((a) => {
                  'exerciseId': a['exerciseId'].toString(),
                  'answer': a['answer'].toString(),
                })
            .toList(),
      );
      await _store?.enqueueOfflineSession(offline);
      return _localSummary(session, answers, durationMs);
    }
  }

  /// Ringkasan sementara (offline) dihitung dengan engine Rust yang sama
  /// dengan server sehingga XP konsisten ketika nanti disinkronkan.
  Future<SessionSummary> _localSummary(
    StartedSession session,
    List<Map<String, dynamic>> answers,
    int durationMs,
  ) async {
    var correct = 0;
    var combo = 0;
    var maxCombo = 0;
    for (final answer in answers) {
      final exercise = session.exercises.firstWhere(
        (e) => e.id == answer['exerciseId'],
        orElse: () => session.exercises.first,
      );
      final evaluation = await evaluate(exercise, answer['answer'].toString());
      if (evaluation.isCorrect) {
        correct++;
        combo++;
        if (combo > maxCombo) maxCombo = combo;
      } else {
        combo = 0;
      }
    }
    final total = session.exercises.length;
    final accuracy = total == 0 ? 0.0 : correct / total;
    final xp = await _rust.computeXp(accuracy: accuracy, maxCombo: maxCombo);
    final stats = ref.read(statsProvider);
    final updated = StatsState(
      totalXp: stats.totalXp + xp,
      level: stats.level,
      streak: stats.streak,
      longestStreak: stats.longestStreak,
      hearts: (stats.hearts - (total - correct)).clamp(0, 5),
      gems: stats.gems + 5 + correct ~/ 2,
      freezesAvailable: stats.freezesAvailable,
      dailyGoalXp: stats.dailyGoalXp,
      xpToday: stats.xpToday + xp,
      nextHeartSeconds: stats.nextHeartSeconds,
      heartsUpdatedAt: stats.heartsUpdatedAt,
    );
    ref.read(statsProvider.notifier).state = updated;
    return SessionSummary(
      lessonId: session.lessonId,
      nodeId: session.nodeId,
      totalQuestions: total,
      correctCount: correct,
      accuracy: accuracy,
      maxCombo: maxCombo,
      xpEarned: xp,
      gemsEarned: 5 + correct ~/ 2,
      heartsLost: total - correct,
      isMastered: accuracy >= 1,
      streak: updated.streak,
      stats: updated,
      answers: const [],
    );
  }

  // ------------------------------------------------------------- latihan

  Future<PracticeOverview> loadPractice() => _api.practice();

  Future<SrsCardState> reviewCard(String cardId, int rating) async {
    try {
      final card = await _api.reviewCard(cardId: cardId, rating: rating);
      return card;
    } on ApiException catch (error) {
      if (!error.canWorkOffline) rethrow;
      await _store?.enqueueOfflineReview(OfflineReview(
        clientOpId: _uuid.v4(),
        cardId: cardId,
        rating: rating,
        reviewedAt: DateTime.now(),
      ));
      throw ApiException(
        statusCode: 0,
        code: 'QUEUED_OFFLINE',
        title: 'Disimpan Offline',
        detail: 'Ulasan akan dikirim saat koneksi tersedia.',
      );
    }
  }

  // --------------------------------------------------------------- quest

  Future<QuestOverview> loadQuests() => _api.quests();

  Future<StatsState> claimQuest(String code) async {
    final stats = await _api.claimQuest(code);
    ref.read(statsProvider.notifier).state = stats;
    return stats;
  }

  // ---------------------------------------------------------------- liga

  Future<LeagueOverview> loadLeague() => _api.league();

  // ---------------------------------------------------------------- toko

  Future<List<ShopItem>> loadShop() => _api.shopCatalog();

  Future<StatsState> buy(String sku) async {
    try {
      final stats = await _api.buy(sku);
      ref.read(statsProvider.notifier).state = stats;
      return stats;
    } on ApiException catch (error) {
      if (error.canWorkOffline) {
        await _store?.enqueueFailedPurchase(sku);
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------- sync

  /// Kirim seluruh antrean offline lalu bersihkan yang berhasil.
  Future<int> syncPending() async {
    final store = _store;
    if (store == null || !_api.isAuthenticated) return 0;
    final ops = await store.pendingOps();
    if (ops.isEmpty) return 0;

    final sessions = ops.where((o) => o.kind == 'session').map((o) => o.payload).toList();
    final reviews = ops.where((o) => o.kind == 'review').map((o) => o.payload).toList();
    final purchases = ops.where((o) => o.kind == 'purchase').map((o) => o.payload).toList();

    final result = await _api.sync(sessions: sessions, reviews: reviews, purchases: purchases);
    final applied = (result['appliedOps'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    await store.removeOps(applied);
    if (result['stats'] is Map) {
      ref.read(statsProvider.notifier).state =
          StatsState.fromJson((result['stats'] as Map).cast<String, dynamic>());
    }
    ref.invalidate(profileProvider);
    return applied.length;
  }

  Future<int> pendingOpsCount() async => await _store?.pendingCount() ?? 0;

  // --------------------------------------------------------------- admin

  Future<Map<String, dynamic>> createUnit({
    required String title,
    required String description,
    required String summary,
    required List<String> grammarTips,
  }) =>
      _api.createUnit(
        title: title,
        description: description,
        summary: summary,
        grammarTips: grammarTips,
      );

  Future<bool> _guard(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      state = const AsyncValue.data(null);
      return true;
    } on ApiException catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return false;
    }
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, AsyncValue<void>>((ref) => SessionController(ref));

final curriculumProvider = FutureProvider<CurriculumSnapshot>((ref) async {
  final controller = ref.watch(sessionControllerProvider.notifier);
  return controller.loadCurriculum();
});

final practiceProvider = FutureProvider<PracticeOverview>((ref) {
  ref.watch(profileProvider);
  return ref.watch(sessionControllerProvider.notifier).loadPractice();
});

final questsProvider = FutureProvider<QuestOverview>((ref) {
  ref.watch(profileProvider);
  return ref.watch(sessionControllerProvider.notifier).loadQuests();
});

final leagueProvider = FutureProvider<LeagueOverview>((ref) {
  ref.watch(profileProvider);
  return ref.watch(sessionControllerProvider.notifier).loadLeague();
});

final shopProvider = FutureProvider<List<ShopItem>>((ref) {
  ref.watch(profileProvider);
  return ref.watch(sessionControllerProvider.notifier).loadShop();
});

final pendingOpsProvider = FutureProvider<int>((ref) async {
  ref.watch(profileProvider);
  return ref.watch(sessionControllerProvider.notifier).pendingOpsCount();
});

@visibleForTesting
void noop() {}
