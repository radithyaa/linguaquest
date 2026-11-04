import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  UserStats,
  Course,
  TabType,
  LearningNode,
  Unit,
  DailyQuest,
  MonthlyQuest,
  LeagueMember,
  FSRSCard,
  ShopItem,
  AchievementBadge,
  ActivityFeedItem,
  Exercise
} from '../types';
import { initialCourses } from '../data/curriculum';
import {
  initialUserStats,
  initialLeagueMembers,
  initialDailyQuests,
  initialMonthlyQuest,
  initialFSRSCards,
  initialShopItems,
  initialBadges,
  initialActivityFeed
} from '../data/mockData';
import { sound } from '../services/soundEffects';

interface AppContextType {
  activeTab: TabType;
  setActiveTab: (tab: TabType) => void;
  userStats: UserStats;
  courses: Course[];
  currentCourseId: string;
  currentCourse: Course;
  switchCourse: (courseId: string) => void;
  
  // Lesson Session
  activeLesson: LearningNode | null;
  startLesson: (node: LearningNode) => void;
  closeLesson: () => void;
  finishLesson: (nodeId: string, xpEarned: number, gemsEarned: number, accuracy: number) => void;
  
  // Guidebook & Modals
  activeGuidebookUnit: Unit | null;
  openGuidebook: (unit: Unit) => void;
  closeGuidebook: () => void;
  isCourseSelectOpen: boolean;
  setIsCourseSelectOpen: (open: boolean) => void;
  isHeartDepletedModalOpen: boolean;
  setIsHeartDepletedModalOpen: (open: boolean) => void;
  isAdminModalOpen: boolean;
  setIsAdminModalOpen: (open: boolean) => void;

  // Chest & Quests
  claimChest: (nodeId: string) => void;
  dailyQuests: DailyQuest[];
  claimQuest: (questId: string) => void;
  monthlyQuest: MonthlyQuest;

  // League
  leagueMembers: LeagueMember[];

  // FSRS & Practice
  fsrsCards: FSRSCard[];
  reviewFsrsCard: (cardId: string, rating: 1 | 2 | 3 | 4) => void;
  mistakesQueue: Exercise[];
  addMistakeToQueue: (exercise: Exercise) => void;
  clearMistakeFromQueue: (exerciseId: string) => void;

  // Shop & Customization
  shopItems: ShopItem[];
  buyShopItem: (item: ShopItem) => boolean;
  refillHearts: () => void;
  toggleSuperSubscription: () => void;
  equipOutfit: (outfitId: string) => void;

  // Badges & Social
  badges: AchievementBadge[];
  activityFeed: ActivityFeedItem[];
  sendKudos: (feedId: string) => void;

  // Hearts management
  deductHeart: () => boolean;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // Load state from localStorage or use defaults
  const [activeTab, setActiveTabState] = useState<TabType>('learn');
  const [courses, setCourses] = useState<Course[]>(() => {
    try {
      const saved = localStorage.getItem('lq_courses');
      return saved ? JSON.parse(saved) : initialCourses;
    } catch {
      return initialCourses;
    }
  });
  const [currentCourseId, setCurrentCourseId] = useState<string>('en_id');

  const [userStats, setUserStats] = useState<UserStats>(() => {
    try {
      const saved = localStorage.getItem('lq_user_stats');
      return saved ? JSON.parse(saved) : initialUserStats;
    } catch {
      return initialUserStats;
    }
  });

  const [activeLesson, setActiveLesson] = useState<LearningNode | null>(null);
  const [activeGuidebookUnit, setActiveGuidebookUnit] = useState<Unit | null>(null);
  const [isCourseSelectOpen, setIsCourseSelectOpen] = useState(false);
  const [isHeartDepletedModalOpen, setIsHeartDepletedModalOpen] = useState(false);
  const [isAdminModalOpen, setIsAdminModalOpen] = useState(false);

