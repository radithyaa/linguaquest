// Profil pengguna: identitas, statistik, liga, dan pencapaian dari server.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../state/providers.dart';
import '../../ui/labels.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(describeError(error))),
      data: (value) {
        if (value == null) return const Center(child: Text('Belum masuk.'));
        final stats = value.stats;
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileProvider);
            await ref.read(profileProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.primaryGreen,
                    child: Text(
                      value.user.displayName.isEmpty
                          ? '?'
                          : value.user.displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 30, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(value.user.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
                        const SizedBox(height: 2),
                        Text('@${value.user.username}',
                            style: const TextStyle(color: AppColors.textMuted)),
                        if (value.user.isGuest)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Akun tamu — data tersimpan di server ini',
                                style: TextStyle(fontSize: 11, color: AppColors.streakOrangeDark)),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreenLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Level ${stats.level} • ${stats.xpToday}/${stats.dailyGoalXp} XP hari ini',
                            style: const TextStyle(
                                color: AppColors.primaryGreenDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Statistik Belajar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  _statCard(Icons.local_fire_department_rounded, AppColors.streakOrange,
                      '${stats.streak} Hari', 'Streak Saat Ini'),
                  _statCard(Icons.bolt_rounded, AppColors.jewelGold, '${stats.totalXp} XP',
                      'Total XP'),
                  _statCard(Icons.shield_rounded, tierColor(value.leagueTier),
                      tierLabel(value.leagueTier), 'Liga Saat Ini'),
                  _statCard(Icons.diamond_rounded, AppColors.skyBlue, '${stats.gems}', 'Gems'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: AppColors.heartRed, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Hearts ${stats.hearts}/5'
                    '${stats.hearts >= 5 ? " (penuh)" : " • berikutnya dalam ${formatHeartCountdown(stats.nextHeartSeconds)}"}'
                    '${stats.freezesAvailable > 0 ? " • ${stats.freezesAvailable} Streak Freeze" : ""}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Pencapaian & Lencana',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...value.achievements.map(
                (achievement) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        achievement.unlocked
                            ? Icons.military_tech_rounded
                            : Icons.lock_outline_rounded,
                        color: achievement.unlocked ? AppColors.jewelGold : AppColors.textLight,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(achievement.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 3),
                            Text(achievement.description,
                                style:
                                    const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: achievement.progress,
                                minHeight: 6,
                                backgroundColor: AppColors.borderLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  achievement.unlocked
                                      ? AppColors.primaryGreen
                                      : AppColors.jewelGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
