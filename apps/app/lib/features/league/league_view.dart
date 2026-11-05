// Papan peringkat liga mingguan (data dari server + Redis ZSET).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../state/session_controller.dart';
import '../../ui/labels.dart';

class LeagueView extends ConsumerWidget {
  const LeagueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final league = ref.watch(leagueProvider);

    return league.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(describeError(error))),
      data: (overview) {
        final remaining = overview.endsAt.difference(DateTime.now().toUtc());
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leagueProvider);
            await ref.read(leagueProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_rounded, size: 52, color: tierColor(overview.tier)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LIGA ${tierLabel(overview.tier).toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            'Musim ${overview.seasonId} • sisa ${formatCountdown(remaining)}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            overview.nextTier == null
                                ? 'Tier tertinggi! Pertahankan posisimu.'
                                : 'Top ${overview.promotionCutoff} promosi ke ${tierLabel(overview.nextTier!)}!',
                            style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (overview.entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Belum ada peserta di grup ini. Selesaikan pelajaran untuk masuk peringkat.'),
                ),
              ...overview.entries.map((entry) {
                final promotion = entry.rank <= overview.promotionCutoff;
                final demotion = entry.rank >= overview.demotionCutoff;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: entry.isCurrentUser ? AppColors.skyBlueLight : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: entry.isCurrentUser ? AppColors.skyBlue : AppColors.borderLight,
                      width: entry.isCurrentUser ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${entry.rank}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: promotion
                                ? AppColors.primaryGreen
                                : demotion
                                    ? AppColors.heartRed
                                    : AppColors.textMain,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor:
                            entry.isCurrentUser ? AppColors.skyBlue : AppColors.borderLight,
                        child: Text(
                          entry.displayName.isEmpty ? '?' : entry.displayName.substring(0, 1),
                          style: TextStyle(
                            color: entry.isCurrentUser ? Colors.white : AppColors.textMain,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.isCurrentUser ? '${entry.displayName} (kamu)' : entry.displayName,
                          style: TextStyle(
                            fontWeight: entry.isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.weeklyXp} XP',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
