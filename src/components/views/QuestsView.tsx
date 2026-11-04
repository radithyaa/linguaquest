import React from 'react';
import { Target, Crown, Gem, Award, CheckCircle2, Zap, Flame, BookOpen, Clock } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { TactileButton } from '../ui/TactileButton';
import { sound } from '../../services/soundEffects';

export const QuestsView: React.FC = () => {
  const { dailyQuests, claimQuest, monthlyQuest, badges } = useApp();

  return (
    <div className="w-full max-w-2xl mx-auto pb-24 pt-2 space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl sm:text-3xl font-black text-[#1B1C1C]">Tantangan & Quests</h1>
        <p className="text-sm text-[#777777] font-medium mt-1">
          Selesaikan misi harian dan bulanan untuk mendapatkan hadiah Gems dan lencana kehormatan.
        </p>
      </div>

      {/* MONTHLY QUEST BANNER */}
      <div className="p-6 rounded-3xl bg-gradient-to-br from-[#FFF9E6] via-[#FFF3D6] to-[#FFE8A3] border-2 border-[#D9A700] shadow-[0_5px_0_0_#D9A700] text-[#683A00] relative overflow-hidden">
        <div className="flex items-start justify-between gap-4">
          <div className="flex-1">
            <div className="flex items-center gap-2 text-xs font-black uppercase tracking-wider text-[#8C5000]">
              <Crown className="w-4 h-4 fill-[#8C5000]" />
              <span>Tantangan Bulanan</span>
            </div>
            <h2 className="text-xl sm:text-2xl font-black text-[#1B1C1C] mt-1">
              {monthlyQuest.title}
            </h2>
            <p className="text-xs sm:text-sm font-semibold text-[#8C5000] mt-0.5">
              Raih {monthlyQuest.badgeName}
            </p>

            {/* Progress Bar */}
            <div className="mt-4">
              <div className="flex justify-between text-xs font-black mb-1.5">
                <span>{monthlyQuest.current} / {monthlyQuest.target} Misi Selesai</span>
                <span className="flex items-center gap-1 text-[#8C5000]">
                  <Clock className="w-3.5 h-3.5" />
                  {monthlyQuest.daysRemaining} hari tersisa
                </span>
              </div>
              <div className="h-4 bg-white/70 rounded-full overflow-hidden p-0.5 border border-[#D9A700]">
                <div
                  className="h-full bg-[#FFC800] rounded-full transition-all duration-300 shadow-inner"
                  style={{ width: `${Math.round((monthlyQuest.current / monthlyQuest.target) * 100)}%` }}
                />
              </div>
            </div>
          </div>

          <div className="w-20 h-20 sm:w-24 sm:h-24 rounded-3xl bg-white/80 border-2 border-[#D9A700] shadow-md flex items-center justify-center flex-shrink-0">
            <Crown className="w-10 h-10 text-[#FFC800] fill-[#FFC800]" />
          </div>
        </div>
      </div>

      {/* DAILY QUESTS LIST */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-black text-[#1B1C1C] flex items-center gap-2">
            <Target className="w-5 h-5 text-[#1CB0F6]" />
            <span>Misi Harian</span>
          </h2>
          <span className="text-xs font-bold text-[#777777]">Direset setiap tengah malam</span>
        </div>

        <div className="space-y-3">
          {dailyQuests.map((quest) => {
            const percent = Math.min(100, Math.round((quest.current / quest.target) * 100));
            return (
              <div
                key={quest.id}
                className="p-4 sm:p-5 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_3px_0_0_#E5E5E5] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4"
              >
                <div className="flex items-center gap-3.5 flex-1 w-full">
                  <div className="w-12 h-12 rounded-2xl bg-[#E1F5FE] text-[#1CB0F6] flex items-center justify-center flex-shrink-0">
                    {quest.icon === 'book' && <BookOpen className="w-6 h-6" />}
                    {quest.icon === 'zap' && <Zap className="w-6 h-6 fill-[#1CB0F6]" />}
                    {quest.icon === 'target' && <Target className="w-6 h-6" />}
                  </div>

                  <div className="flex-1">
                    <h3 className="font-extrabold text-sm sm:text-base text-[#1B1C1C]">
                      {quest.title}
                    </h3>
                    <p className="text-xs text-[#777777] font-medium">{quest.description}</p>

                    <div className="mt-2 flex items-center gap-2">
                      <div className="flex-1 h-2.5 bg-[#E5E5E5] rounded-full overflow-hidden">
                        <div
                          className="h-full bg-[#1CB0F6] rounded-full transition-all duration-300"
                          style={{ width: `${percent}%` }}
                        />
                      </div>
                      <span className="text-xs font-bold text-[#777777] min-w-[50px] text-right">
                        {quest.current}/{quest.target} {quest.unit}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="w-full sm:w-auto flex sm:flex-col items-center justify-between sm:justify-center gap-2 pt-2 sm:pt-0 border-t sm:border-t-0 border-[#E5E5E5]">
                  <div className="flex items-center gap-1 font-black text-[#1CB0F6] text-sm">
                    <Gem className="w-4 h-4 fill-[#1CB0F6]" />
                    <span>+{quest.rewardGems}</span>
                  </div>

                  {quest.claimed ? (
                    <span className="text-xs font-black text-[#58CC02] flex items-center gap-1">
                      <CheckCircle2 className="w-4 h-4" /> Diklaim
                    </span>
                  ) : quest.completed ? (
                    <TactileButton
                      variant="primary"
                      size="sm"
                      onClick={() => claimQuest(quest.id)}
                    >
                      Klaim
                    </TactileButton>
                  ) : (
                    <span className="text-xs font-bold text-[#AFAFAF]">Sedang Berjalan</span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* ACHIEVEMENTS / BADGES */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-black text-[#1B1C1C] flex items-center gap-2">
            <Award className="w-5 h-5 text-[#FF9600]" />
            <span>Lencana Prestasi</span>
          </h2>
          <span className="text-xs font-bold text-[#777777]">Koleksi Penghargaan</span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
          {badges.map((badge) => {
            const tierColors = {
              bronze: 'border-[#CD7F32] bg-[#FFFBF7]',
              silver: 'border-[#A0B2C6] bg-[#F7F9FC]',
              gold: 'border-[#FFC800] bg-[#FFFDF0]',
              diamond: 'border-[#4DD0E1] bg-[#F0FCFD]'
            };

            return (
              <div
                key={badge.id}
                className={`p-4 rounded-3xl border-2 shadow-xs flex items-center gap-3.5 ${
                  tierColors[badge.tier]
                }`}
              >
                <div
                  className={`w-12 h-12 rounded-2xl flex items-center justify-center flex-shrink-0 ${
                    badge.unlocked
                      ? 'bg-white shadow-xs text-[#FF9600]'
                      : 'bg-[#E5E5E5] text-[#AFAFAF]'
                  }`}
                >
                  {badge.icon === 'flame' && <Flame className="w-6 h-6 fill-current" />}
                  {badge.icon === 'zap' && <Zap className="w-6 h-6 fill-current" />}
                  {badge.icon === 'book-open' && <BookOpen className="w-6 h-6 fill-current" />}
                  {badge.icon === 'award' && <Award className="w-6 h-6 fill-current" />}
                </div>

                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <h3 className="font-black text-sm text-[#1B1C1C]">{badge.title}</h3>
                    <span className="text-[10px] font-extrabold uppercase tracking-wider text-[#777777]">
                      {badge.tier}
                    </span>
                  </div>
                  <p className="text-xs text-[#777777] font-medium mt-0.5 leading-snug">
                    {badge.description}
                  </p>
                  <div className="mt-1.5 flex items-center gap-2">
                    <div className="flex-1 h-2 bg-[#E5E5E5] rounded-full overflow-hidden">
                      <div
                        className="h-full bg-[#58CC02] rounded-full"
                        style={{
                          width: `${Math.min(100, Math.round((badge.progress / badge.target) * 100))}%`
                        }}
                      />
                    </div>
                    <span className="text-[10px] font-bold text-[#777777]">
                      {badge.progress}/{badge.target}
                    </span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
