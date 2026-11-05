// Klien HTTP untuk API Rust (`lq_api`).
//
// - Menyisipkan header `Authorization: Bearer <token>` otomatis.
// - Refresh token otomatis sekali ketika menerima 401.
// - Menerjemahkan Problem Details (RFC 9457) menjadi `ApiException` bertipe.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../api/api_config.dart';
import '../api/models.dart';
import '../models/app_models.dart';
import '../local/local_store.dart';

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.code,
    required this.title,
    required this.detail,
  });

  final int statusCode;
  final String code;
  final String title;
  final String detail;

  bool get isNetwork => statusCode == 0;
  bool get isAuth => statusCode == 401;
  bool get isOffline => statusCode == 0 || statusCode == 503;

  /// Error yang tetap bisa ditangani dengan mode offline (server mati).
  bool get canWorkOffline => isOffline;

  @override
  String toString() => 'ApiException($statusCode, $code): $detail';
}

/// Konflik klien yang perlu penanganan khusus UI.
class HeartsExhaustedException extends ApiException {
  HeartsExhaustedException(String detail)
      : super(
          statusCode: 403,
          code: 'HEARTS_EXHAUSTED',
          title: 'Hearts Depleted',
          detail: detail,
        );
}

typedef TokenListener = void Function(String? accessToken, String? refreshToken);

class ApiClient {
  ApiClient({http.Client? httpClient, LocalStore? store})
      : _http = httpClient ?? http.Client(),
        _store = store;

  final http.Client _http;
  LocalStore? _store;

  String? _accessToken;
  String? _refreshToken;

  TokenListener? onTokensChanged;

  String get baseUrl => ApiConfig.baseUrl;

  void attachStore(LocalStore? store) => _store = store;

  void setTokens({String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    onTokensChanged?.call(accessToken, refreshToken);
  }

  bool get isAuthenticated => _accessToken != null;

  String? get refreshToken => _refreshToken;

  /// Mengembalikan token valid; me-refresh bila hampir tidak ada sesi.
  Future<void> restoreSession() async {
    final session = await _store?.readSession();
    if (session == null) return;
    _accessToken = session['accessToken'] as String?;
    _refreshToken = session['refreshToken'] as String?;
  }

  Future<Map<String, dynamic>> rawRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'content-type': 'application/json'};
    if (authenticated && _accessToken != null) {
      headers['authorization'] = 'Bearer $_accessToken';
    }

