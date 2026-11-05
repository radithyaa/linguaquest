// Smoke test C-ABI `lq_bridge`: dipanggil dari Dart melalui dart:ffi.
//
// Pemakaian: dart run scripts/ffi_smoke.dart <path ke liblq_bridge.so>

import 'dart:convert';
import 'dart:ffi' as ffi;

typedef _GenerateNative = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);
typedef _GenerateDart = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);
typedef _FreeNative = ffi.Void Function(ffi.Pointer<ffi.Char>);
typedef _FreeDart = void Function(ffi.Pointer<ffi.Char>);
typedef _AllocNative = ffi.Pointer<ffi.Uint8> Function(ffi.IntPtr);
typedef _AllocDart = ffi.Pointer<ffi.Uint8> Function(int);

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'liblq_bridge.so';
  final library = ffi.DynamicLibrary.open(path);

  final generate = library.lookupFunction<_GenerateNative, _GenerateDart>('lq_generate_symbol');
  final free = library.lookupFunction<_FreeNative, _FreeDart>('lq_string_free');
  final alloc = library.lookupFunction<_AllocNative, _AllocDart>('lq_alloc');
  final version = library.lookupFunction<ffi.Pointer<ffi.Char> Function(),
      ffi.Pointer<ffi.Char> Function()>('lq_version');

  Map<String, dynamic> call(Map<String, dynamic> request) {
    final bytes = utf8.encode(jsonEncode(request));
    final pointer = alloc(bytes.length + 1);
    pointer.asTypedList(bytes.length + 1)
      ..setAll(0, bytes)
      ..[bytes.length] = 0;
    final result = generate(pointer.cast());
    try {
      return jsonDecode(_read(result)) as Map<String, dynamic>;
    } finally {
      free(result);
      free(pointer.cast());
    }
  }

  print('versi library   : ${_read(version())}');

  final typo = call({
    'fn': 'evaluateAnswer',
    'input': 'tehcer',
    'correctAnswer': 'teacher',
  });
  print('evaluasi typo   : status=${typo['status']} jarak=${typo['distance']}');

  final correct = call({
    'fn': 'evaluateAnswer',
    'input': 'Terima kasih banyak',
    'correctAnswer': 'Terima kasih banyak',
  });
  print('evaluasi benar  : status=${correct['status']}');

  final wrong = call({
    'fn': 'evaluateAnswer',
    'input': 'xyz',
    'correctAnswer': 'teacher',
  });
  print('evaluasi salah  : status=${wrong['status']}');

  final xp = call({'fn': 'computeXp', 'accuracy': 1.0, 'maxCombo': 15});
  print('XP sesi sempurna: ${xp['value']} (harus 21)');

  final review = call({
    'fn': 'applyFsrsRating',
    'rating': 3,
    'card': {
      'id': '1d6a5a2e-0000-4000-8000-000000000000',
      'userId': '1d6a5a2e-0000-4000-8000-000000000001',
      'word': 'Hello',
      'translation': 'Halo',
      'stability': 0.0,
      'difficulty': 5.0,
      'dueAt': DateTime.now().toUtc().toIso8601String(),
      'lastReview': null,
      'reps': 0,
      'lapses': 0,
    },
  });
  print('FSRS rating 3   : stability=${review['stability']} reps=${review['reps']}');

  final interval = call({'fn': 'recommendedIntervalDays', 'stability': 2.5});
  print('interval 90%    : ${(interval['value'] as num).toStringAsFixed(2)} hari');

  final ok = typo['status'] == 'typo_warning' &&
      correct['status'] == 'correct' &&
      wrong['status'] == 'incorrect' &&
      xp['value'] == 21 &&
      review['reps'] == 1;
  if (!ok) {
    throw StateError('FFI smoke test gagal');
  }
  print('\nFFI OK — Dart memanggil lq_core lewat liblq_bridge');
}

String _read(ffi.Pointer<ffi.Char> pointer) {
  final bytes = pointer.cast<ffi.Uint8>().asTypedList(1 << 16);
  final end = bytes.indexOf(0);
  return utf8.decode(bytes.sublist(0, end < 0 ? bytes.length : end));
}