  const [dailyQuests, setDailyQuests] = useState<DailyQuest[]>(initialDailyQuests);
  const [monthlyQuest, setMonthlyQuest] = useState<MonthlyQuest>(initialMonthlyQuest);
  const [leagueMembers, setLeagueMembers] = useState<LeagueMember[]>(initialLeagueMembers);
  const [fsrsCards, setFsrsCards] = useState<FSRSCard[]>(initialFSRSCards);
  const [mistakesQueue, setMistakesQueue] = useState<Exercise[]>([]);
  const [shopItems, setShopItems] = useState<ShopItem[]>(initialShopItems);
  const [badges, setBadges] = useState<AchievementBadge[]>(initialBadges);
  const [activityFeed, setActivityFeed] = useState<ActivityFeedItem[]>(initialActivityFeed);

  // Sync with localStorage
  useEffect(() => {
    try {
      localStorage.setItem('lq_user_stats', JSON.stringify(userStats));
    } catch {
      // Ignore
    }
  }, [userStats]);

  useEffect(() => {
    try {
      localStorage.setItem('lq_courses', JSON.stringify(courses));
    } catch {
      // Ignore
    }
  }, [courses]);

  const setActiveTab = (tab: TabType) => {
    sound.playClick();
    setActiveTabState(tab);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const currentCourse = courses.find((c) => c.id === currentCourseId) || courses[0];

  const switchCourse = (courseId: string) => {
    sound.playClick();
    setCurrentCourseId(courseId);
    setIsCourseSelectOpen(false);
  };

  const openGuidebook = (unit: Unit) => {
    sound.playClick();
    setActiveGuidebookUnit(unit);
  };

  const closeGuidebook = () => {
    sound.playClick();
    setActiveGuidebookUnit(null);
  };

  const startLesson = (node: LearningNode) => {
    sound.playClick();
    if (userStats.hearts <= 0 && !userStats.isSuperSubscriber) {
      sound.playIncorrect();
      setIsHeartDepletedModalOpen(true);
      return;
    }
    setActiveLesson(node);
  };

  const closeLesson = () => {
    sound.playClick();
    setActiveLesson(null);
  };

  const deductHeart = (): boolean => {
    if (userStats.isSuperSubscriber) {
      return true; // Super subscriber doesn't lose hearts
    }
    if (userStats.hearts <= 1) {
      setUserStats((prev) => ({ ...prev, hearts: 0 }));
      setIsHeartDepletedModalOpen(true);
      return false;
    }
    setUserStats((prev) => ({ ...prev, hearts: Math.max(0, prev.hearts - 1) }));
    return true;
  };

  const refillHearts = () => {
    sound.playChestClaim();
    setUserStats((prev) => ({ ...prev, hearts: prev.maxHearts }));
    setIsHeartDepletedModalOpen(false);
  };

  const finishLesson = (nodeId: string, xpEarned: number, gemsEarned: number, accuracy: number) => {
    // Mark node as mastered and unlock next node in line
    setCourses((prevCourses) => {
      return prevCourses.map((crs) => {
        if (crs.id !== currentCourseId) return crs;
        return {
          ...crs,
          units: crs.units.map((unit) => {
            let nextUnlocked = false;
            return {
              ...unit,
              nodes: unit.nodes.map((node, idx) => {
                if (node.id === nodeId) {
                  nextUnlocked = true;
                  return { ...node, status: 'mastered' };
                }
                if (nextUnlocked && node.status === 'locked') {
                  nextUnlocked = false;
                  return { ...node, status: 'unlocked' };
                }
                return node;
              })
            };
          })
        };
      });
    });

    // Update user stats according to SRS Section 9.1
    setUserStats((prev) => {
      const newTotalXp = prev.totalXp + xpEarned;
      const newWeeklyXp = prev.weeklyXp + xpEarned;
      const newTodayXp = prev.todayXp + xpEarned;
      const newGems = prev.gems + gemsEarned;
      const newLevel = Math.floor(newTotalXp / 300) + 1;
      
      return {
        ...prev,
        totalXp: newTotalXp,
        weeklyXp: newWeeklyXp,
        todayXp: newTodayXp,
        gems: newGems,
        level: newLevel,
        wordsLearnedCount: prev.wordsLearnedCount + Math.floor(xpEarned / 5)
      };
    });

    // Update league leaderboard ranking dynamically
    setLeagueMembers((prevMembers) => {
      const updated = prevMembers.map((m) => {
        if (m.isCurrentUser) {
          return { ...m, xp: m.xp + xpEarned };
        }
        return m;
      });
      // Sort descending by XP
      return updated.sort((a, b) => b.xp - a.xp);
    });

    // Update daily quests
    setDailyQuests((prevQuests) => {
      return prevQuests.map((q) => {
        if (q.id === 'dq_1') {
          const nextCur = Math.min(q.target, q.current + 1);
          return { ...q, current: nextCur, completed: nextCur >= q.target };
        }
        if (q.id === 'dq_2') {
          const nextCur = Math.min(q.target, userStats.todayXp + xpEarned);
          return { ...q, current: nextCur, completed: nextCur >= q.target };
        }
        if (q.id === 'dq_3' && accuracy >= 90) {
          return { ...q, current: q.target, completed: true };
        }
        return q;
      });
    });

    // Close the lesson after finishing
    setActiveLesson(null);
  };

  const claimChest = (nodeId: string) => {
    sound.playChestClaim();
    setCourses((prev) =>
      prev.map((crs) => ({
        ...crs,
        units: crs.units.map((unit) => ({
          ...unit,
          nodes: unit.nodes.map((n) => {
            if (n.id === nodeId) {
              return { ...n, chestClaimed: true, status: 'mastered' };
            }
            return n;
          })
        }))
      }))
    );
    setUserStats((prev) => ({ ...prev, gems: prev.gems + 25 }));
  };

  const claimQuest = (questId: string) => {
    sound.playChestClaim();
    const quest = dailyQuests.find((q) => q.id === questId);
    if (!quest || !quest.completed || quest.claimed) return;

    setDailyQuests((prev) =>
      prev.map((q) => (q.id === questId ? { ...q, claimed: true } : q))
    );
    setUserStats((prev) => ({ ...prev, gems: prev.gems + quest.rewardGems }));
    setMonthlyQuest((prev) => ({
      ...prev,
      current: Math.min(prev.target, prev.current + 1)
    }));
  };

  const buyShopItem = (item: ShopItem): boolean => {
    if (item.costGems && userStats.gems < item.costGems) {
      sound.playIncorrect();
      return false;
    }

    sound.playChestClaim();
    if (item.costGems) {
      setUserStats((prev) => ({ ...prev, gems: prev.gems - item.costGems! }));
    }

    if (item.id === 'item_freeze') {
      setUserStats((prev) => ({ ...prev, freezesAvailable: prev.freezesAvailable + 1 }));
    } else if (item.id === 'item_heart_refill') {
      refillHearts();
    } else if (item.category === 'cosmetic') {
      setUserStats((prev) => ({ ...prev, activeOutfit: item.id }));
    } else if (item.id === 'sub_super') {
      setUserStats((prev) => ({ ...prev, isSuperSubscriber: true, hearts: 5 }));
    }
    return true;
  };

  const toggleSuperSubscription = () => {
    sound.playChestClaim();
    setUserStats((prev) => ({
      ...prev,
      isSuperSubscriber: !prev.isSuperSubscriber,
      hearts: 5
    }));
  };

  const equipOutfit = (outfitId: string) => {
    sound.playClick();
    setUserStats((prev) => ({ ...prev, activeOutfit: outfitId }));
  };

  // FSRS 4.5 Algorithm Implementation
  const reviewFsrsCard = (cardId: string, rating: 1 | 2 | 3 | 4) => {
    sound.playClick();
    setFsrsCards((prevCards) =>
      prevCards.map((card) => {
        if (card.id !== cardId) return card;

        let newStability = card.stability;
        let newDifficulty = card.difficulty;
        let newLapses = card.lapses;
        const newReps = card.reps + 1;

        if (rating === 1) {
          // Again
          newStability = Math.max(0.4, card.stability * 0.35);
          newDifficulty = Math.min(10.0, card.difficulty + 0.8);
          newLapses += 1;
        } else if (rating === 2) {
          // Hard
          newStability = card.stability * 1.2;
          newDifficulty = Math.min(10.0, card.difficulty + 0.3);
        } else if (rating === 3) {
          // Good
          newStability = card.stability * 2.1;
          newDifficulty = Math.max(1.0, card.difficulty - 0.1);
        } else if (rating === 4) {
          // Easy
          newStability = card.stability * 3.4;
          newDifficulty = Math.max(1.0, card.difficulty - 0.4);
        }

        // Retrievability based on FSRS formula: R(t) = (1 + F * (t/S))^-1
        const retrievability = rating === 1 ? 0.35 : Math.min(0.99, 0.7 + (rating * 0.08));

        let masteryLevel: 'Baru' | 'Belajar' | 'Kuat' | 'Dikuasai' = 'Belajar';
        if (newStability >= 10 && newReps >= 5) masteryLevel = 'Dikuasai';
        else if (newStability >= 4) masteryLevel = 'Kuat';
        else if (newReps <= 1) masteryLevel = 'Baru';

        return {
          ...card,
          stability: Number(newStability.toFixed(1)),
          difficulty: Number(newDifficulty.toFixed(1)),
          reps: newReps,
          lapses: newLapses,
          retrievability: Number(retrievability.toFixed(2)),
          masteryLevel,
          lastReview: new Date().toISOString()
        };
      })
    );

    // Give a small XP bonus for practicing SRS
    setUserStats((prev) => ({
      ...prev,
      totalXp: prev.totalXp + 5,
      weeklyXp: prev.weeklyXp + 5,
      todayXp: prev.todayXp + 5
    }));
  };

  const addMistakeToQueue = (exercise: Exercise) => {
    setMistakesQueue((prev) => {
      if (prev.some((e) => e.id === exercise.id)) return prev;
      return [...prev, exercise];
    });
  };

  const clearMistakeFromQueue = (exerciseId: string) => {
    setMistakesQueue((prev) => prev.filter((e) => e.id !== exerciseId));
  };

  const sendKudos = (feedId: string) => {
    sound.playClick();
    setActivityFeed((prev) =>
      prev.map((item) => {
        if (item.id === feedId && !item.hasKudosGiven) {
          return {
            ...item,
            kudosCount: item.kudosCount + 1,
            hasKudosGiven: true
          };
        }
        return item;
      })
    );
  };

  return (
    <AppContext.Provider
      value={{
        activeTab,
        setActiveTab,
        userStats,
        courses,
        currentCourseId,
        currentCourse,
        switchCourse,
        activeLesson,
        startLesson,
        closeLesson,
        finishLesson,
        activeGuidebookUnit,
        openGuidebook,
        closeGuidebook,
        isCourseSelectOpen,
        setIsCourseSelectOpen,
        isHeartDepletedModalOpen,
        setIsHeartDepletedModalOpen,
        isAdminModalOpen,
        setIsAdminModalOpen,
        claimChest,
        dailyQuests,
        claimQuest,
        monthlyQuest,
        leagueMembers,
        fsrsCards,
        reviewFsrsCard,
        mistakesQueue,
        addMistakeToQueue,
        clearMistakeFromQueue,
        shopItems,
        buyShopItem,
        refillHearts,
        toggleSuperSubscription,
        equipOutfit,
        badges,
        activityFeed,
        sendKudos,
        deductHeart
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
