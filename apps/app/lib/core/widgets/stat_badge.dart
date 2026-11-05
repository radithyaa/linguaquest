import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum StatType {
  streak,
  gems,
  hearts,
}

class StatBadge extends StatelessWidget {
  final StatType type;
  final int count;
  final VoidCallback? onTap;

  const StatBadge({
    super.key,
    required this.type,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case StatType.streak:
        icon = Icons.local_fire_department_rounded;
        color = AppColors.streakOrange;
        break;
      case StatType.gems:
        icon = Icons.diamond_rounded;
        color = AppColors.skyBlue;
        break;
      case StatType.hearts:
        icon = Icons.favorite_rounded;
        color = AppColors.heartRed;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
