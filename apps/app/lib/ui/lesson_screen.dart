// Layar sesi pelajaran: 9 tipe latihan, evaluasi via mesin lq_core,
// rekaman audio untuk latihan pelafalan, dan rangkuman hasil dari server.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/colors.dart';
import '../core/widgets/mascot.dart';
import '../core/widgets/tactile_button.dart';
import '../data/api/api_client.dart';
import '../data/api/models.dart';
import '../data/models/app_models.dart';
import '../features/lesson/speech_recorder.dart';
import '../rust_bridge/frb_generated.dart';
import '../state/providers.dart';
import '../state/session_controller.dart';
import 'labels.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.node});

  final LessonNode node;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  StartedSession? _session;
  String? _startError;

  int _index = 0;
  int _combo = 0;
  int _maxCombo = 0;
  double _hearts = 5;

  final List<Map<String, dynamic>> _submitted = [];
  final Map<String, String> _evaluations = {};
  final Set<String> _typoRows = {};

  String? _selectedOption;
  final List<String> _assembled = [];
  final List<String> _removedBank = [];
  final _typing = TextEditingController();
  String? _selectedLeft;
  final Map<String, String> _matchedPairs = {};
  String? _speechTranscript;

  bool _checked = false;
  bool _isCorrect = false;
  bool _busy = false;
  DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final controller = ref.read(sessionControllerProvider.notifier);
    final stats = ref.read(statsProvider);
    setState(() => _hearts = stats.hearts.toDouble().clamp(0, 5));
    try {
      final session = await controller.startSession(widget.node);
      if (!mounted) return;
      setState(() {
        _session = session;
        _startedAt = DateTime.now();
        if (session.hearts > 0) _hearts = session.hearts.toDouble();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _startError = describeError(error));
    } catch (error) {
      if (!mounted) return;
      setState(() => _startError = describeError(error));
    }
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  Exercise? get _exercise {
    final session = _session;
    if (session == null || _index >= session.exercises.length) return null;
    return session.exercises[_index];
  }

  String _answerFor(Exercise exercise) {
    switch (exercise.kind) {
      case ExerciseKind.multipleChoice:
      case ExerciseKind.fillInTheBlank:
      case ExerciseKind.listening:
        return _selectedOption ?? '';
      case ExerciseKind.wordBank:
        return _assembled.join(' ');
      case ExerciseKind.typing:
        return _typing.text;
      case ExerciseKind.pairMatching:
        return _matchedPairs.entries.map((e) => '${e.key}=${e.value}').join('|');
      case ExerciseKind.speech:
        return _speechTranscript ?? '';
      default:
        return '';
    }
  }

  bool get _canCheck {
    final exercise = _exercise;
    if (exercise == null || _checked) return false;
    final answer = _answerFor(exercise).trim();
    if (exercise.kind == ExerciseKind.pairMatching) {
      return _matchedPairs.length == exercise.pairs.length && exercise.pairs.isNotEmpty;
    }
    return answer.isNotEmpty;
  }

  Future<void> _check() async {
    final exercise = _exercise;
    if (exercise == null || !_canCheck) return;

    final controller = ref.read(sessionControllerProvider.notifier);
    final answer = _answerFor(exercise);

    AnswerEvaluation evaluation;
    try {
      evaluation = await controller.evaluate(exercise, answer);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Evaluasi gagal: $error')),
      );
      return;
    }

    if (!mounted) return;
    final correct = evaluation.isCorrect;
    setState(() {
      _checked = true;
      _isCorrect = correct;
      _evaluations[exercise.id] = evaluation.canonicalAnswer;
      if (evaluation.status == EvaluationStatus.typoWarning) {
        _typoRows.add(exercise.id);
        _combo++;
        _maxCombo = _maxCombo > _combo ? _maxCombo : _combo;
      } else if (correct) {
        _combo++;
        _maxCombo = _maxCombo > _combo ? _maxCombo : _combo;
      } else {
        _combo = 0;
        _hearts = (_hearts - 1).clamp(0, 5);
      }
      _submitted.add({'exerciseId': exercise.id, 'answer': answer, 'durationMs': 0});
    });
  }

  Future<void> _next() async {
    final session = _session!;
    if (_hearts <= 0) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hearts Habis'),
          content: const Text('Heart kamu habis. Isi ulang di Toko atau tunggu regenerasi 4 jam.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('KELUAR')),
          ],
        ),
      );
      if (leave == true && mounted) Navigator.of(context).pop();
      return;
    }

    if (_index + 1 >= session.exercises.length) {
      setState(() => _busy = true);
      try {
        final summary = await ref.read(sessionControllerProvider.notifier).completeSession(
              session: session,
              answers: _submitted,
              startedAt: _startedAt,
            );
        if (!mounted) return;
        Navigator.of(context).pop(summary);
      } catch (error) {
        if (!mounted) return;
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan sesi: ${describeError(error)}')),
        );
      }
      return;
    }

    setState(() {
      _index++;
      _checked = false;
      _isCorrect = false;
      _selectedOption = null;
      _assembled.clear();
      _removedBank.clear();
      _typing.clear();
      _selectedLeft = null;
      _matchedPairs.clear();
      _speechTranscript = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_startError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.node.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock_rounded, size: 56, color: AppColors.heartRed),
                const SizedBox(height: 12),
                Text(_startError!, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    final session = _session;
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (session.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.node.title)),
        body: const Center(child: Text('Pelajaran ini belum memiliki soal.')),
      );
    }

    final exercise = _exercise!;
    final total = session.exercises.length;
    final progress = _index / total;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 28, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 14,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.borderLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: AppColors.heartRed, size: 24),
                      const SizedBox(width: 4),
                      Text(
                        '${_hearts.toInt()}',
                        style: const TextStyle(
                          color: AppColors.heartRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.instruction ?? 'Pilih jawaban yang benar:',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MascotWidget(
                          size: 76,
                          mood: !_checked
                              ? MascotMood.happy
                              : _isCorrect
                                  ? MascotMood.cheering
                                  : MascotMood.sad,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderLight, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              exercise.prompt,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_combo >= 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Chip(
                          backgroundColor: AppColors.streakOrangeLight,
                          avatar: const Icon(Icons.local_fire_department_rounded,
                              color: AppColors.streakOrange, size: 18),
                          label: Text('Combo x$_combo',
                              style: const TextStyle(
                                  color: AppColors.streakOrangeDark, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildInput(exercise),
                  ],
                ),
              ),
            ),
            _buildFooter(exercise),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(Exercise exercise) {
    switch (exercise.kind) {
      case ExerciseKind.multipleChoice:
      case ExerciseKind.fillInTheBlank:
      case ExerciseKind.listening:
        return Column(
          children: exercise.options.map((option) {
            final selected = _selectedOption == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TactileButton(
                variant: selected ? ButtonVariant.secondary : ButtonVariant.outline,
                width: double.infinity,
                height: 56,
                onPressed: _checked ? null : () => setState(() => _selectedOption = option),
                child: Text(option),
              ),
            );
          }).toList(),
        );

      case ExerciseKind.wordBank:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 64),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 2)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _assembled
                    .map((word) => Chip(
                          label: Text(word, style: const TextStyle(fontWeight: FontWeight.bold)),
                          onDeleted: _checked
                              ? null
                              : () => setState(() {
                                    _assembled.remove(word);
                                    _removedBank.remove(word);
                                  }),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercise.wordBank.asMap().entries.map((entry) {
                final used = _assembled.contains(entry.value) || _removedBank.contains(entry.value);
                return TactileButton(
                  variant: used ? ButtonVariant.ghost : ButtonVariant.outline,
                  height: 44,
                  onPressed: used || _checked
                      ? null
                      : () => setState(() {
                            _assembled.add(entry.value);
                            _removedBank.add(entry.value);
                          }),
                  child: Text(entry.value),
                );
              }).toList(),
            ),
          ],
        );

      case ExerciseKind.typing:
        return TextField(
          controller: _typing,
          enabled: !_checked,
          decoration: InputDecoration(
            hintText: 'Ketik jawabanmu di sini...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );

      case ExerciseKind.pairMatching:
        return _buildPairMatching(exercise);

      case ExerciseKind.speech:
        return _SpeechPractice(
          expectedText: exercise.prompt,
          checked: _checked,
          onTranscript: (text) => setState(() => _speechTranscript = text),
        );

      case ExerciseKind.story:
      case ExerciseKind.characterWriting:
      case ExerciseKind.unknown:
        return const Text('Tipe latihan ini belum didukung di versi ini.');
    }
  }

  Widget _buildPairMatching(Exercise exercise) {
    final rights = exercise.pairs.map((p) => p.right).toList()..shuffle();
    final remainingLefts = exercise.pairs
        .where((p) => !_matchedPairs.containsKey(p.left))
        .map((p) => p.left)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: remainingLefts.map((left) {
            final selected = _selectedLeft == left;
            return TactileButton(
              variant: selected ? ButtonVariant.secondary : ButtonVariant.outline,
              height: 44,
              onPressed: _checked ? null : () => setState(() => _selectedLeft = left),
              child: Text(left),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rights.map((right) {
            final matched = _matchedPairs.containsValue(right);
            return TactileButton(
              variant: matched ? ButtonVariant.ghost : ButtonVariant.primary,
              height: 44,
              onPressed: matched || _checked || _selectedLeft == null
                  ? null
                  : () => setState(() {
                        _matchedPairs[_selectedLeft!] = right;
                        _selectedLeft = null;
                      }),
              child: Text(right),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (_matchedPairs.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _matchedPairs.entries
                .map((e) => Chip(
                      label: Text('${e.key} → ${e.value}', style: const TextStyle(fontSize: 12)),
                      onDeleted: _checked
                          ? null
                          : () => setState(() => _matchedPairs.remove(e.key)),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildFooter(Exercise exercise) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_checked) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 2)),
        ),
        child: TactileButton(
          width: double.infinity,
          height: 52,
          onPressed: _canCheck ? _check : null,
          child: const Text('PERIKSA'),
        ),
      );
    }

    final background = _isCorrect ? AppColors.primaryGreenLight : AppColors.heartRedLight;
    final foreground = _isCorrect ? AppColors.primaryGreenDark : AppColors.heartRedDark;
    final canonical = _evaluations[exercise.id];
    final typo = _typoRows.contains(exercise.id);

    if (!_isCorrect) {
      return _buildFeedbackSheet(
        background: background,
        foreground: foreground,
        icon: Icons.cancel_rounded,
        title: 'Jawaban Belum Tepat',
        lines: [
          'Jawaban benar: ${canonical ?? "-"}',
        ],
        buttonLabel: _hearts <= 0 ? 'KELUAR' : 'LANJUT',
        buttonVariant: ButtonVariant.danger,
        onPressed: _next,
      );
    }

    return _buildFeedbackSheet(
      background: background,
      foreground: foreground,
      icon: Icons.check_circle_rounded,
      title: typo ? 'Hampir Tepat!' : 'Luar Biasa!',
      lines: [
        if (typo) 'Ada typo kecil, namun jawaban diterima: ${canonical ?? "-"}',
      ],
      buttonLabel: _index + 1 >= (_session?.exercises.length ?? 0) ? 'SELESAI' : 'LANJUT',
      buttonVariant: ButtonVariant.primary,
      onPressed: _next,
    );
  }

  Widget _buildFeedbackSheet({
    required Color background,
    required Color foreground,
    required IconData icon,
    required String title,
    required List<String> lines,
    required String buttonLabel,
    required ButtonVariant buttonVariant,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: foreground, size: 28),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: foreground, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...lines.map((line) => Text(line, style: TextStyle(color: foreground))),
          ],
          const SizedBox(height: 16),
          TactileButton(
            width: double.infinity,
            height: 52,
            variant: buttonVariant,
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

/// Latihan pelafalan: rekam audio lalu kirim ke endpoint STT server.
class _SpeechPractice extends ConsumerStatefulWidget {
  const _SpeechPractice({
    required this.expectedText,
    required this.checked,
    required this.onTranscript,
  });

  final String expectedText;
  final bool checked;
  final ValueChanged<String> onTranscript;

  @override
  ConsumerState<_SpeechPractice> createState() => _SpeechPracticeState();
}

class _SpeechPracticeState extends ConsumerState<_SpeechPractice> {
  final _recorder = SpeechRecorder();
  bool _recording = false;
  bool _uploading = false;
  String? _transcript;
  String? _message;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _uploading = true;
        _message = null;
      });
      try {
        final bytes = await SpeechRecorder.readFile(path);
        final response = await ref.read(apiProvider).transcribe(
              audioBase64: base64Encode(bytes),
              mimeType: _recorder.mimeType,
              expectedText: widget.expectedText,
            );
        if (!mounted) return;
        final transcript = response['transcript'] as String? ?? '';
        setState(() {
          _transcript = transcript;
          _message = 'Terdengar: "$transcript"';
        });
        widget.onTranscript(transcript);
      } on ApiException catch (error) {
        if (!mounted) return;
        setState(() {
          _message = error.code == 'STT_NOT_CONFIGURED'
              ? 'Server belum mengaktifkan STT. Ketik transkripsi secara manual.'
              : describeError(error);
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _message = 'Gagal memproses audio: $error');
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
      return;
    }

    try {
      setState(() => _message = null);
      await _recorder.start();
      setState(() => _recording = true);
    } catch (error) {
      setState(() => _message = 'Mikrofon tidak tersedia atau izin ditolak: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TactileButton(
          height: 56,
          variant: _recording ? ButtonVariant.danger : ButtonVariant.secondary,
          onPressed: widget.checked || _uploading ? null : _toggleRecording,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(_recording
                  ? 'BERHENTI & KIRIM'
                  : _uploading
                      ? 'MENGIRIM...'
                      : 'REKAM SUARA'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_message != null)
          Text(_message!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        TextField(
          controller: _transcript == null ? null : TextEditingController(text: _transcript),
          enabled: !widget.checked,
          onChanged: widget.onTranscript,
          decoration: InputDecoration(
            labelText: 'Transkripsi (bisa diedit sebelum diperiksa)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
