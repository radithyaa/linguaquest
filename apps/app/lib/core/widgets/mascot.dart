import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum MascotMood {
  happy,
  cheering,
  thinking,
  sad,
  celebrating,
}

class MascotWidget extends StatelessWidget {
  final MascotMood mood;
  final double size;

  const MascotWidget({
    super.key,
    this.mood = MascotMood.happy,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    // Custom vector depiction of LinguaQuest mascot
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Body
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreenDark,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
          // Belly patch
          Positioned(
            bottom: size * 0.12,
            child: Container(
              width: size * 0.55,
              height: size * 0.45,
              decoration: const BoxDecoration(
                color: Color(0xFF8CE62A),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Eyes
          Positioned(
            top: size * 0.28,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEye(),
                SizedBox(width: size * 0.12),
                _buildEye(),
              ],
            ),
          ),
          // Beak
          Positioned(
            top: size * 0.46,
            child: Container(
              width: size * 0.22,
              height: size * 0.14,
              decoration: BoxDecoration(
                color: AppColors.streakOrange,
                borderRadius: BorderRadius.circular(size * 0.08),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.streakOrangeDark,
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          // Mood accessories or arms
          if (mood == MascotMood.cheering || mood == MascotMood.celebrating)
            Positioned(
              top: size * 0.1,
              child: const Icon(Icons.star, color: AppColors.jewelGold, size: 28),
            ),
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: size * 0.22,
      height: size * 0.22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: mood == MascotMood.sad
          ? const Icon(Icons.close, size: 14, color: AppColors.textMain)
          : Container(
              width: size * 0.10,
              height: size * 0.10,
              decoration: const BoxDecoration(
                color: AppColors.textMain,
                shape: BoxShape.circle,
              ),
            ),
    );
  }
}
