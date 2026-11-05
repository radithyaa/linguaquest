// Perekam mikrofon untuk latihan pelafalan (SRS EXE-07).
//
// Memakai paket `record` (Android/iOS/desktop). Di web, atau bila plugin
// tidak tersedia, `start()` melempar error yang ditangkap UI.

import 'dart:io';

import 'package:record/record.dart';

class SpeechRecorder {
  SpeechRecorder();

  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  bool get isRecording => _path != null;

  String get mimeType =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS ? 'audio/m4a' : 'audio/wav';

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw StateError('Izin mikrofon ditolak');
    }
    final directory = Directory.systemTemp;
    final extension = mimeType == 'audio/wav' ? 'wav' : 'm4a';
    _path = '${directory.path}/lq_speech_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100),
      path: _path!,
    );
  }

  Future<String?> stop() async {
    final path = await _recorder.stop();
    _path = null;
    return path;
  }

  static Future<List<int>> readFile(String? path) async {
    if (path == null) return const [];
    final file = File(path);
    if (!await file.exists()) return const [];
    return file.readAsBytes();
  }

  Future<void> dispose() async {
    if (_path != null) {
      await _recorder.stop();
      _path = null;
    }
    await _recorder.dispose();
  }
}
