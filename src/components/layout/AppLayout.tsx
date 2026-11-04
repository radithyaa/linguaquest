import React, { useState } from 'react';
import {
  Compass,
  Dumbbell,
  Target,
  Trophy,
  ShoppingBag,
  User,
  Volume2,
  VolumeX,
  Sparkles,
  ChevronRight,
  ShieldCheck,
  Flame,
  Gem,
  Heart,
  Infinity,
  Settings,
  Database
} from 'lucide-react';
import { TabType } from '../../types';
import { useApp } from '../../context/AppContext';
import { sound } from '../../services/soundEffects';
import { StatBadge } from '../ui/StatBadge';
import { Mascot } from '../ui/Mascot';

interface AppLayoutProps {
  children: React.ReactNode;
}

export const AppLayout: React.FC<AppLayoutProps> = ({ children }) => {
  const {
    activeTab,
    setActiveTab,
    userStats,
    currentCourse,
    setIsCourseSelectOpen,
    setIsAdminModalOpen,
    dailyQuests
  } = useApp();

  const [soundEnabled, setSoundEnabled] = useState(sound.isSoundEnabled());

  const toggleSound = () => {
    const next = !soundEnabled;
    sound.setSoundEnabled(next);
    setSoundEnabled(next);
    if (next) sound.playClick();
  };

  const navItems: { id: TabType; label: string; icon: React.ReactNode }[] = [
    { id: 'learn', label: 'Belajar', icon: <Compass className="w-6 h-6 stroke-[2.5]" /> },
    { id: 'practice', label: 'Latihan', icon: <Dumbbell className="w-6 h-6 stroke-[2.5]" /> },
    { id: 'quests', label: 'Tantangan', icon: <Target className="w-6 h-6 stroke-[2.5]" /> },
    { id: 'league', label: 'Liga', icon: <Trophy className="w-6 h-6 stroke-[2.5]" /> },
    { id: 'shop', label: 'Toko', icon: <ShoppingBag className="w-6 h-6 stroke-[2.5]" /> },
    { id: 'profile', label: 'Profil', icon: <User className="w-6 h-6 stroke-[2.5]" /> }
  ];

  return (
    <div className="min-h-screen bg-[#F7F9FA] text-[#4B4B4B] flex justify-center">
      {/* =========================================================================
          DESKTOP & TABLET LEFT SIDEBAR / NAVIGATION RAIL
      ========================================================================= */}
      <aside className="hidden md:flex flex-col justify-between fixed left-0 top-0 bottom-0 z-40 bg-white border-r-2 border-[#E5E5E5] w-[88px] lg:w-[256px] px-3 py-6 select-none">
        <div className="space-y-6">
          {/* Logo & Brand Mascot */}
          <div className="flex items-center gap-3 px-2 lg:px-4 cursor-pointer" onClick={() => setActiveTab('learn')}>
            <Mascot mood="happy" size="md" outfit={userStats.activeOutfit} className="flex-shrink-0" />
            <div className="hidden lg:block">
              <span className="text-2xl font-black text-[#58CC02] tracking-tight">LinguaQuest</span>
              <p className="text-[10px] font-extrabold uppercase tracking-widest text-[#777777]">
                Belajar Bergamifikasi
              </p>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="space-y-1.5">
            {navItems.map((item) => {
              const isActive = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => setActiveTab(item.id)}
                  className={`w-full flex items-center gap-4 px-3.5 py-3 rounded-2xl font-extrabold text-sm uppercase tracking-wider transition-all duration-75 cursor-pointer ${
                    isActive
                      ? 'bg-[#E1F5FE] text-[#1CB0F6] border-2 border-[#B3E5FC] shadow-[0_2px_0_0_#1CB0F6]'
                      : 'text-[#777777] hover:bg-[#F7F9FA] hover:text-[#1B1C1C] border-2 border-transparent'
                  }`}
                >
                  <span className="flex-shrink-0">{item.icon}</span>
                  <span className="hidden lg:inline">{item.label}</span>
                </button>
              );
            })}
          </nav>
        </div>

        {/* Sidebar Bottom Utilities */}
        <div className="space-y-2 pt-4 border-t border-[#E5E5E5]">
          {/* Current Course Selector Button */}
          <button
            onClick={() => setIsCourseSelectOpen(true)}
            className="w-full flex items-center justify-between p-2.5 rounded-2xl border-2 border-[#E5E5E5] bg-[#F7F9FA] hover:border-[#1CB0F6] transition-all cursor-pointer"
          >
            <div className="flex items-center gap-2.5">
              <span className="text-xl">{currentCourse.flag}</span>
              <span className="hidden lg:inline font-bold text-xs text-[#1B1C1C] truncate max-w-[120px]">
                {currentCourse.title}
              </span>
            </div>
            <span className="hidden lg:inline text-[10px] font-extrabold text-[#1CB0F6] uppercase">
              Ubah
            </span>
          </button>

          {/* Sound Toggle & Admin CMS */}
          <div className="flex items-center justify-around lg:justify-between px-2">
            <button
              onClick={toggleSound}
              title={soundEnabled ? 'Matikan Suara Audio' : 'Aktifkan Suara Audio'}
              className="p-2 rounded-xl text-[#777777] hover:text-[#1B1C1C] hover:bg-[#F7F9FA] transition-colors cursor-pointer"
            >
              {soundEnabled ? (
                <Volume2 className="w-5 h-5 text-[#58CC02]" />
              ) : (
                <VolumeX className="w-5 h-5 text-[#AFAFAF]" />
              )}
            </button>

            <button
              onClick={() => setIsAdminModalOpen(true)}
              title="Panel CMS Kurikulum (SRS 5.12)"
              className="p-2 rounded-xl text-[#777777] hover:text-[#1B1C1C] hover:bg-[#F7F9FA] transition-colors cursor-pointer flex items-center gap-1"
            >
              <Database className="w-5 h-5 text-[#1CB0F6]" />
              <span className="hidden lg:inline text-[10px] font-extrabold uppercase">CMS</span>
            </button>
          </div>
        </div>
      </aside>

      {/* =========================================================================
          MAIN CENTER WORKSPACE CONTAINER
      ========================================================================= */}
      <main className="w-full md:pl-[88px] lg:pl-[256px] xl:pr-[380px] min-h-screen px-4 pt-16 md:pt-6">
        {/* Sticky Mobile/Tablet Top Chrome Header */}
        <header className="fixed top-0 left-0 right-0 md:left-[88px] lg:left-[256px] xl:hidden z-30 bg-white/95 backdrop-blur-md border-b-2 border-[#E5E5E5] px-4 py-2.5 flex items-center justify-between">
          {/* Flag / Course switcher */}
          <button
            onClick={() => setIsCourseSelectOpen(true)}
            className="flex items-center gap-1.5 px-2.5 py-1 rounded-xl bg-[#F7F9FA] border border-[#E5E5E5] cursor-pointer hover:border-[#1CB0F6]"
          >
            <span className="text-xl leading-none">{currentCourse.flag}</span>
            <span className="text-xs font-black hidden sm:inline">{currentCourse.title}</span>
          </button>

          {/* Stats Badges */}
          <div className="flex items-center gap-2">
            <StatBadge type="streak" value={userStats.streak} onClick={() => setActiveTab('profile')} />
            <StatBadge type="gems" value={userStats.gems} onClick={() => setActiveTab('shop')} />
            <StatBadge
              type="hearts"
              value={userStats.hearts}
              isSuper={userStats.isSuperSubscriber}
              onClick={() => setActiveTab('shop')}
            />
          </div>
        </header>

        {/* Primary Page Content */}
        <div className="pt-2">{children}</div>
      </main>

      {/* =========================================================================
          DESKTOP RIGHT TELEMETRY SIDEBAR (Width 360px)
      ========================================================================= */}
      <aside className="hidden xl:block fixed right-0 top-0 bottom-0 w-[360px] p-6 bg-[#F7F9FA] border-l-2 border-[#E5E5E5] overflow-y-auto space-y-6 z-30 select-none">
        {/* Top Chrome Stats Bar */}
        <div className="flex items-center justify-between gap-2 p-3 bg-white rounded-3xl border-2 border-[#E5E5E5] shadow-xs">
          <StatBadge type="streak" value={userStats.streak} onClick={() => setActiveTab('profile')} />
          <StatBadge type="gems" value={userStats.gems} onClick={() => setActiveTab('shop')} />
          <StatBadge
            type="hearts"
            value={userStats.hearts}
            isSuper={userStats.isSuperSubscriber}
            onClick={() => setActiveTab('shop')}
          />
        </div>

        {/* Daily Goal Telemetry Card */}
        <div className="p-5 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_3px_0_0_#E5E5E5] space-y-2.5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-black uppercase text-[#FF9600] flex items-center gap-1.5">
              <Flame className="w-4 h-4 fill-current" /> Target XP Harian
            </span>
            <span className="text-xs font-bold text-[#777777]">
              {userStats.todayXp} / {userStats.targetDailyXp} XP
            </span>
          </div>
          <div className="h-3 bg-[#E5E5E5] rounded-full overflow-hidden">
            <div
              className="h-full bg-[#FF9600] rounded-full transition-all duration-300"
              style={{
                width: `${Math.min(100, Math.round((userStats.todayXp / userStats.targetDailyXp) * 100))}%`
              }}
            />
          </div>
          <p className="text-[11px] text-[#777777] font-medium leading-snug">
            {userStats.todayXp >= userStats.targetDailyXp
              ? '🎉 Target tercapai! Streak apimu aman hari ini.'
              : `Raih ${userStats.targetDailyXp - userStats.todayXp} XP lagi untuk menjaga streak hari ini!`}
          </p>
        </div>

        {/* Weekly League Status Card */}
        <div
          onClick={() => setActiveTab('league')}
          className="p-5 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_3px_0_0_#E5E5E5] hover:border-[#1CB0F6] transition-all cursor-pointer space-y-2"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-black uppercase text-[#9C27B0] flex items-center gap-1.5">
              <Trophy className="w-4 h-4" /> Liga {userStats.leagueTier}
            </span>
            <span className="text-xs font-black px-2 py-0.5 rounded-full bg-[#D7FFB8] text-[#2B6C00]">
              Peringkat #{userStats.leagueRank}
            </span>
          </div>
          <p className="text-xs text-[#777777] font-medium">
            Kamu berada di Zona Promosi! Pertahankan posisi Top 5 hingga akhir pekan.
          </p>
        </div>

        {/* Super Subscription Banner Promo */}
        {!userStats.isSuperSubscriber && (
          <div
            onClick={() => setActiveTab('shop')}
            className="p-5 rounded-3xl bg-gradient-to-br from-[#1B1C1C] to-[#2D3748] text-white shadow-md hover:scale-[1.01] transition-all cursor-pointer relative overflow-hidden"
          >
            <div className="flex items-center gap-1.5 text-xs font-black text-[#FFC800] uppercase tracking-wider mb-1">
              <Sparkles className="w-4 h-4" />
              <span>LinguaQuest Super</span>
            </div>
            <h3 className="text-lg font-black leading-tight">Hearts Tak Terbatas</h3>
            <p className="text-xs text-gray-300 mt-1">
              Belajar tanpa takut kehabisan nyawa dengan LinguaQuest Super!
            </p>
          </div>
        )}

        {/* Mini Daily Quests Widget */}
        <div className="p-5 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_3px_0_0_#E5E5E5] space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="font-black text-sm text-[#1B1C1C] flex items-center gap-1.5">
              <Target className="w-4 h-4 text-[#1CB0F6]" />
              <span>Misi Hari Ini</span>
            </h3>
            <button
              onClick={() => setActiveTab('quests')}
              className="text-xs font-extrabold text-[#1CB0F6] hover:underline cursor-pointer"
            >
              Lihat Semua
            </button>
          </div>

          <div className="space-y-2.5">
            {dailyQuests.slice(0, 2).map((q) => (
              <div key={q.id} className="text-xs">
                <div className="flex justify-between font-bold mb-1">
                  <span className="text-[#1B1C1C] truncate max-w-[190px]">{q.title}</span>
                  <span className="text-[#777777]">{q.current}/{q.target}</span>
                </div>
                <div className="h-2 bg-[#E5E5E5] rounded-full overflow-hidden">
                  <div
                    className="h-full bg-[#1CB0F6] rounded-full"
                    style={{ width: `${Math.min(100, Math.round((q.current / q.target) * 100))}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      </aside>

      {/* =========================================================================
          MOBILE PERSISTENT BOTTOM NAVIGATION BAR (Height 64px)
      ========================================================================= */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 h-16 bg-white border-t-2 border-[#E5E5E5] z-40 flex items-center justify-around px-2 select-none shadow-lg">
        {navItems.map((item) => {
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`flex flex-col items-center justify-center w-12 h-12 rounded-2xl transition-all cursor-pointer ${
                isActive
                  ? 'bg-[#E1F5FE] text-[#1CB0F6] shadow-xs'
                  : 'text-[#777777] hover:text-[#1B1C1C]'
              }`}
            >
              {item.icon}
            </button>
          );
        })}
      </nav>
    </div>
  );
};
