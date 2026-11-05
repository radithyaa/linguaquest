// Peta kurikulum dari server: unit, status node, dan panduan grammar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/api/models.dart';
import '../../state/session_controller.dart';
import '../../ui/labels.dart';

class LearnView extends ConsumerWidget {
  const LearnView({super.key, required this.onSelectLesson});

  final Future<void> Function(LessonNode node) onSelectLesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculum = ref.watch(curriculumProvider);

    return curriculum.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorState(
        message: describeError(error),
        onRetry: () => ref.invalidate(curriculumProvider),
      ),
      data: (snapshot) {
        final units = snapshot.curriculum.units;
        if (units.isEmpty) {
          return const Center(child: Text('Kurikulum belum tersedia di server.'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(curriculumProvider);
            await ref.read(curriculumProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            itemCount: units.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.curriculum.course.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    if (snapshot.fromCache)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Mode offline: menampilkan kurikulum dari penyimpanan lokal.',
                          style: TextStyle(fontSize: 12, color: AppColors.streakOrangeDark),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                );
              }
              final unit = units[index - 1];
              return _UnitSection(unit: unit, onSelectLesson: onSelectLesson);
            },
          ),
        );
      },
    );
  }
}

class _UnitSection extends StatelessWidget {
  const _UnitSection({required this.unit, required this.onSelectLesson});

  final LearningUnit unit;
  final Future<void> Function(LessonNode node) onSelectLesson;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 28),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: unit.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: unit.color.withOpacity(0.4),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNIT ${unit.position}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit.description,
                      style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TactileButton(
                variant: ButtonVariant.outline,
                height: 44,
                onPressed: () => _showGuidebook(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 20, color: AppColors.textMain),
                    SizedBox(width: 6),
                    Text('PANDUAN', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...unit.nodes.asMap().entries.map((entry) {
          const offsets = [0.0, 40.0, 0.0, -40.0];
          final shift = offsets[entry.key % offsets.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: Transform.translate(
              offset: Offset(shift, 0),
              child: _NodeButton(
                node: entry.value,
                color: unit.color,
                onTap: () => onSelectLesson(entry.value),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showGuidebook(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.skyBlue),
            const SizedBox(width: 8),
            Text('Panduan Unit ${unit.position}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(unit.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(unit.guidebook.summary.isEmpty ? unit.description : unit.guidebook.summary),
            if (unit.guidebook.grammarTips.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Tips Tata Bahasa:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...unit.guidebook.grammarTips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $tip'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('TUTUP', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _NodeButton extends StatelessWidget {
  const _NodeButton({required this.node, required this.color, required this.onTap});

  final LessonNode node;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = node.isLocked;
    final completed = node.isCompleted;
    final background = locked
        ? AppColors.borderLight
        : completed
            ? AppColors.jewelGold
            : color;
    final icon = locked
        ? Icons.lock_rounded
        : completed
            ? (node.isMastered ? Icons.workspace_premium_rounded : Icons.check_rounded)
            : Icons.star_rounded;

    return Center(
      child: Column(
        children: [
          TactileButton(
            height: 72,
            width: 76,
            depth: 6,
            variant: ButtonVariant.ghost,
            onPressed: locked ? null : onTap,
            child: Container(
              decoration: BoxDecoration(color: background, shape: BoxShape.circle),
              child: Center(child: Icon(icon, color: Colors.white, size: 34)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            node.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: locked ? AppColors.textLight : AppColors.textMain,
            ),
          ),
          if (!locked)
            Text(
              '${node.totalExercises} soal • ${node.kind}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TactileButton(onPressed: onRetry, height: 44, child: const Text('COBA LAGI')),
          ],
        ),
      ),
    );
  }
}
