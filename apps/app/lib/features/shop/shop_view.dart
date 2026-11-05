// Toko virtual: katalog & pembelian dari server (ledger gems transaksional).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/api/api_client.dart';
import '../../data/models/app_models.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../../ui/labels.dart';

class ShopView extends ConsumerWidget {
  const ShopView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopProvider);
    final stats = ref.watch(statsProvider);

    return shop.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(describeError(error))),
      data: (items) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.jewelGold, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'SUPER LINGUAQUEST',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hearts tanpa batas, bebas iklan, dan ulasan kosakata FSRS tanpa batas.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  'Saldo Gems kamu: ${stats.gems}',
                  style: const TextStyle(color: AppColors.jewelGold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Toko Gems',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...items.map((item) => _ShopTile(item: item)),
        ],
      ),
    );
  }
}

class _ShopTile extends ConsumerStatefulWidget {
  const _ShopTile({required this.item});

  final ShopItem item;

  @override
  ConsumerState<_ShopTile> createState() => _ShopTileState();
}

class _ShopTileState extends ConsumerState<_ShopTile> {
  bool _busy = false;

  Future<void> _buy() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stats = await ref.read(sessionControllerProvider.notifier).buy(widget.item.sku);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('${widget.item.title} berhasil! Sisa ${stats.gems} Gems.'),
        backgroundColor: AppColors.primaryGreen,
      ));
      ref.invalidate(shopProvider);
      ref.invalidate(profileProvider);
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(error.canWorkOffline
            ? 'Offline: pembelian dicatat dan akan disinkronkan saat online.'
            : describeError(error)),
        backgroundColor: error.canWorkOffline ? AppColors.skyBlue : AppColors.heartRed,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final disabled = !item.available || item.owned || _busy;

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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.displayColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconByName(item.icon), color: item.displayColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 3),
                Text(item.description,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                if (item.owned)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Sudah dimiliki',
                        style: TextStyle(color: AppColors.primaryGreen, fontSize: 11)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TactileButton(
            height: 42,
            variant: ButtonVariant.secondary,
            onPressed: disabled ? null : _buy,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond_rounded, size: 16),
                const SizedBox(width: 4),
                Text('${item.priceGems}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
