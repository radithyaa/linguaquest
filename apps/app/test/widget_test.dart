// Widget test: memastikan aplikasi memuat dan layar autentikasi tampil
// ketika belum ada sesi tersimpan.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linguaquest/data/api/api_client.dart';
import 'package:linguaquest/main.dart';
import 'package:linguaquest/rust_bridge/engine.dart';
import 'package:linguaquest/rust_bridge/rust_lib.dart';
import 'package:linguaquest/state/providers.dart';

void main() {
  testWidgets('LinguaQuest menampilkan layar autentikasi', (tester) async {
    final api = ApiClient(
      httpClient: MockClient((request) async => http.Response('{"status":"ok"}', 200)),
    );
    final bootstrap = Bootstrap(
      store: null,
      api: api,
      bridge: BridgeRuntime.forTesting(PureDartEngine()),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [bootstrapInstance.overrideWithValue(bootstrap)],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('LinguaQuest'), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
    expect(find.text('MAIN SEBAGAI TAMU'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
