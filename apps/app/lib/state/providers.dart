// Provider inti: penyimpanan lokal, klien API, engine Rust, dan state global.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_client.dart';
import '../data/local/local_store.dart';
import '../data/models/app_models.dart';
import '../rust_bridge/frb_generated.dart';
import '../rust_bridge/rust_lib.dart';

/// Dibuat di `main()` setelah bootstrap asynchronous selesai.
final bootstrapProvider = Provider<Bootstrap>((ref) => throw UnimplementedError('Bootstrap belum disiapkan'));

class Bootstrap {
  Bootstrap({required this.store, required this.api, required this.bridge});

  final LocalStore? store;
  final ApiClient api;
  final BridgeRuntime bridge;

  RustApi get rust => RustApi(engine: bridge.engine);

  bool get hasLocalDb => store != null;
}

/// Status konektivitas + info server yang ditampilkan di UI.
class ServerInfo {
  const ServerInfo({
    required this.online,
    required this.database,
    required this.redis,
    required this.message,
  });

  const ServerInfo.unknown()
      : online = false,
        database = '-',
        redis = '-',
        message = 'Belum terhubung';

  final bool online;
  final String database;
  final String redis;
  final String message;
}

final bootstrapInstance = Provider<Bootstrap>((ref) => throw UnimplementedError());

final localStoreProvider = Provider<LocalStore?>((ref) => ref.watch(bootstrapInstance).store);

final apiProvider = Provider<ApiClient>((ref) => ref.watch(bootstrapInstance).api);

final rustApiProvider = Provider<RustApi>((ref) => ref.watch(bootstrapInstance).rust);

/// Info server (diperbarui oleh `SessionController`).
final serverInfoProvider = StateProvider<ServerInfo>((ref) => const ServerInfo.unknown());

/// Profil pengguna + statistik dari server.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final api = ref.watch(apiProvider);
  final store = ref.watch(localStoreProvider);
  if (!api.isAuthenticated) return null;
  final profile = await api.profile();
  await store?.saveStats(profile.user.id, profile.stats);
  return profile;
});

/// Statistik ringan untuk TopBar, diperbarui setelah sesi/pembelian.
final statsProvider = StateProvider<StatsState>((ref) => StatsState.empty);

/// Indikator debug tipe mesin yang dipakai.
final engineModeProvider = Provider<String>((ref) => ref.watch(bootstrapInstance).bridge.mode);

@visibleForTesting
void debugPrintEngine(String label) => debugPrint(label);
