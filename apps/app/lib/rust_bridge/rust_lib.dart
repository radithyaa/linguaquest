// Inisialisasi & pemilihan engine Rust untuk Flutter.
//
// Native (Android/iOS/Desktop): `liblq_bridge.so` dimuat via `DynamicLibrary`.
// Bridge ini memakai kontrak C-ABI JSON: setiap fungsi Rust memakai satu
// parameter `String` (JSON) dan mengembalikan `String` (JSON), yang
// dikembalikan sebagai `*mut c_char` lalu dibebaskan dengan `lq_string_free`.
//
// Keuntungan: deterministik, tanpa threading/port, dan hasilnya identik dengan
// pemanggilan `flutter_rust_bridge` (fungsi `#[frb(sync)]` pada crate yang sama).
//
// Bila library tidak tersedia (unit test, web, atau .so belum di-build),
// aplikasi otomatis memakai `PureDartEngine` yang porting-nya identik.

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'engine.dart';
import 'frb_generated.dart';

/// Nama library native (dibangun oleh `scripts/build_bridge.sh`).
const String bridgeLibraryName = 'lq_bridge';

typedef _GenerateSymbolNative = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);
typedef _GenerateSymbolDart = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);
typedef _FreeStringNative = ffi.Void Function(ffi.Pointer<ffi.Char>);
typedef _FreeStringDart = void Function(ffi.Pointer<ffi.Char>);

class BridgeRuntime {
  BridgeRuntime._(this.engine, this.mode, this.detail);

  final BridgeEngine engine;

  /// `rust-ffi` bila library native aktif, `dart-fallback` bila tidak.
  final String mode;

  final String detail;

  static late BridgeRuntime instance;

  /// Instance untuk pengujian dengan engine tertentu tanpa memuat .so.
  @visibleForTesting
  static BridgeRuntime forTesting(BridgeEngine engine) =>
      BridgeRuntime._(engine, 'test', 'engine uji');

  bool get isRustActive => mode == 'rust-ffi';

  static Future<BridgeRuntime> init() async {
    if (kIsWeb) {
      instance = BridgeRuntime._(
        PureDartEngine(),
        'dart-fallback',
        'Web: modul WASM belum dimuat, memakai porting Dart.',
      );
      return instance;
    }

    try {
      final library = _Abi(library: _openLibrary());
      final engine = FFIEngine(invoke: library.invoke);
      // Panggil satu fungsi untuk memastikan ABI benar-benar aktif.
      final probe = await engine.computeXp(accuracy: 1.0, maxCombo: 10);
      instance = BridgeRuntime._(
        engine,
        'rust-ffi',
        'lib$bridgeLibraryName aktif (probe XP=$probe)',
      );
      debugPrint('[linguaquest] engine Rust aktif: ${instance.detail}');
    } catch (error) {
      instance = BridgeRuntime._(
        PureDartEngine(),
        'dart-fallback',
        'Library native tidak termuat ($error).',
      );
      debugPrint('[linguaquest] ${instance.detail}');
    }
    return instance;
  }

  /// Membuka `liblq_bridge.so`/`.dylib`/`.dll` sesuai platform.
  static ffi.DynamicLibrary _openLibrary() {
    final candidates = <String>[
      if (Platform.isAndroid || Platform.isLinux) 'lib$bridgeLibraryName.so',
      if (Platform.isMacOS || Platform.isIOS) 'lib$bridgeLibraryName.dylib',
      if (Platform.isWindows) '$bridgeLibraryName.dll',
    ];
    Object? lastError;
    for (final name in candidates) {
      try {
        return ffi.DynamicLibrary.open(name);
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('Gagal memuat ${candidates.join(", ")}: $lastError');
  }
}

/// Pembungkus C-ABI `lq_bridge`.
class _Abi {
  _Abi({required ffi.DynamicLibrary library}) : _library = library;

  final ffi.DynamicLibrary _library;
  late final _generate = _library
      .lookupFunction<_GenerateSymbolNative, _GenerateSymbolDart>('lq_generate_symbol');
  late final _free = _library.lookupFunction<_FreeStringNative, _FreeStringDart>('lq_string_free');

  Future<String> invoke(String function, Map<String, dynamic> args) async {
    final request = _encode({'fn': function, ...args});
    final requestPointer = _allocate(request.codeUnits).cast<ffi.Char>();
    final resultPointer = _generate(requestPointer);
    try {
      if (resultPointer == ffi.nullptr) return '{}';
      return _readUtf8(resultPointer);
    } finally {
      _free(resultPointer);
      _free(requestPointer);
    }
  }

  /// Alokasi memori native untuk string permintaan (UTF-8, null-terminated).
  ffi.Pointer<ffi.Uint8> _allocate(List<int> bytes) {
    final alloc =
        _library.lookupFunction<ffi.Pointer<ffi.Uint8> Function(ffi.IntPtr), ffi.Pointer<ffi.Uint8> Function(int)>(
            'lq_alloc');
    final pointer = alloc(bytes.length + 1);
    final buffer = pointer.asTypedList(bytes.length + 1);
    buffer.setAll(0, bytes);
    buffer[bytes.length] = 0;
    return pointer;
  }
}

String _encode(Map<String, dynamic> value) => jsonEncode(value);

/// Membaca string C (UTF-8, null-terminated) sampai byte 0.
String _readUtf8(ffi.Pointer<ffi.Char> pointer) {
  final bytes = pointer.cast<ffi.Uint8>().asTypedList(1 << 20);
  final end = bytes.indexOf(0);
  final slice = end < 0 ? bytes : bytes.sublist(0, end);
  return utf8.decode(slice);
}
