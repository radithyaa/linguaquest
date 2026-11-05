// Shell utama: AppBar dengan statistik server, navigasi adaptif, dan banner sync.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/colors.dart';
import '../core/widgets/stat_badge.dart';
import '../data/api/models.dart';
import '../data/models/app_models.dart';
import '../features/admin/admin_cms_dialog.dart';
import '../features/league/league_view.dart';
import '../features/learn/learn_view.dart';
import '../features/practice/practice_view.dart';
import '../features/profile/profile_view.dart';
import '../features/quests/quests_view.dart';
import '../features/shop/shop_view.dart';
import '../state/providers.dart';
import '../state/session_controller.dart';
import 'lesson_screen.dart';
import 'labels.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  static const _destinations = [
    (Icons.school_rounded, 'Belajar'),
    (Icons.fitness_center_rounded, 'Latihan'),
    (Icons.flag_rounded, 'Quest'),
    (Icons.shield_rounded, 'Liga'),
    (Icons.storefront_rounded, 'Toko'),
    (Icons.person_rounded, 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = ref.read(sessionControllerProvider.notifier);
      await controller.refreshServerInfo();
      final pending = await controller.pendingOpsCount();
      if (pending > 0) await _sync(pending: pending);
    });
  }

  Future<void> _sync({int? pending}) async {
    final controller = ref.read(sessionControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await controller.syncPending();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(count == 0 ? 'Tidak ada data offline untuk disinkronkan.' : '$count operasi offline tersinkron.'),
        backgroundColor: AppColors.primaryGreen,
      ));
      ref.invalidate(pendingOpsProvider);
      ref.invalidate(curriculumProvider);
      ref.invalidate(profileProvider);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Sinkronisasi gagal: ${describeError(error)}'),
        backgroundColor: AppColors.heartRed,
      ));
    }
  }

  Future<void> _openLesson(LessonNode node) async {
    final summary = await Navigator.of(context).push<SessionSummary>(
      MaterialPageRoute(builder: (_) => LessonScreen(node: node)),
    );
    if (summary == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${node.title}: +${summary.xpEarned} XP, akurasi ${(summary.accuracy * 100).round()}%'),
      backgroundColor: AppColors.primaryGreen,
    ));
    ref.invalidate(curriculumProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(practiceProvider);
    ref.invalidate(questsProvider);
    ref.invalidate(leagueProvider);
  }

  void _showAdminDialog() {
    showDialog(
      context: context,
      builder: (_) => AdminCmsDialog(
        onCourseAdded: () {
          ref.invalidate(curriculumProvider);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unit baru tersimpan di server.'),
            backgroundColor: AppColors.primaryGreen,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final stats = ref.watch(statsProvider);
    final server = ref.watch(serverInfoProvider);
    final pending = ref.watch(pendingOpsProvider).valueOrNull ?? 0;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final effectiveStats = profile?.stats ?? stats;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.translate_rounded, color: AppColors.primaryGreen, size: 28),
            const SizedBox(width: 8),
            const Text(
              'LinguaQuest',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 10),
            _ConnectionDot(online: server.online, database: server.database),
          ],
        ),
        actions: [
          if (pending > 0)
            IconButton(
              tooltip: '$pending operasi offline menunggu sinkronisasi',
              onPressed: () => _sync(pending: pending),
              icon: Badge(
                label: Text('$pending'),
                child: const Icon(Icons.cloud_upload_rounded, color: AppColors.skyBlue),
              ),
            ),
          StatBadge(type: StatType.streak, count: effectiveStats.streak),
          StatBadge(type: StatType.gems, count: effectiveStats.gems),
          StatBadge(type: StatType.hearts, count: effectiveStats.hearts),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.textMuted),
            tooltip: 'Admin CMS',
            onPressed: _showAdminDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
            tooltip: 'Keluar',
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in _destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.$1),
                    label: Text(destination.$2),
                  ),
              ],
            ),
          Expanded(child: _buildTab()),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.$1),
                    label: destination.$2,
                  ),
              ],
            ),
    );
  }

  Widget _buildTab() {
    switch (_currentIndex) {
      case 0:
        return LearnView(onSelectLesson: _openLesson);
      case 1:
        return const PracticeView();
      case 2:
        return const QuestsView();
      case 3:
        return const LeagueView();
      case 4:
        return const ShopView();
      case 5:
        return const ProfileView();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.online, required this.database});

  final bool online;
  final String database;

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.primaryGreen : AppColors.heartRed;
    final label = online ? database : 'offline';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
