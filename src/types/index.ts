export type TabType = 'learn' | 'practice' | 'quests' | 'league' | 'shop' | 'profile';

export type ExerciseKind = 
  | 'multiple_choice'
  | 'word_bank'
  | 'typing_translation'
  | 'audio_listening'
  | 'pair_matching'
  | 'fill_in_the_blank'
  | 'interactive_story';

export interface ExerciseOption {
  id: string;
  text: string;
  translation?: string;
  image?: string;
}

export interface WordPair {
  id: string;
  source: string;
  target: string;
}

export interface StoryDialogStep {
  speaker: string;
  speakerAvatar: string;
  text: string;
  translation: string;
  audioText?: string;
}

export interface Exercise {
  id: string;
  lessonId: string;
  kind: ExerciseKind;
  position: number;
  prompt: string;
  promptSecondary?: string;
  targetSentence?: string; // Sentence in source language
  correctAnswer: string; // Correct answer string or normalized answer
  options?: ExerciseOption[]; // For multiple choice & fill in blank
  wordBank?: string[]; // Word tokens to construct sentence
  pairs?: WordPair[]; // For pair matching
  blankSentence?: string; // Sentence with "___" for fill in the blank
  audioPhrase?: string; // Text to speak via TTS
  storySteps?: StoryDialogStep[]; // For story node
  hint?: string;
  explanation?: string;
}

export type NodeKind = 'lesson' | 'review' | 'story' | 'checkpoint' | 'chest';
export type NodeStatus = 'locked' | 'unlocked' | 'mastered';

export interface LearningNode {
  id: string;
  unitId: string;
  position: number;
  kind: NodeKind;
  status: NodeStatus;
  title: string;
  subtitle: string;
  iconName?: string;
  rewardXp: number;
  rewardGems: number;
  totalExercises: number;
  exercises: Exercise[];
  chestClaimed?: boolean;
}

export interface GuidebookGrammar {
  title: string;
  explanation: string;
  examples: { source: string; translation: string }[];
}

export interface GuidebookPhrase {
  phrase: string;
  translation: string;
  audioText: string;
  context: string;
}

export interface UnitGuidebook {
  title: string;
  unitNumber: number;
  summary: string;
  culturalNote?: string;
  keyPhrases: GuidebookPhrase[];
  grammarTips: GuidebookGrammar[];
}

export interface Unit {
  id: string;
  courseId: string;
  unitNumber: number;
  title: string;
  description: string;
  color: string;
  shadowColor: string;
  guidebook: UnitGuidebook;
  nodes: LearningNode[];
}

export interface Course {
  id: string;
  title: string;
  fromLang: string;
  toLang: string;
  flag: string;
  totalLearners: string;
  units: Unit[];
}

export interface DailyQuest {
  id: string;
  title: string;
  description: string;
  current: number;
  target: number;
  unit: string;
  rewardGems: number;
  completed: boolean;
  claimed: boolean;
  icon: string;
}

export interface MonthlyQuest {
  id: string;
  title: string;
  badgeName: string;
  badgeIcon: string;
  current: number;
  target: number;
  daysRemaining: number;
}

export type LeagueTier = 
  | 'Bronze'
  | 'Silver'
  | 'Gold'
  | 'Sapphire'
  | 'Ruby'
  | 'Emerald'
  | 'Amethyst'
  | 'Pearl'
  | 'Obsidian'
  | 'Diamond';

export interface LeagueMember {
  id: string;
  username: string;
  displayName: string;
  avatarUrl: string;
  xp: number;
  isCurrentUser?: boolean;
  streak: number;
  isPro?: boolean;
}

export interface FSRSCard {
  id: string;
  word: string;
  translation: string;
  partOfSpeech: string;
  example: string;
  exampleTranslation: string;
  stability: number; // In days
  difficulty: number; // 1.0 to 10.0
  reps: number;
  lapses: number;
  dueAt: string; // ISO date
  lastReview?: string;
  retrievability: number; // 0.0 to 1.0
  masteryLevel: 'Baru' | 'Belajar' | 'Kuat' | 'Dikuasai';
}

export interface ShopItem {
  id: string;
  name: string;
  category: 'boost' | 'hearts' | 'cosmetic' | 'subscription';
  description: string;
  costGems?: number;
  priceIdr?: string;
  icon: string;
  purchased?: boolean;
  active?: boolean;
  badge?: string;
}

export interface AchievementBadge {
  id: string;
  title: string;
  description: string;
  tier: 'bronze' | 'silver' | 'gold' | 'diamond';
  progress: number;
  target: number;
  unlocked: boolean;
  icon: string;
}

export interface ActivityFeedItem {
  id: string;
  userDisplayName: string;
  userAvatar: string;
  action: string;
  target: string;
  timeAgo: string;
  kudosCount: number;
  hasKudosGiven: boolean;
}

export interface UserStats {
  id: string;
  username: string;
  displayName: string;
  avatarUrl: string;
  totalXp: number;
  level: number;
  streak: number;
  longestStreak: number;
  hearts: number; // Max 5
  maxHearts: number;
  gems: number;
  freezesAvailable: number;
  leagueTier: LeagueTier;
  leagueRank: number;
  weeklyXp: number;
  targetDailyXp: number;
  todayXp: number;
  isSuperSubscriber: boolean;
  activeOutfit: string;
  hasFreezeAppliedToday: boolean;
  wordsLearnedCount: number;
}
