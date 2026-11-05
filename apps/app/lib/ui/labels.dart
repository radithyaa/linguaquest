// Util bersama lapisan UI: tema, format, ikon, dan penerjemah error API.

import 'package:flutter/material.dart';

import '../core/constants/colors.dart';
import '../data/api/api_client.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
    useMaterial3: true,
    fontFamily: 'Inter',
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Mengubah error teknis menjadi pesan yang ramah pengguna.
String describeError(Object error) {
  if (error is ApiException) {
    if (error.isNetwork) {
      return 'Server belum dapat dihubungi. Periksa koneksi atau alamat server.';
    }
    return error.detail;
  }
  return error.toString();
}

/// Ikon Material dari nama ikon yang dikirim server.
IconData iconByName(String name) => switch (name) {
      'favorite' => Icons.favorite_rounded,
      'ac_unit' => Icons.ac_unit_rounded,
      'bolt' => Icons.bolt_rounded,
      'check_circle' => Icons.check_circle_rounded,
      'track_changes' => Icons.track_changes_rounded,
      'shield' => Icons.shield_rounded,
      'flag' => Icons.flag_rounded,
      'diamond' => Icons.diamond_rounded,
      _ => Icons.widgets_rounded,
    };

String tierLabel(String tier) => switch (tier) {
      'bronze' => 'Perunggu',
      'silver' => 'Perak',
      'gold' => 'Emas',
      'sapphire' => 'Safir',
      'ruby' => 'Rubi',
      'emerald' => 'Emerald',
      'amethyst' => 'Amethyst',
      'pearl' => 'Mutiara',
      'obsidian' => 'Obsidian',
      'diamond' => 'Diamond',
      _ => tier,
    };

Color tierColor(String tier) => switch (tier) {
      'bronze' => const Color(0xFFCD7F32),
      'silver' => const Color(0xFF9E9E9E),
      'gold' => AppColors.jewelGold,
      'sapphire' => const Color(0xFF0F52BA),
      'ruby' => const Color(0xFFC2185B),
      'emerald' => AppColors.primaryGreen,
      'amethyst' => AppColors.jewelPurple,
      'pearl' => const Color(0xFFB0BEC5),
      'obsidian' => const Color(0xFF37474F),
      'diamond' => AppColors.skyBlue,
      _ => AppColors.borderLight,
    };

/// Format durasi singkat, mis. "2 hari 14 jam".
String formatCountdown(Duration duration) {
  if (duration.isNegative) return 'berakhir';
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  if (days > 0) return '$days hari $hours jam';
  if (hours > 0) return '$hours jam ${duration.inMinutes % 60} menit';
  return '${duration.inMinutes} menit';
}

String formatIntervalDays(double days) {
  if (days < 1) return 'hari ini';
  if (days < 2) return 'besok';
  return '${days.toStringAsFixed(0)} hari';
}

String formatHeartCountdown(int seconds) {
  if (seconds <= 0) return 'penuh';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0) return '$hours jam $minutes menit';
  return '$minutes menit';
}
