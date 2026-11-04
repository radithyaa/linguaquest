import {
  UserStats,
  LeagueMember,
  DailyQuest,
  MonthlyQuest,
  FSRSCard,
  ShopItem,
  AchievementBadge,
  ActivityFeedItem
} from '../types';

export const initialUserStats: UserStats = {
  id: 'usr_me_01',
  username: 'lingua_warrior',
  displayName: 'Arya Pratama',
  avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
  totalXp: 3840,
  level: 14,
  streak: 7,
  longestStreak: 21,
  hearts: 5,
  maxHearts: 5,
  gems: 520,
  freezesAvailable: 1,
  leagueTier: 'Amethyst',
  leagueRank: 3,
  weeklyXp: 1450,
  targetDailyXp: 30, // Serius target
  todayXp: 25,
  isSuperSubscriber: false,
  activeOutfit: 'default',
  hasFreezeAppliedToday: false,
  wordsLearnedCount: 142
};

export const initialLeagueMembers: LeagueMember[] = [
  {
    id: 'user_1',
    username: 'maya_lang',
    displayName: 'Maya Kusuma',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
    xp: 1820,
    streak: 42,
    isPro: true
  },
  {
    id: 'user_2',
    username: 'kenji_tokyo',
    displayName: 'Kenji Sato',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    xp: 1610,
    streak: 15
  },
  {
    id: 'usr_me_01',
    username: 'lingua_warrior',
    displayName: 'Arya Pratama (Anda)',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    xp: 1450,
    isCurrentUser: true,
    streak: 7
  },
  {
    id: 'user_4',
    username: 'clara_be',
    displayName: 'Clara Oswald',
    avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
    xp: 1390,
    streak: 28,
    isPro: true
  },
  {
    id: 'user_5',
    username: 'david_r',
    displayName: 'David R.',
    avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    xp: 1320,
    streak: 19
  },
  // Promotion line here (Rank 1-5 promoted)
  {
    id: 'user_6',
    username: 'siti_rahma',
    displayName: 'Siti Rahma',
    avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    xp: 1210,
    streak: 9
  },
  {
    id: 'user_7',
    username: 'marcus_v',
    displayName: 'Marcus Vance',
    avatarUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80',
    xp: 1150,
    streak: 12
  },
  {
    id: 'user_8',
    username: 'dian_lestari',
    displayName: 'Dian Lestari',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
    xp: 980,
    streak: 4
  },
  {
    id: 'user_9',
    username: 'alex_f',
    displayName: 'Alexandre Fontaine',
    avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150&auto=format&fit=crop&q=80',
    xp: 910,
    streak: 18
  },
  {
    id: 'user_10',
    username: 'nadia_z',
    displayName: 'Nadia Zahra',
    avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
    xp: 840,
    streak: 6
  },
  {
    id: 'user_11',
    username: 'leo_park',
    displayName: 'Leo Park',
    avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150&auto=format&fit=crop&q=80',
    xp: 790,
    streak: 3
  },
  {
    id: 'user_12',
    username: 'rani_w',
    displayName: 'Rani Wijaya',
    avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
    xp: 740,
    streak: 14
  },
  {
    id: 'user_26',
    username: 'budi_santoso',
    displayName: 'Budi Santoso',
    avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
    xp: 220,
    streak: 1
  },
  {
    id: 'user_27',
    username: 'chloe_t',
    displayName: 'Chloe Taylor',
    avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150&auto=format&fit=crop&q=80',
    xp: 180,
    streak: 0
  },
  {
    id: 'user_28',
    username: 'kevin_lee',
    displayName: 'Kevin Lee',
    avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150&auto=format&fit=crop&q=80',
    xp: 150,
    streak: 0
  },
  {
    id: 'user_29',
    username: 'putri_ayu',
    displayName: 'Putri Ayu',
    avatarUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=150&auto=format&fit=crop&q=80',
    xp: 110,
    streak: 0
  },
  {
    id: 'user_30',
    username: 'hassan_k',
    displayName: 'Hassan Karim',
    avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
    xp: 80,
    streak: 0
  }
];

