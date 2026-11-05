// Model domain klien: pengguna, statistik, sesi, toko, quest, dan liga.

import 'package:flutter/material.dart';

import '../api/models.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.isGuest,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String email;
  final String displayName;
  final bool isGuest;
  final String? avatarUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        isGuest: json['isGuest'] as bool? ?? false,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

class StatsState {
  const StatsState({
    required this.totalXp,
    required this.level,
    required this.streak,
    required this.longestStreak,
    required this.hearts,
    required this.gems,
    required this.freezesAvailable,
    required this.dailyGoalXp,
    required this.xpToday,
    required this.nextHeartSeconds,
    required this.heartsUpdatedAt,
  });

  final int totalXp;
  final int level;
  final int streak;
  final int longestStreak;
  final int hearts;
  final int gems;
  final int freezesAvailable;
  final int dailyGoalXp;
  final int xpToday;
  final int nextHeartSeconds;
  final DateTime heartsUpdatedAt;

  static final StatsState empty = StatsState(
    totalXp: 0,
    level: 1,
    streak: 0,
    longestStreak: 0,
    hearts: 5,
    gems: 0,
    freezesAvailable: 0,
    dailyGoalXp: 20,
    xpToday: 0,
    nextHeartSeconds: 0,
    heartsUpdatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory StatsState.fromJson(Map<String, dynamic> json) => StatsState(
        totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
        hearts: (json['hearts'] as num?)?.toInt() ?? 0,
        gems: (json['gems'] as num?)?.toInt() ?? 0,
        freezesAvailable: (json['freezesAvailable'] as num?)?.toInt() ?? 0,
        dailyGoalXp: (json['dailyGoalXp'] as num?)?.toInt() ?? 20,
        xpToday: (json['xpToday'] as num?)?.toInt() ?? 0,
        nextHeartSeconds: (json['nextHeartSeconds'] as num?)?.toInt() ?? 0,
        heartsUpdatedAt: DateTime.tryParse(json['heartsUpdatedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'level': level,
        'streak': streak,
        'longestStreak': longestStreak,
        'hearts': hearts,
        'gems': gems,
        'freezesAvailable': freezesAvailable,
        'dailyGoalXp': dailyGoalXp,
        'xpToday': xpToday,
        'nextHeartSeconds': nextHeartSeconds,
        'heartsUpdatedAt': heartsUpdatedAt.toIso8601String(),
      };
}

class Achievement {
  const Achievement({
    required this.code,
    required this.title,
    required this.description,
    required this.progress,
    required this.unlocked,
  });

  final String code;
  final String title;
  final String description;
  final double progress;
  final bool unlocked;

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        unlocked: json['unlocked'] as bool? ?? false,
      );
}

class Profile {
  const Profile({
    required this.user,
    required this.stats,
    required this.leagueTier,
    required this.achievements,
  });

  final UserProfile user;
  final StatsState stats;
  final String leagueTier;
  final List<Achievement> achievements;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        user: UserProfile.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ?? const {}),
        stats: StatsState.fromJson((json['stats'] as Map?)?.cast<String, dynamic>() ?? const {}),
        leagueTier: json['leagueTier'] as String? ?? 'bronze',
        achievements: (json['achievements'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(Achievement.fromJson)
                .toList() ??
            const [],
      );
}

class AnswerResult {
  const AnswerResult({
    required this.exerciseId,
    required this.isCorrect,
    required this.typoWarning,
    required this.correctAnswer,
    this.explanation,
  });

  final String exerciseId;
  final bool isCorrect;
  final bool typoWarning;
  final String correctAnswer;
  final String? explanation;

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
        exerciseId: json['exerciseId'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
        typoWarning: json['typoWarning'] as bool? ?? false,
        correctAnswer: json['correctAnswer'] as String? ?? '',
        explanation: json['explanation'] as String?,
      );
}

class SessionSummary {
  const SessionSummary({
    required this.lessonId,
    required this.nodeId,
    required this.totalQuestions,
    required this.correctCount,
    required this.accuracy,
    required this.maxCombo,
    required this.xpEarned,
    required this.gemsEarned,
    required this.heartsLost,
    required this.isMastered,
    required this.streak,
    required this.stats,
    required this.answers,
  });

  final String lessonId;
  final String nodeId;
  final int totalQuestions;
  final int correctCount;
  final double accuracy;
  final int maxCombo;
  final int xpEarned;
  final int gemsEarned;
  final int heartsLost;
  final bool isMastered;
  final int streak;
  final StatsState stats;
  final List<AnswerResult> answers;

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
        lessonId: json['lessonId'] as String? ?? '',
        nodeId: json['nodeId'] as String? ?? '',
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        maxCombo: (json['maxCombo'] as num?)?.toInt() ?? 0,
        xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
        gemsEarned: (json['gemsEarned'] as num?)?.toInt() ?? 0,
        heartsLost: (json['heartsLost'] as num?)?.toInt() ?? 0,
        isMastered: json['isMastered'] as bool? ?? false,
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        stats: StatsState.fromJson((json['stats'] as Map?)?.cast<String, dynamic>() ?? const {}),
        answers: (json['answers'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(AnswerResult.fromJson)
                .toList() ??
            const [],
      );
}

class StartedSession {
  const StartedSession({
    required this.sessionId,
    required this.lessonId,
    required this.nodeId,
    required this.exercises,
    required this.hearts,
    required this.expiresAt,
  });

  final String sessionId;
  final String lessonId;
  final String nodeId;
  final List<Exercise> exercises;
  final int hearts;
  final DateTime expiresAt;

  factory StartedSession.fromJson(Map<String, dynamic> json) => StartedSession(
        sessionId: json['sessionId'] as String? ?? '',
        lessonId: json['lessonId'] as String? ?? '',
        nodeId: json['nodeId'] as String? ?? '',
        exercises: (json['exercises'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(Exercise.fromJson)
                .toList() ??
            const [],
        hearts: (json['hearts'] as num?)?.toInt() ?? 5,
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class SrsCardState {
  const SrsCardState({
    required this.id,
    required this.word,
    required this.translation,
    required this.stability,
    required this.difficulty,
    required this.dueAt,
    required this.reps,
    required this.lapses,
    required this.retrievability,
    required this.intervalDays,
  });

  final String id;
  final String word;
  final String translation;
  final double stability;
  final double difficulty;
  final DateTime dueAt;
  final int reps;
  final int lapses;
  final double retrievability;
  final double intervalDays;

  factory SrsCardState.fromJson(Map<String, dynamic> json) => SrsCardState(
        id: json['id'] as String? ?? '',
        word: json['word'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
        stability: (json['stability'] as num?)?.toDouble() ?? 0,
        difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0,
        dueAt: DateTime.tryParse(json['dueAt'] as String? ?? '') ?? DateTime.now(),
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        lapses: (json['lapses'] as num?)?.toInt() ?? 0,
        retrievability: (json['retrievability'] as num?)?.toDouble() ?? 0,
        intervalDays: (json['intervalDays'] as num?)?.toDouble() ?? 0,
      );
}

class Mistake {
  const Mistake({
    required this.exerciseId,
    required this.prompt,
    required this.correctAnswer,
    required this.yourAnswer,
    required this.occurredAt,
  });

  final String exerciseId;
  final String prompt;
  final String correctAnswer;
  final String yourAnswer;
  final DateTime occurredAt;

  factory Mistake.fromJson(Map<String, dynamic> json) => Mistake(
        exerciseId: json['exerciseId'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        correctAnswer: json['correctAnswer'] as String? ?? '',
        yourAnswer: json['yourAnswer'] as String? ?? '',
        occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class PracticeOverview {
  const PracticeOverview({
    required this.dueNow,
    required this.upcoming,
    required this.mastered,
    required this.mistakes,
  });

  final List<SrsCardState> dueNow;
  final List<SrsCardState> upcoming;
  final List<SrsCardState> mastered;
  final List<Mistake> mistakes;

  static const PracticeOverview empty =
      PracticeOverview(dueNow: [], upcoming: [], mastered: [], mistakes: []);

  factory PracticeOverview.fromJson(Map<String, dynamic> json) => PracticeOverview(
        dueNow: _cards(json['dueNow']),
        upcoming: _cards(json['upcoming']),
        mastered: _cards(json['mastered']),
        mistakes: (json['mistakes'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(Mistake.fromJson)
                .toList() ??
            const [],
      );

  static List<SrsCardState> _cards(dynamic value) =>
      (value as List?)?.whereType<Map<String, dynamic>>().map(SrsCardState.fromJson).toList() ??
      const [];
}

class ShopItem {
  const ShopItem({
    required this.sku,
    required this.title,
    required this.description,
    required this.priceGems,
    required this.icon,
    required this.color,
    required this.available,
    required this.owned,
  });

  final String sku;
  final String title;
  final String description;
  final int priceGems;
  final String icon;
  final String color;
  final bool available;
  final bool owned;

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        sku: json['sku'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        priceGems: (json['priceGems'] as num?)?.toInt() ?? 0,
        icon: json['icon'] as String? ?? 'store',
        color: json['color'] as String? ?? '#1CB0F6',
        available: json['available'] as bool? ?? true,
        owned: json['owned'] as bool? ?? false,
      );

  Color get displayColor {
    final value = int.tryParse(color.replaceFirst('#', ''), radix: 16);
    return value == null ? const Color(0xFF1CB0F6) : Color(0xFF000000 | value);
  }
}

class Quest {
  const Quest({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.progress,
    required this.target,
    required this.rewardGems,
    required this.completed,
    required this.claimed,
  });

  final String code;
  final String title;
  final String description;
  final String icon;
  final String color;
  final int progress;
  final int target;
  final int rewardGems;
  final bool completed;
  final bool claimed;

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? 'flag',
        color: json['color'] as String? ?? '#1CB0F6',
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 1,
        rewardGems: (json['rewardGems'] as num?)?.toInt() ?? 0,
        completed: json['completed'] as bool? ?? false,
        claimed: json['claimed'] as bool? ?? false,
      );

  Color get displayColor {
    final value = int.tryParse(color.replaceFirst('#', ''), radix: 16);
    return value == null ? const Color(0xFF1CB0F6) : Color(0xFF000000 | value);
  }
}

class MonthlyQuest {
  const MonthlyQuest({
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.rewardTitle,
  });

  final String title;
  final String description;
  final int progress;
  final int target;
  final String rewardTitle;

  factory MonthlyQuest.fromJson(Map<String, dynamic> json) => MonthlyQuest(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 1,
        rewardTitle: json['rewardTitle'] as String? ?? '',
      );

  double get ratio => target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);
}

class QuestOverview {
  const QuestOverview({required this.daily, required this.monthly});

  final List<Quest> daily;
  final MonthlyQuest monthly;

  factory QuestOverview.fromJson(Map<String, dynamic> json) => QuestOverview(
        daily: (json['daily'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(Quest.fromJson)
                .toList() ??
            const [],
        monthly: MonthlyQuest.fromJson(
            (json['monthly'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}

class LeagueEntry {
  const LeagueEntry({
    required this.rank,
    required this.displayName,
    required this.username,
    required this.weeklyXp,
    required this.isCurrentUser,
  });

  final int rank;
  final String displayName;
  final String username;
  final int weeklyXp;
  final bool isCurrentUser;

  factory LeagueEntry.fromJson(Map<String, dynamic> json) => LeagueEntry(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        displayName: json['displayName'] as String? ?? '',
        username: json['username'] as String? ?? '',
        weeklyXp: (json['weeklyXp'] as num?)?.toInt() ?? 0,
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      );
}

class LeagueOverview {
  const LeagueOverview({
    required this.seasonId,
    required this.tier,
    required this.nextTier,
    required this.endsAt,
    required this.promotionCutoff,
    required this.demotionCutoff,
    required this.currentUserRank,
    required this.entries,
  });

  final String seasonId;
  final String tier;
  final String? nextTier;
  final DateTime endsAt;
  final int promotionCutoff;
  final int demotionCutoff;
  final int currentUserRank;
  final List<LeagueEntry> entries;

  factory LeagueOverview.fromJson(Map<String, dynamic> json) => LeagueOverview(
        seasonId: json['seasonId'] as String? ?? '',
        tier: json['tier'] as String? ?? 'bronze',
        nextTier: json['nextTier'] as String?,
        endsAt: DateTime.tryParse(json['endsAt'] as String? ?? '') ?? DateTime.now(),
        promotionCutoff: (json['promotionCutoff'] as num?)?.toInt() ?? 5,
        demotionCutoff: (json['demotionCutoff'] as num?)?.toInt() ?? 26,
        currentUserRank: (json['currentUserRank'] as num?)?.toInt() ?? 0,
        entries: (json['entries'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(LeagueEntry.fromJson)
                .toList() ??
            const [],
      );
}

/// Ulasan FSRS yang direkam offline (antrean sinkronisasi).
class OfflineReview {
  const OfflineReview({
    required this.clientOpId,
    required this.cardId,
    required this.rating,
    required this.reviewedAt,
  });

  final String clientOpId;
  final String cardId;
  final int rating;
  final DateTime reviewedAt;

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'rating': rating,
        'reviewedAt': reviewedAt.toUtc().toIso8601String(),
        'clientOpId': clientOpId,
      };
}

/// Sesi pelajaran yang diselesaikan saat offline (Drift/SQLite).
class OfflineSession {
  const OfflineSession({
    required this.clientOpId,
    required this.nodeId,
    required this.lessonId,
    required this.startedAt,
    required this.completedAt,
    required this.durationMs,
    required this.answers,
  });

  final String clientOpId;
  final String nodeId;
  final String lessonId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationMs;
  final List<Map<String, String>> answers;

  Map<String, dynamic> toJson() => {
        'clientOpId': clientOpId,
        'nodeId': nodeId,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'completedAt': completedAt.toUtc().toIso8601String(),
        'durationMs': durationMs,
        'answers': answers
            .map((a) => {'exerciseId': a['exerciseId'], 'answer': a['answer'], 'durationMs': 0})
            .toList(),
      };
}
