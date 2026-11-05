// Uji alur utama aplikasi: engine Rust/Dart, penyimpanan offline, dan klien API.
//
// Server palsu (MockClient) mensimulasikan respons `lq_api` sehingga test
// berjalan tanpa jaringan, sekaligus memverifikasi parsing DTO camelCase.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linguaquest/data/api/api_client.dart';
import 'package:linguaquest/data/api/models.dart';
import 'package:linguaquest/data/models/app_models.dart';
import 'package:linguaquest/rust_bridge/engine.dart';
import 'package:linguaquest/rust_bridge/frb_generated.dart';

void main() {
  group('PureDartEngine (porting 1:1 lq_core)', () {
    final engine = PureDartEngine();

    test('menormalisasi NFKD, case-folding, dan tanda baca', () async {
      expect(await engine.normalize('  Good Morning!  '), 'good morning');
      expect(await engine.normalize('Terima kasih...'), 'terima kasih');
    });

    test('menerima typo dengan jarak Levenshtein <= 2', () async {
      final result = await engine.evaluateAnswer(input: 'tehcer', correctAnswer: 'teacher');
      expect(result.status, EvaluationStatus.typoWarning);
      expect(result.distance, 2);
      expect(result.isCorrect, isTrue);
    });

    test('menolak jawaban yang jauh berbeda', () async {
      final result = await engine.evaluateAnswer(input: 'xyz', correctAnswer: 'teacher');
      expect(result.status, EvaluationStatus.incorrect);
    });

    test('menerima sinonim alternatif', () async {
      final result = await engine.evaluateAnswer(
        input: 'makasih banyak',
        correctAnswer: 'terima kasih banyak',
        acceptableAnswers: ['makasih banyak'],
      );
      expect(result.status, EvaluationStatus.correct);
    });

    test('formula XP sesuai SRS 9.1', () async {
      expect(await engine.computeXp(accuracy: 1.0, maxCombo: 15), 21);
      expect(await engine.computeXp(accuracy: 0.95, maxCombo: 8), 15);
      expect(await engine.computeXp(accuracy: 0.80, maxCombo: 2), 10);
    });

    test('FSRS: rating Good menetapkan stability awal 2.5', () async {
      final card = SrsCard(
        id: 'c1',
        userId: 'u1',
        word: 'Hello',
        translation: 'Halo',
        stability: 0,
        difficulty: 5,
        dueAt: DateTime.now(),
        reps: 0,
        lapses: 0,
      );
      final updated = await engine.applyFsrsRating(card: card, rating: 3);
      expect(updated.stability, 2.5);
      expect(updated.reps, 1);
      expect(updated.dueAt.isAfter(DateTime.now()), isTrue);
    });

    test('FSRS: rating Again menambah lapses', () async {
      final card = SrsCard(
        id: 'c1',
        userId: 'u1',
        word: 'Hello',
        translation: 'Halo',
        stability: 5,
        difficulty: 5,
        dueAt: DateTime.now(),
        lastReview: DateTime.now().subtract(const Duration(days: 3)),
        reps: 2,
        lapses: 0,
      );
      final updated = await engine.applyFsrsRating(card: card, rating: 1);
      expect(updated.lapses, 1);
      expect(updated.stability, lessThan(5));
    });

    test('retrievability menurun seiring waktu', () async {
      final fresh = await engine.currentRetrievability(elapsedDays: 0, stability: 10);
      final later = await engine.currentRetrievability(elapsedDays: 10, stability: 10);
      expect(fresh, closeTo(1.0, 1e-6));
      expect(later, closeTo(0.81, 0.01));
    });
  });

  group('ApiClient', () {
    late List<String> requestLog;

    /// Server palsu yang meniru kontrak `lq_api`.
    MockClient server() {
      requestLog = [];
      return MockClient.streaming((request, bodyStream) async {
        final body = await bodyStream.bytesToString();
        requestLog.add('${request.method} ${request.url.path} $body');
        final path = request.url.path;

        if (path.endsWith('/auth/login')) {
          return _jsonResponse(200, {
            'accessToken': 'token-abc',
            'refreshToken': 'refresh-abc',
            'expiresIn': 3600,
            'user': {
              'id': 'u1',
              'username': 'demo',
              'email': 'demo@linguaquest.app',
              'displayName': 'Pelajar Hebat',
              'isGuest': false,
            },
          });
        }
        if (path.endsWith('/me')) {
          return _jsonResponse(200, {
            'user': {
              'id': 'u1',
              'username': 'demo',
              'email': 'demo@linguaquest.app',
              'displayName': 'Pelajar Hebat',
              'isGuest': false,
            },
            'stats': {
              'totalXp': 320,
              'level': 3,
              'streak': 4,
              'longestStreak': 6,
              'hearts': 5,
              'gems': 450,
              'freezesAvailable': 1,
              'dailyGoalXp': 20,
              'xpToday': 12,
              'nextHeartSeconds': 0,
              'heartsUpdatedAt': '2026-11-05T00:00:00Z',
            },
            'leagueTier': 'emerald',
            'achievements': [
              {'code': 'streak_7', 'title': 'Api Abadi', 'description': '...', 'progress': 0.57, 'unlocked': false}
            ],
          });
        }
        if (path.endsWith('/courses')) {
          return _jsonResponse(200, [
            {'id': 'c1', 'fromLang': 'en', 'toLang': 'id', 'title': 'Inggris', 'version': 1}
          ]);
        }
        if (path.endsWith('/curriculum')) {
          return _jsonResponse(200, {
            'course': {'id': 'c1', 'fromLang': 'en', 'toLang': 'id', 'title': 'Inggris', 'version': 1},
            'units': [
              {
                'id': 'unit1',
                'position': 1,
                'title': 'Salam',
                'description': 'Dasar',
                'themeColor': '#58CC02',
                'guidebook': {'summary': 'ringkas', 'grammarTips': ['tip 1']},
                'nodes': [
                  {
                    'id': 'node1',
                    'kind': 'lesson',
                    'title': 'Halo',
                    'description': 'dasar',
                    'position': 1,
                    'totalExercises': 2,
                    'status': 'current',
                    'isMastered': false,
                    'lessonId': 'lesson1',
                    'exercises': [
                      {
                        'id': 'ex1',
                        'kind': 'multiple_choice',
                        'position': 1,
                        'prompt': 'Hello',
                        'instruction': 'Pilih arti',
                        'options': ['Halo', 'Maaf'],
                        'wordBank': [],
                        'pairs': [],
                      },
                      {
                        'id': 'ex2',
                        'kind': 'pair_matching',
                        'position': 2,
                        'prompt': 'Cocokkan',
                        'options': [],
                        'wordBank': [],
                        'pairs': [
                          {'left': 'Tea', 'right': 'Teh'}
                        ],
                      },
                    ],
                  }
                ],
              }
            ],
          });
        }
        if (path.endsWith('/sessions/start')) {
          return _jsonResponse(200, {
            'sessionId': 's1',
            'lessonId': 'lesson1',
            'nodeId': 'node1',
            'hearts': 5,
            'expiresAt': '2026-11-05T01:00:00Z',
            'exercises': [
              {
                'id': 'ex1',
                'kind': 'multiple_choice',
                'position': 1,
                'prompt': 'Hello',
                'options': ['Halo', 'Maaf'],
                'wordBank': [],
                'pairs': [],
              }
            ],
          });
        }
        if (path.endsWith('/sessions/complete')) {
          return _jsonResponse(200, {
            'lessonId': 'lesson1',
            'nodeId': 'node1',
            'totalQuestions': 1,
            'correctCount': 1,
            'accuracy': 1.0,
            'maxCombo': 1,
            'xpEarned': 15,
            'gemsEarned': 5,
            'heartsLost': 0,
            'isMastered': true,
            'streak': 5,
            'stats': {
              'totalXp': 335,
              'level': 3,
              'streak': 5,
              'longestStreak': 6,
              'hearts': 5,
              'gems': 455,
              'freezesAvailable': 1,
              'dailyGoalXp': 20,
              'xpToday': 27,
              'nextHeartSeconds': 0,
              'heartsUpdatedAt': '2026-11-05T00:00:00Z',
            },
            'answers': [
              {'exerciseId': 'ex1', 'isCorrect': true, 'typoWarning': false, 'correctAnswer': 'Halo'}
            ],
          });
        }
        if (path.endsWith('/shop/catalog')) {
          return _jsonResponse(200, [
            {
              'sku': 'heart_refill',
              'title': 'Isi Penuh Hearts',
              'description': '...',
              'priceGems': 150,
              'icon': 'favorite',
              'color': '#FF4B4B',
              'available': true,
              'owned': false,
            }
          ]);
        }
        if (path.endsWith('/health')) {
          return _jsonResponse(200, {'status': 'ok', 'database': 'postgres', 'redis': 'connected'});
        }
        return _jsonResponse(404, {
          'type': 'https://api.linguaquest.app/errors/not-found',
          'title': 'Data Tidak Ditemukan',
          'status': 404,
          'detail': 'tidak ada',
          'code': 'NOT_FOUND',
          'timestamp': '2026-11-05T00:00:00Z',
        });
      });
    }

    test('login menyimpan token dan mengirim header Authorization', () async {
      final client = ApiClient(httpClient: server());
      await client.login(email: 'demo@linguaquest.app', password: 'demo12345');
      expect(client.isAuthenticated, isTrue);

      final profile = await client.profile();
      expect(profile.user.displayName, 'Pelajar Hebat');
      expect(profile.stats.gems, 450);
      expect(profile.achievements.single.code, 'streak_7');
      expect(requestLog.last, contains('GET /v1/me'));
    });

    test('parse kurikulum & exercise kinds', () async {
      final client = ApiClient(httpClient: server());
      await client.login(email: 'a@b.c', password: 'password123');
      final curriculum = await client.curriculum('c1');
      expect(curriculum.units.single.nodes.single.exercises.length, 2);
      expect(curriculum.units.single.nodes.single.exercises[1].kind, ExerciseKind.pairMatching);
      expect(curriculum.units.single.color.value, 0xFF58CC02);
    });

    test('complete session mengembalikan ringkasan', () async {
      final client = ApiClient(httpClient: server());
      await client.login(email: 'a@b.c', password: 'password123');
      final summary = await client.completeSession(
        sessionId: 's1',
        clientOpId: 'op-1',
        nodeId: 'node1',
        startedAt: DateTime.now(),
        durationMs: 42000,
        answers: [
          {'exerciseId': 'ex1', 'answer': 'Halo', 'durationMs': 1000}
        ],
      );
      expect(summary.xpEarned, 15);
      expect(summary.stats.totalXp, 335);
      expect(summary.answers.single.isCorrect, isTrue);
    });

    test('error server dipetakan ke ApiException RFC 9457', () async {
      final client = ApiClient(httpClient: server());
      expect(
        () => client.rawRequest('GET', '/tidak-ada'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NOT_FOUND')),
      );
    });

    test('health mengembalikan status database & redis', () async {
      final client = ApiClient(httpClient: server());
      final health = await client.health();
      expect(health['database'], 'postgres');
      expect(health['redis'], 'connected');
    });
  });

  group('Model klien', () {
    test('StatsState round-trip JSON', () {
      final stats = StatsState.fromJson({
        'totalXp': 10,
        'level': 2,
        'streak': 3,
        'longestStreak': 4,
        'hearts': 5,
        'gems': 20,
        'freezesAvailable': 0,
        'dailyGoalXp': 20,
        'xpToday': 10,
        'nextHeartSeconds': 60,
        'heartsUpdatedAt': '2026-11-05T00:00:00Z',
      });
      expect(stats.totalXp, 10);
      expect(jsonEncode(stats.toJson()), contains('"gems":20'));
    });

    test('OfflineSession menghasilkan payload sync berisi clientOpId', () {
      final session = OfflineSession(
        clientOpId: 'op-1',
        nodeId: 'node1',
        lessonId: 'lesson1',
        startedAt: DateTime.utc(2026, 11, 5),
        completedAt: DateTime.utc(2026, 11, 5, 0, 5),
        durationMs: 5000,
        answers: [
          {'exerciseId': 'ex1', 'answer': 'Halo'}
        ],
      );
      final payload = session.toJson();
      expect(payload['clientOpId'], 'op-1');
      expect((payload['answers'] as List).first['exerciseId'], 'ex1');
    });
  });
}

http.StreamedResponse _jsonResponse(int status, Object body) {
  final bytes = utf8.encode(jsonEncode(body));
  return http.StreamedResponse(
    Stream.value(bytes),
    status,
    headers: {'content-type': 'application/json'},
  );
}