export const initialDailyQuests: DailyQuest[] = [
  {
    id: 'dq_1',
    title: 'Selesaikan 2 Sesi Belajar',
    description: 'Selesaikan 2 pelajaran atau cerita apapun hari ini',
    current: 1,
    target: 2,
    unit: 'sesi',
    rewardGems: 15,
    completed: false,
    claimed: false,
    icon: 'book'
  },
  {
    id: 'dq_2',
    title: 'Raih 30 XP Hari Ini',
    description: 'Capai target harian untuk mempertahankan streak api',
    current: 25,
    target: 30,
    unit: 'XP',
    rewardGems: 20,
    completed: false,
    claimed: false,
    icon: 'zap'
  },
  {
    id: 'dq_3',
    title: 'Akurasi Sempurna di 1 Latihan',
    description: 'Selesaikan 1 sesi dengan akurasi 90% ke atas',
    current: 1,
    target: 1,
    unit: 'kali',
    rewardGems: 10,
    completed: true,
    claimed: false,
    icon: 'target'
  }
];

export const initialMonthlyQuest: MonthlyQuest = {
  id: 'mq_nov_2026',
  title: 'Tantangan Petualang November 2026',
  badgeName: 'Lencana Mahkota Emas November',
  badgeIcon: 'crown',
  current: 22,
  target: 30,
  daysRemaining: 18
};

export const initialFSRSCards: FSRSCard[] = [
  {
    id: 'fsrs_1',
    word: 'Delicious',
    translation: 'Lezat / Enak sekali',
    partOfSpeech: 'Adjective (Kata Sifat)',
    example: 'This warm croissant is delicious!',
    exampleTranslation: 'Croissant hangat ini sangat lezat!',
    stability: 3.4,
    difficulty: 4.1,
    reps: 4,
    lapses: 0,
    dueAt: '2026-11-04T12:00:00Z',
    retrievability: 0.88,
    masteryLevel: 'Kuat'
  },
  {
    id: 'fsrs_2',
    word: 'Would like',
    translation: 'Menginginkan (bentuk sopan)',
    partOfSpeech: 'Modal Verb Phrase',
    example: 'I would like a cup of coffee, please.',
    exampleTranslation: 'Saya ingin secangkir kopi, tolong.',
    stability: 2.1,
    difficulty: 5.3,
    reps: 3,
    lapses: 1,
    dueAt: '2026-11-04T09:00:00Z',
    retrievability: 0.65,
    masteryLevel: 'Belajar'
  },
  {
    id: 'fsrs_3',
    word: 'Good morning',
    translation: 'Selamat pagi',
    partOfSpeech: 'Greeting (Salam)',
    example: 'Good morning, how can I help you today?',
    exampleTranslation: 'Selamat pagi, bagaimana saya bisa membantu Anda hari ini?',
    stability: 14.2,
    difficulty: 2.0,
    reps: 8,
    lapses: 0,
    dueAt: '2026-11-12T00:00:00Z',
    retrievability: 0.98,
    masteryLevel: 'Dikuasai'
  },
  {
    id: 'fsrs_4',
    word: 'Excuse me',
    translation: 'Permisi / Maaf',
    partOfSpeech: 'Expression',
    example: 'Excuse me, where is the nearest restroom?',
    exampleTranslation: 'Permisi, di mana toilet terdekat?',
    stability: 4.8,
    difficulty: 3.8,
    reps: 5,
    lapses: 0,
    dueAt: '2026-11-05T08:00:00Z',
    retrievability: 0.85,
    masteryLevel: 'Kuat'
  },
  {
    id: 'fsrs_5',
    word: 'Train station',
    translation: 'Stasiun kereta api',
    partOfSpeech: 'Compound Noun',
    example: 'The train station is two blocks away.',
    exampleTranslation: 'Stasiun kereta berjarak dua blok dari sini.',
    stability: 1.5,
    difficulty: 6.2,
    reps: 2,
    lapses: 1,
    dueAt: '2026-11-04T10:00:00Z',
    retrievability: 0.58,
    masteryLevel: 'Baru'
  }
];

