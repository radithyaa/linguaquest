// Quest harian & lencana bulanan dari server, termasuk klaim reward gems.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/api/api_client.dart';
import '../../data/models/app_models.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../../ui/labels.dart';

class QuestsView extends ConsumerWidget {
  const QuestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsProvider);

    return quests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(describeError(error))),
      data: (overview) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tantangan & Quest',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textMain),
            ),
            const SizedBox(height: 6),
            const Text(
              'Selesaikan misi harian untuk mendapatkan bonus Gems dan XP.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            _MonthlyQuestCard(monthly: overview.monthly),
            const SizedBox(height: 26),
            const Text('Misi Harian',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            ...overview.daily.map((quest) => _QuestTile(quest: quest)),
          ],
        ),
      ),
    );
  }
}

class _MonthlyQuestCard extends StatelessWidget {
  const _MonthlyQuestCard({required this.monthly});

  final MonthlyQuest monthly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.military_tech_rounded, color: Colors.amber, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthly.title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${monthly.description} (${monthly.progress}/${monthly.target})',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: monthly.ratio,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Hadiah: ${monthly.rewardTitle}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestTile extends ConsumerStatefulWidget {
  const _QuestTile({required this.quest});

  final Quest quest;

  @override
  ConsumerState<_QuestTile> createState() => _QuestTileState();
}

class _QuestTileState extends ConsumerState<_QuestTile> {
  bool _busy = false;

  Future<void> _claim() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stats = await ref.read(sessionControllerProvider.notifier).claimQuest(widget.quest.code);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('+${widget.quest.rewardGems} Gems diklaim. Total ${stats.gems} Gems.'),
        backgroundColor: AppColors.primaryGreen,
      ));
      ref.invalidate(questsProvider);
      ref.invalidate(profileProvider);
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(describeError(error)),
        backgroundColor: AppColors.heartRed,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final ratio = quest.target == 0 ? 0.0 : (quest.progress / quest.target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(iconByName(quest.icon), color: quest.displayColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(quest.description,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      quest.completed ? AppColors.primaryGreen : AppColors.skyBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${quest.progress} / ${quest.target}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (quest.claimed)
            const Chip(label: Text('DIKLAIM', style: TextStyle(fontSize: 11)))
          else if (quest.completed)
            TactileButton(
              height: 38,
              variant: ButtonVariant.primary,
              onPressed: _busy ? null : _claim,
              child: const Text('KLAIM', style: TextStyle(fontSize: 12)),
            )
          else
            Row(
              children: [
                const Icon(Icons.diamond_rounded, color: AppColors.skyBlue, size: 18),
                const SizedBox(width: 4),
                Text('+${quest.rewardGems}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.skyBlue)),
              ],
            ),
        ],
      ),
    );
  }
}
