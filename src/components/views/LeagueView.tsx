import React from 'react';
import { Trophy, Shield, ArrowUp, ArrowDown, Clock, Sparkles, UserCheck } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { LeagueTier } from '../../types';

export const LeagueView: React.FC = () => {
  const { leagueMembers, userStats } = useApp();

  const tierColors: Record<LeagueTier, { bg: string; text: string; border: string }> = {
    Bronze: { bg: 'bg-[#CD7F32]/10', text: 'text-[#CD7F32]', border: 'border-[#CD7F32]' },
    Silver: { bg: 'bg-[#A0B2C6]/15', text: 'text-[#5C6E82]', border: 'border-[#A0B2C6]' },
    Gold: { bg: 'bg-[#FFC800]/15', text: 'text-[#996500]', border: 'border-[#FFC800]' },
    Sapphire: { bg: 'bg-[#2B70C9]/15', text: 'text-[#2B70C9]', border: 'border-[#2B70C9]' },
    Ruby: { bg: 'bg-[#E53935]/15', text: 'text-[#E53935]', border: 'border-[#E53935]' },
    Emerald: { bg: 'bg-[#00A86B]/15', text: 'text-[#00A86B]', border: 'border-[#00A86B]' },
    Amethyst: { bg: 'bg-[#9C27B0]/15', text: 'text-[#9C27B0]', border: 'border-[#9C27B0]' },
    Pearl: { bg: 'bg-[#E0E5EC]/30', text: 'text-[#455A64]', border: 'border-[#B0BEC5]' },
    Obsidian: { bg: 'bg-[#263238]/10', text: 'text-[#263238]', border: 'border-[#263238]' },
    Diamond: { bg: 'bg-[#4DD0E1]/20', text: 'text-[#00838F]', border: 'border-[#4DD0E1]' }
  };

  const currentTierTheme = tierColors[userStats.leagueTier] || tierColors.Amethyst;

  return (
    <div className="w-full max-w-2xl mx-auto pb-24 pt-2 space-y-6">
      {/* Tier Header Banner */}
      <div
        className={`p-6 rounded-3xl border-2 shadow-[0_5px_0_0_#E5E5E5] flex items-center justify-between gap-4 ${currentTierTheme.bg} ${currentTierTheme.border}`}
      >
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-3xl bg-white shadow-md flex items-center justify-center border-2 border-current">
            <Trophy className={`w-8 h-8 ${currentTierTheme.text}`} />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-black uppercase tracking-wider text-[#777777]">
                Musim Mingguan
              </span>
              <span className={`text-xs font-black px-2 py-0.5 rounded-full bg-white shadow-xs ${currentTierTheme.text}`}>
                Tier {userStats.leagueTier}
              </span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-black text-[#1B1C1C] mt-0.5">
              Liga {userStats.leagueTier}
            </h1>
            <p className="text-xs sm:text-sm font-semibold text-[#777777] mt-0.5">
              30 Pembelajar saling bersaing meraih XP tertinggi!
            </p>
          </div>
        </div>

        <div className="hidden sm:flex flex-col items-end text-xs font-black text-[#777777]">
          <span className="flex items-center gap-1">
            <Clock className="w-4 h-4 text-[#FF9600]" />
            Sisa Waktu
          </span>
          <span className="text-sm font-black text-[#1B1C1C] mt-0.5">2 Hari 14 Jam</span>
        </div>
      </div>

      {/* Rules Notice */}
      <div className="flex items-center justify-between text-xs font-bold text-[#777777] px-2">
        <span className="flex items-center gap-1.5 text-[#58CC02]">
          <ArrowUp className="w-4 h-4 stroke-[3]" /> Top 5 Promosi ke Tier Berikutnya
        </span>
        <span className="flex items-center gap-1.5 text-[#FF4B4B]">
          <ArrowDown className="w-4 h-4 stroke-[3]" /> Bottom 5 Zona Degradasi
        </span>
      </div>

      {/* 30-Player Leaderboard Table */}
      <div className="rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-xs overflow-hidden">
        {leagueMembers.map((member, idx) => {
          const rank = idx + 1;
          const isPromotionZone = rank <= 5;
          const isRelegationZone = rank > 25;
          const isCurrentUser = member.isCurrentUser;

          return (
            <React.Fragment key={member.id}>
              {/* Promotion Zone Divider after rank 5 */}
              {rank === 6 && (
                <div className="bg-[#D7FFB8] px-4 py-1.5 text-[11px] font-black uppercase tracking-wider text-[#2B6C00] flex items-center justify-between border-y border-[#58CC02]/30">
                  <span className="flex items-center gap-1">
                    <ArrowUp className="w-3.5 h-3.5 stroke-[3]" /> Batas Promosi (Top 5)
                  </span>
                  <span>Hadiah +50 Gems</span>
                </div>
              )}

              {/* Relegation Zone Divider before rank 26 */}
              {rank === 26 && (
                <div className="bg-[#FFDFE0] px-4 py-1.5 text-[11px] font-black uppercase tracking-wider text-[#BA1A1A] flex items-center justify-between border-y border-[#FF4B4B]/30">
                  <span className="flex items-center gap-1">
                    <ArrowDown className="w-3.5 h-3.5 stroke-[3]" /> Zona Degradasi (Bottom 5)
                  </span>
                  <span>Turun Tier</span>
                </div>
              )}

              <div
                className={`px-4 sm:px-6 py-3.5 flex items-center justify-between border-b border-[#E5E5E5] last:border-b-0 transition-colors ${
                  isCurrentUser
                    ? 'bg-[#DDF4FF] font-black text-[#006590]'
                    : isPromotionZone
                    ? 'hover:bg-[#F9FFF5]'
                    : isRelegationZone
                    ? 'hover:bg-[#FFF9F9]'
                    : 'hover:bg-[#F7F9FA]'
                }`}
              >
                <div className="flex items-center gap-3.5">
                  {/* Rank Number */}
                  <span
                    className={`w-7 text-center font-black text-sm ${
                      rank === 1
                        ? 'text-[#FFC800] text-base'
                        : rank === 2
                        ? 'text-[#A0B2C6] text-base'
                        : rank === 3
                        ? 'text-[#CD7F32] text-base'
                        : isPromotionZone
                        ? 'text-[#58CC02]'
                        : isRelegationZone
                        ? 'text-[#FF4B4B]'
                        : 'text-[#777777]'
                    }`}
                  >
                    {rank}
                  </span>

                  {/* Avatar */}
                  <div className="relative">
                    <img
                      src={member.avatarUrl}
                      alt={member.displayName}
                      className="w-10 h-10 rounded-full object-cover border-2 border-white shadow-xs"
                    />
                    {member.isPro && (
                      <span className="absolute -bottom-1 -right-1 w-4 h-4 bg-[#FFC800] text-[#683A00] rounded-full text-[8px] font-black flex items-center justify-center shadow-xs">
                        ★
                      </span>
                    )}
                  </div>

                  {/* Name and streak */}
                  <div>
                    <div className="flex items-center gap-1.5">
                      <span
                        className={`text-sm ${
                          isCurrentUser ? 'font-black text-[#006590]' : 'font-bold text-[#1B1C1C]'
                        }`}
                      >
                        {member.displayName}
                      </span>
                      {isCurrentUser && (
                        <span className="text-[10px] uppercase font-black px-1.5 py-0.5 rounded-md bg-[#1CB0F6] text-white">
                          Kamu
                        </span>
                      )}
                    </div>
                    <span className="text-xs text-[#777777] font-medium">
                      🔥 {member.streak} hari streak
                    </span>
                  </div>
                </div>

                {/* Score XP */}
                <div className="text-right">
                  <span className="font-black text-sm sm:text-base text-[#1B1C1C]">
                    {member.xp} XP
                  </span>
                </div>
              </div>
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
};
