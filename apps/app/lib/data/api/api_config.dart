// Konfigurasi alamat server API LinguaQuest.
//
// Urutan penentuan URL:
//   1. `--dart-define=API_BASE_URL=http://host:8090/v1`
//   2. Emulator Android: `10.0.2.2` = localhost mesin host
//   3. Perangkat fisik Android: alamat LAN otomatis dari `LQ_LAN_HOST`
//   4. Fallback: `127.0.0.1` (desktop/iOS simulator)

import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Host LAN opsional, mis. `--dart-define=LQ_LAN_HOST=192.168.1.10`.
  static const String _lanHost = String.fromEnvironment('LQ_LAN_HOST');

  static const int port = int.fromEnvironment('LQ_API_PORT', defaultValue: 8090);

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://127.0.0.1:$port/v1';
    if (Platform.isAndroid) {
      // Emulator mengenali host melalui 10.0.2.2; perangkat fisik butuh IP LAN.
      if (_lanHost.isNotEmpty) return 'http://$_lanHost:$port/v1';
      return 'http://10.0.2.2:$port/v1';
    }
    return 'http://127.0.0.1:$port/v1';
  }

  /// Alamat STT service (opsional).
  static String get sttProvider => const String.fromEnvironment('LQ_STT_PROVIDER', defaultValue: 'none');

  static Duration get requestTimeout => const Duration(seconds: 20);
}
