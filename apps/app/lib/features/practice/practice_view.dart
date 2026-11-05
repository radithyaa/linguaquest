// Hub latihan FSRS 4.5: kartu jatuh tempo dari server, ulasan berbasis Rust,
// tinjauan kesalahan, dan kamus kata yang dikuasai.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/api/api_client.dart';
import '../../data/models/app_models.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../../ui/labels.dart';

class PracticeView extends ConsumerStatefulWidget {
  const PracticeView({super.key});

  @override
  ConsumerState<PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends ConsumerState<PracticeView> {
  int _tab = 0;
  int _cardIndex = 0;
  bool _flipped = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final practice = ref.watch(practiceProvider);

    return practice.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sync_problem_rounded, size: 52, color: AppColors.textLight),
              const SizedBox(height: 12),
              Text(describeError(error), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TactileButton(onPressed: () => ref.invalidate(practiceProvider), child: const Text('COBA LAGI')),
            ],
          ),
        ),
      ),
      data: (overview) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hub Latihan & Ulasan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textMain),
            ),
            const SizedBox(height: 6),
            Text(
              '${overview.dueNow.length} kartu jatuh tempo • '
              '${overview.upcoming.length} terjadwal • '
              '${overview.mistakes.length} kesalahan untuk diulang',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tabButton('Kartu FSRS', 0),
                _tabButton('Review Salah', 1),
                _tabButton('Kamus Kata', 2),
              ],
            ),
            const SizedBox(height: 22),
            if (_tab == 0) _buildCards(overview),
            if (_tab == 1) _buildMistakes(overview),
            if (_tab == 2) _buildDictionary(overview),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) => TactileButton(
        variant: _tab == index ? ButtonVariant.secondary : ButtonVariant.outline,
        height: 42,
        onPressed: () => setState(() => _tab = index),
        child: Text(label, style: const TextStyle(fontSize: 14)),
      );

  Widget _buildCards(PracticeOverview overview) {
    if (overview.dueNow.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            const MascotWidget(mood: MascotMood.celebrating, size: 96),
            const SizedBox(height: 16),
            const Text('Semua Kartu Selesai Diulas!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              overview.upcoming.isEmpty
                  ? 'Selesaikan pelajaran untuk menambah kosakata baru.'
                  : 'Kartu berikutnya jatuh tempo ${formatIntervalDays(overview.upcoming.first.intervalDays)}.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TactileButton(
              onPressed: () => ref.invalidate(practiceProvider),
              child: const Text('MUAT ULANG'),
            ),
          ],
        ),
      );
    }

    final index = _cardIndex.clamp(0, overview.dueNow.length - 1);
    final card = overview.dueNow[index];

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _flipped = !_flipped),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), offset: Offset(0, 4), blurRadius: 12),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _flipped ? 'ARTI / TERJEMAHAN' : 'KOSAKATA',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _flipped ? card.translation : card.word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Retensi ${(card.retrievability * 100).round()}% • ${card.reps} ulasan',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ketuk untuk membalik kartu',
                    style: TextStyle(
                        color: AppColors.skyBlue, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Kartu ${index + 1} dari ${overview.dueNow.length}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (_flipped)
          Row(
            children: [
              _ratingButton('Again (1)', ButtonVariant.danger, card, 1),
              const SizedBox(width: 8),
              _ratingButton('Hard (2)', ButtonVariant.outline, card, 2),
              const SizedBox(width: 8),
              _ratingButton('Good (3)', ButtonVariant.secondary, card, 3),
              const SizedBox(width: 8),
              _ratingButton('Easy (4)', ButtonVariant.primary, card, 4),
            ],
          )
        else
          const Text(
            'Balik kartu untuk memilih tingkat ingatan.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        if (_busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Widget _ratingButton(String label, ButtonVariant variant, SrsCardState card, int rating) {
    return Expanded(
      child: TactileButton(
        variant: variant,
        height: 46,
        onPressed: _busy ? null : () => _rate(card, rating),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Future<void> _rate(SrsCardState card, int rating) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await ref
          .read(sessionControllerProvider.notifier)
          .reviewCard(card.id, rating);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('"${card.word}" dijadwalkan lagi ${formatIntervalDays(updated.intervalDays)}.'),
        backgroundColor: AppColors.primaryGreen,
      ));
      setState(() {
        _flipped = false;
        _cardIndex++;
      });
      ref.invalidate(practiceProvider);
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(error.code == 'QUEUED_OFFLINE'
            ? 'Offline: ulasan disimpan dan akan disinkronkan.'
            : describeError(error)),
        backgroundColor: error.code == 'QUEUED_OFFLINE' ? AppColors.skyBlue : AppColors.heartRed,
      ));
      setState(() {
        _flipped = false;
        _cardIndex++;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildMistakes(PracticeOverview overview) {
    if (overview.mistakes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryGreen, size: 48),
            SizedBox(height: 12),
            Text('Tidak ada kesalahan lampau!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 4),
            Text('Kamu menjawab soal-soal sesi terakhir dengan sangat baik.'),
          ],
        ),
      );
    }

    return Column(
      children: overview.mistakes.map((mistake) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.heartRedLight, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mistake.prompt, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Jawabanmu: ${mistake.yourAnswer}',
                  style: const TextStyle(color: AppColors.heartRedDark, fontSize: 13)),
              Text('Jawaban benar: ${mistake.correctAnswer}',
                  style: const TextStyle(color: AppColors.primaryGreenDark, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDictionary(PracticeOverview overview) {
    final cards = [...overview.mastered, ...overview.upcoming, ...overview.dueNow];
    if (cards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Belum ada kosakata. Selesaikan pelajaran untuk mulai mengumpulkan kata.'),
      );
    }

    final seen = <String>{};
    return Column(
      children: cards.where((card) => seen.add(card.id)).map((card) {
        final mastery = (card.retrievability * 100).round();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(card.translation, style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Chip(
                label: Text('Retensi $mastery%',
                    style: const TextStyle(fontSize: 12, color: AppColors.primaryGreenDark)),
                backgroundColor: AppColors.primaryGreenLight,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Dipakai pengujian widget.
String debugPractice(WidgetRef ref) => ref.watch(apiProvider).baseUrl;
