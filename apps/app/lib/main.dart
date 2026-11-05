import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/api/api_client.dart';
import 'data/local/local_store.dart';
import 'rust_bridge/rust_lib.dart';
import 'state/providers.dart';
import 'state/session_controller.dart';
import 'ui/auth_view.dart';
import 'ui/labels.dart';
import 'ui/shell_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Diperlukan sebelum database SSE dibuka pada desktop Linux/Windows/macOS.
  LocalStore.prepareDesktopSqlite();
  debugPrint('[linguaquest] sqlite path: prepare');
  final store = await LocalStore.open();
  debugPrint('[linguaquest] sqlite ${store != null ? "siap" : "tidak tersedia"}');
  final bridge = await BridgeRuntime.init();
  final api = ApiClient(store: store);
  api.attachStore(store);
  final bootstrap = Bootstrap(store: store, api: api, bridge: bridge);

  runApp(
    ProviderScope(
      overrides: [bootstrapInstance.overrideWithValue(bootstrap)],
      child: const LinguaQuestApp(),
    ),
  );
}

class LinguaQuestApp extends ConsumerWidget {
  const LinguaQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LinguaQuest',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _RootGate(),
    );
  }
}

/// Menentukan layar awal: dashboard (sudah login) atau autentikasi.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiProvider);
    final profile = ref.watch(profileProvider);

    if (!api.isAuthenticated) {
      return const AuthView();
    }

    return profile.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        if (error is ApiException && error.isAuth) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(sessionControllerProvider.notifier).logout();
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _StartupError(message: describeError(error), showLogin: () {
          ref.read(sessionControllerProvider.notifier).logout();
        });
      },
      data: (value) => const AppShell(),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message, required this.showLogin});

  final String message;
  final VoidCallback showLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.orange),
              const SizedBox(height: 12),
              const Text('Gagal memuat profil',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: showLogin, child: const Text('Kembali ke Login')),
            ],
          ),
        ),
      ),
    );
  }
}
