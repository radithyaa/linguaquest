// Penyimpanan lokal perangkat (SQLite via sqflite).
//
// Menyimpan:
//  - token JWT/refresh + profil terakhir
//  - cache kurikulum (agar peta belajar tetap tampil tanpa internet)
//  - antrean operasi offline (`pending_ops`) berisi sesi & ulasan FSRS dengan
//    `client_op_id` unik untuk sinkronisasi idempotent ke server (SRS 11.1)
//
// Catatan: nama tabel/kolom mengikuti konvensi Drift sehingga bila proyek
// dimigrasikan ke codegen `drift`, struktur ini dapat dipetakan langsung.

import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../api/models.dart';
import '../models/app_models.dart';

class LocalStore {
  LocalStore._(this._db);

  final Database _db;

  static LocalStore? _instance;

  /// Membuka database. Gagal (mis. web) -> null dan aplikasi tetap jalan
  /// dengan penyimpanan memori terbatas.
  static Future<LocalStore?> open() async {
    if (_instance != null) return _instance;
    try {
      // Desktop (Linux/Windows/macOS) memakai implementasi SQLite via FFI;
      // Android/iOS memakai plugin sqflite bawaan.
      if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        databaseFactory = createDatabaseFactoryFfi(ffiInit: desktopFfiInit);
      }
      final directory = await getApplicationSupportDirectory();
      final path = p.join(directory.path, 'linguaquest.db');
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE session (
              key TEXT PRIMARY KEY,
              access_token TEXT NOT NULL,
              refresh_token TEXT NOT NULL,
              user_json TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE cached_curriculum (
              course_id TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              cached_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE pending_ops (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              client_op_id TEXT NOT NULL UNIQUE,
              kind TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE local_stats (
              user_id TEXT PRIMARY KEY,
              stats_json TEXT NOT NULL
            )
          ''');
        },
      );
      _instance = LocalStore._(db);
      return _instance;
    } catch (error) {
      debugPrint('[linguaquest] SQLite tidak tersedia: $error');
      return null;
    }
  }

  static LocalStore? get instanceOrNull => _instance;

  /// Inisialisasi FFI desktop; sebagian distro Linux hanya menyediakan
  /// `libsqlite3.so.0` (tanpa symlink `libsqlite3.so` dari paket dev).
  static void desktopFfiInit() {
    sqfliteFfiInit();
    if (!kIsWeb && Platform.isLinux) {
      try {
        DynamicLibrary.open('libsqlite3.so.0');
        sqlite_open.open.overrideFor(
          sqlite_open.OperatingSystem.linux,
          () => DynamicLibrary.open('libsqlite3.so.0'),
        );
      } catch (_) {
        // `libsqlite3.so` tersedia — pakai loader default.
      }
    }
  }

  /// Wajib dipanggil sebelum `LocalStore.open()` pada platform desktop.
  static void prepareDesktopSqlite() {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) return;
    desktopFfiInit();
  }

  // ------------------------------------------------------------------ sesi

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await _db.insert(
      'session',
      {
        'key': 'current',
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user_json': jsonEncode(user),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> readSession() async {
    final rows = await _db.query('session', where: 'key = ?', whereArgs: ['current'], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return {
      'accessToken': row['access_token'],
      'refreshToken': row['refresh_token'],
      'user': jsonDecode(row['user_json'] as String),
    };
  }

  Future<void> clearSession() async {
    await _db.delete('session');
  }

  // ------------------------------------------------------------- statistik

  Future<void> saveStats(String userId, StatsState stats) async {
    await _db.insert(
      'local_stats',
      {'user_id': userId, 'stats_json': jsonEncode(stats.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<StatsState?> readStats(String userId) async {
    final rows = await _db.query('local_stats', where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (rows.isEmpty) return null;
    return StatsState.fromJson(jsonDecode(rows.first['stats_json'] as String));
  }

  // ------------------------------------------------------------- kurikulum

  Future<void> cacheCurriculum(Curriculum curriculum) async {
    await _db.insert(
      'cached_curriculum',
      {
        'course_id': curriculum.course.id,
        'payload': jsonEncode(curriculum.toJson()),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Curriculum?> readCurriculum(String courseId) async {
    final rows =
        await _db.query('cached_curriculum', where: 'course_id = ?', whereArgs: [courseId], limit: 1);
    if (rows.isEmpty) return null;
    return Curriculum.fromJson(jsonDecode(rows.first['payload'] as String));
  }

  Future<String?> lastCourseId() async {
    final rows = await _db.query('cached_curriculum', orderBy: 'cached_at DESC', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['course_id'] as String?;
  }

  // -------------------------------------------------------------- antrean

  /// Tambahkan operasi ke antrean sinkronisasi. Mengembalikan `client_op_id`.
  Future<String> enqueueOfflineSession(OfflineSession session) async {
    await _db.insert(
      'pending_ops',
      {
        'client_op_id': session.clientOpId,
        'kind': 'session',
        'payload': jsonEncode(session.toJson()),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return session.clientOpId;
  }

  Future<String> enqueueOfflineReview(OfflineReview review) async {
    await _db.insert(
      'pending_ops',
      {
        'client_op_id': review.clientOpId,
        'kind': 'review',
        'payload': jsonEncode(review.toJson()),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return review.clientOpId;
  }

  Future<int> enqueueFailedPurchase(String sku) async {
    final opId = const Uuid().v4();
    await _db.insert(
      'pending_ops',
      {
        'client_op_id': opId,
        'kind': 'purchase',
        'payload': jsonEncode({'sku': sku, 'clientOpId': opId}),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return 1;
  }

  Future<List<PendingOp>> pendingOps() async {
    final rows = await _db.query('pending_ops', orderBy: 'id ASC');
    return rows
        .map((row) => PendingOp(
              id: row['id'] as int,
              clientOpId: row['client_op_id'] as String,
              kind: row['kind'] as String,
              payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<int> pendingCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) AS c FROM pending_ops');
    return (result.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<void> removeOps(Iterable<String> clientOpIds) async {
    if (clientOpIds.isEmpty) return;
    final placeholders = List.filled(clientOpIds.length, '?').join(',');
    await _db.delete('pending_ops', where: 'client_op_id IN ($placeholders)', whereArgs: clientOpIds.toList());
  }
}

class PendingOp {
  const PendingOp({
    required this.id,
    required this.clientOpId,
    required this.kind,
    required this.payload,
  });

  final int id;
  final String clientOpId;
  final String kind;
  final Map<String, dynamic> payload;
}