export const initialShopItems: ShopItem[] = [
  {
    id: 'item_freeze',
    name: 'Streak Freeze (Pembeku Streak)',
    category: 'boost',
    description: 'Menjaga streak belajarmu tidak putus jika kamu melewatkan belajar selama 1 hari.',
    costGems: 200,
    icon: 'snowflake',
    badge: 'Paling Populer'
  },
  {
    id: 'item_heart_refill',
    name: 'Isi Penuh Hearts (+5 Nyawa)',
    category: 'hearts',
    description: 'Pulihkan seluruh 5 hearts kamu seketika agar dapat langsung melanjutkan sesi belajar tanpa menunggu.',
    costGems: 100,
    icon: 'heart'
  },
  {
    id: 'item_hat_adventurer',
    name: 'Topi Petualang Kiki',
    category: 'cosmetic',
    description: 'Pakaikan topi petualang legendaris pada maskot Kiki di jalur belajarmu!',
    costGems: 350,
    icon: 'hat',
    badge: 'Edisi Khusus'
  },
  {
    id: 'item_glasses_cool',
    name: 'Kacamata Hitam Kece',
    category: 'cosmetic',
    description: 'Gaya maskot Kiki menjadi ekstra stylish dengan kacamata retro hitam!',
    costGems: 250,
    icon: 'glasses'
  },
  {
    id: 'item_suit_gold',
    name: 'Jas Emas Juara Liga',
    category: 'cosmetic',
    description: 'Jas berkilau emas mewah untuk maskot yang mendominasi puncak liga mingguan!',
    costGems: 600,
    icon: 'sparkles'
  },
  {
    id: 'sub_super',
    name: 'LinguaQuest Super (Langganan)',
    category: 'subscription',
    description: 'Hearts tanpa batas selamanya, bebas iklan, review kesalahan pintar tak terbatas, dan unduh paket offline!',
    priceIdr: 'Rp 69.000 / bulan',
    icon: 'shield-check',
    badge: 'Akses Tak Terbatas'
  }
];

export const initialBadges: AchievementBadge[] = [
  {
    id: 'badge_streak_7',
    title: 'Penjaga Api Abadi',
    description: 'Pertahankan streak belajar selama 7 hari berturut-turut.',
    tier: 'bronze',
    progress: 7,
    target: 7,
    unlocked: true,
    icon: 'flame'
  },
  {
    id: 'badge_xp_1000',
    title: 'Pengumpul Energi',
    description: 'Kumpulkan total 3.000 XP dari pelajaran.',
    tier: 'silver',
    progress: 3840,
    target: 3000,
    unlocked: true,
    icon: 'zap'
  },
  {
    id: 'badge_words_100',
    title: 'Kamus Berjalan',
    description: 'Kuasai 100 kosakata bahasa asing dengan retrievability tinggi.',
    tier: 'gold',
    progress: 142,
    target: 100,
    unlocked: true,
    icon: 'book-open'
  },
  {
    id: 'badge_diamond_league',
    title: 'Juara Liga Tertinggi',
    description: 'Promosi dan raih peringkat 1 di Liga Diamond.',
    tier: 'diamond',
    progress: 7,
    target: 10,
    unlocked: false,
    icon: 'award'
  }
];

export const initialActivityFeed: ActivityFeedItem[] = [
  {
    id: 'feed_1',
    userDisplayName: 'Maya Kusuma',
    userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
    action: 'mencapai streak',
    target: '40 Hari Belajar!',
    timeAgo: '15 menit yang lalu',
    kudosCount: 14,
    hasKudosGiven: false
  },
  {
    id: 'feed_2',
    userDisplayName: 'Kenji Sato',
    userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    action: 'menyelesaikan',
    target: 'Unit 2: Frasa Sehari-hari',
    timeAgo: '1 jam yang lalu',
    kudosCount: 8,
    hasKudosGiven: true
  },
  {
    id: 'feed_3',
    userDisplayName: 'Clara Oswald',
    userAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
    action: 'promosi ke',
    target: 'Liga Diamond',
    timeAgo: '3 jam yang lalu',
    kudosCount: 22,
    hasKudosGiven: false
  }
];