    http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _http.send(request).timeout(ApiConfig.requestTimeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        code: 'TIMEOUT',
        title: 'Koneksi Lambat',
        detail: 'Server tidak merespons dalam ${ApiConfig.requestTimeout.inSeconds} detik.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        title: 'Tidak Ada Koneksi',
        detail: 'Tidak dapat menghubungi server di $baseUrl.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        title: 'Tidak Ada Koneksi',
        detail: error.message,
      );
    }

    if (response.statusCode == 401 && authenticated && retryOnUnauthorized && _refreshToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return rawRequest(method, path, body: body, authenticated: authenticated, retryOnUnauthorized: false);
      }
    }

    final decoded = response.body.isEmpty ? null : _decode(response.body);
    if (response.statusCode >= 400) {
      throw _toException(response.statusCode, decoded);
    }
    return (decoded as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<List<dynamic>> rawList(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'content-type': 'application/json'};
    if (_accessToken != null) headers['authorization'] = 'Bearer $_accessToken';
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _http.send(request).timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty ? <dynamic>[] : _decode(response.body);
      if (response.statusCode >= 400) throw _toException(response.statusCode, decoded);
      return (decoded as List<dynamic>?) ?? <dynamic>[];
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        title: 'Tidak Ada Koneksi',
        detail: 'Tidak dapat menghubungi server di $baseUrl.',
      );
    }
  }

  static dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static ApiException _toException(int status, dynamic decoded) {
    final map = decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
    final code = map['code'] as String? ?? 'ERROR';
    final detail = map['detail'] as String? ?? 'Terjadi kesalahan ($status).';
    if (code == 'HEARTS_EXHAUSTED') return HeartsExhaustedException(detail);
    return ApiException(
      statusCode: status,
      code: code,
      title: map['title'] as String? ?? 'Kesalahan',
      detail: detail,
    );
  }

  Future<bool> _tryRefresh() async {
    final token = _refreshToken;
    if (token == null) return false;
    try {
      final result = await rawRequest(
        'POST',
        '/auth/refresh',
        body: {'refreshToken': token},
        authenticated: false,
        retryOnUnauthorized: false,
      );
      _accessToken = result['accessToken'] as String?;
      _refreshToken = result['refreshToken'] as String?;
      onTokensChanged?.call(_accessToken, _refreshToken);
      return _accessToken != null;
    } on ApiException {
      _accessToken = null;
      _refreshToken = null;
      onTokensChanged?.call(null, null);
      await _store?.clearSession();
      return false;
    }
  }

  // ------------------------------------------------------------- Endpoints

  Future<Map<String, dynamic>> health() =>
      rawRequest('GET', '/health', authenticated: false, retryOnUnauthorized: false);

  Future<void> login({required String email, required String password}) async {
    final result = await rawRequest(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    await _storeAuth(result);
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    String? username,
  }) async {
    final result = await rawRequest(
      'POST',
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'displayName': displayName,
        if (username != null && username.isNotEmpty) 'username': username,
      },
      authenticated: false,
    );
    await _storeAuth(result);
  }

  Future<void> guestLogin({String? displayName}) async {
    final result = await rawRequest(
      'POST',
      '/auth/guest',
      body: {'displayName': displayName},
      authenticated: false,
    );
    await _storeAuth(result);
  }

  Future<void> upgradeGuest({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final result = await rawRequest(
      'POST',
      '/auth/upgrade',
      body: {'email': email, 'password': password, 'displayName': displayName},
    );
    await _storeAuth(result);
  }

  Future<void> logout() async {
    final token = _refreshToken;
    if (token != null) {
      try {
        await rawRequest('POST', '/auth/logout', body: {'refreshToken': token});
      } on ApiException {
        // Logout lokal tetap dilakukan walau server tidak terjangkau.
      }
    }
    setTokens(accessToken: null, refreshToken: null);
    await _store?.clearSession();
  }

  Future<void> _storeAuth(Map<String, dynamic> result) async {
    _accessToken = result['accessToken'] as String?;
    _refreshToken = result['refreshToken'] as String?;
    onTokensChanged?.call(_accessToken, _refreshToken);
    final user = (result['user'] as Map?)?.cast<String, dynamic>();
    if (user != null) {
      await _store?.saveSession(
        accessToken: _accessToken ?? '',
        refreshToken: _refreshToken ?? '',
        user: user,
      );
    }
  }

  Future<Profile> profile() async => Profile.fromJson(await rawRequest('GET', '/me'));

  Future<StatsState> stats() async =>
      StatsState.fromJson(await rawRequest('GET', '/me/stats'));

  Future<List<Course>> courses() async {
    final list = await rawList('GET', '/courses');
    return list.whereType<Map<String, dynamic>>().map(Course.fromJson).toList();
  }

  Future<Curriculum> curriculum(String courseId) async =>
      Curriculum.fromJson(await rawRequest('GET', '/courses/$courseId/curriculum'));

  Future<StartedSession> startSession(String nodeId) async =>
      StartedSession.fromJson(await rawRequest('POST', '/sessions/start', body: {'nodeId': nodeId}));

  Future<SessionSummary> completeSession({
    required String? sessionId,
    required String clientOpId,
    required String nodeId,
    required DateTime startedAt,
    required int durationMs,
    required List<Map<String, dynamic>> answers,
  }) async {
    final result = await rawRequest('POST', '/sessions/complete', body: {
      'sessionId': sessionId,
      'clientOpId': clientOpId,
      'nodeId': nodeId,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'durationMs': durationMs,
      'answers': answers,
    });
    return SessionSummary.fromJson(result);
  }

  Future<PracticeOverview> practice() async =>
      PracticeOverview.fromJson(await rawRequest('GET', '/practice'));

  Future<SrsCardState> reviewCard({
    required String cardId,
    required int rating,
    String? clientOpId,
  }) async {
    final result = await rawRequest('POST', '/practice/review', body: {
      'cardId': cardId,
      'rating': rating,
      'clientOpId': clientOpId,
      'reviewedAt': DateTime.now().toUtc().toIso8601String(),
    });
    return SrsCardState.fromJson((result['card'] as Map?)?.cast<String, dynamic>() ?? const {});
  }

  Future<QuestOverview> quests() async =>
      QuestOverview.fromJson(await rawRequest('GET', '/quests'));

  Future<StatsState> claimQuest(String code) async {
    final result = await rawRequest('POST', '/quests/$code/claim');
    return StatsState.fromJson((result['stats'] as Map?)?.cast<String, dynamic>() ?? const {});
  }

  Future<LeagueOverview> league() async =>
      LeagueOverview.fromJson(await rawRequest('GET', '/league'));

  Future<List<ShopItem>> shopCatalog() async {
    final list = await rawList('GET', '/shop/catalog');
    return list.whereType<Map<String, dynamic>>().map(ShopItem.fromJson).toList();
  }

  Future<StatsState> buy(String sku) async {
    final result = await rawRequest('POST', '/shop/buy', body: {'sku': sku});
    return StatsState.fromJson((result['stats'] as Map?)?.cast<String, dynamic>() ?? const {});
  }

  Future<Map<String, dynamic>> sync({
    required List<Map<String, dynamic>> sessions,
    required List<Map<String, dynamic>> reviews,
    required List<Map<String, dynamic>> purchases,
  }) =>
      rawRequest('POST', '/sync', body: {
        'sessions': sessions,
        'reviews': reviews,
        'purchases': purchases,
      });

  /// Mengirim audio base64 ke endpoint STT server (latihan pelafalan).
  Future<Map<String, dynamic>> transcribe({
    required String audioBase64,
    required String mimeType,
    required String expectedText,
  }) =>
      rawRequest('POST', '/stt/transcribe', body: {
        'audioBase64': audioBase64,
        'mimeType': mimeType,
        'expectedText': expectedText,
      });

  /// Admin CMS: menambahkan unit baru.
  Future<Map<String, dynamic>> createUnit({
    required String title,
    required String description,
    required String summary,
    required List<String> grammarTips,
  }) =>
      rawRequest('POST', '/admin/units', body: {
        'title': title,
        'description': description,
        'summary': summary,
        'grammarTips': grammarTips,
        'themeColor': '#CE82FF',
      });
}
