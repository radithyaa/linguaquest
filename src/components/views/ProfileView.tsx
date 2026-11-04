import React from 'react';
import {
  User,
  Flame,
  Zap,
  Trophy,
  BookOpen,
  Heart,
  Snowflake,
  ShieldCheck,
  Share2,
  Users,
  Settings,
  Sparkles,
  ThumbsUp
} from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { TactileButton } from '../ui/TactileButton';
import { Mascot } from '../ui/Mascot';

export const ProfileView: React.FC = () => {
  const { userStats, activityFeed, sendKudos, badges } = useApp();

  return (
    <div className="w-full max-w-2xl mx-auto pb-24 pt-2 space-y-8">
      {/* Profile Header Card */}
      <div className="p-6 sm:p-8 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_4px_0_0_#E5E5E5]">
        <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6 text-center sm:text-left">
          <div className="relative">
            <img
              src={userStats.avatarUrl}
              alt={userStats.displayName}
              className="w-24 h-24 sm:w-28 sm:h-28 rounded-full object-cover border-4 border-[#58CC02] shadow-md"
            />
            {userStats.isSuperSubscriber && (
              <span className="absolute bottom-0 right-0 w-8 h-8 rounded-full bg-[#FFC800] text-[#683A00] flex items-center justify-center shadow-md text-sm font-black border-2 border-white">
                ★
              </span>
            )}
          </div>

          <div className="flex-1">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
              <div>
                <h1 className="text-2xl sm:text-3xl font-black text-[#1B1C1C]">
                  {userStats.displayName}
                </h1>
                <p className="text-sm text-[#777777] font-semibold">@{userStats.username}</p>
              </div>

              <div className="flex items-center gap-2 justify-center sm:justify-start">
                <span className="text-xs font-black px-3 py-1 rounded-full bg-[#F4FBEA] text-[#58CC02] border border-[#D7FFB8]">
                  Level {userStats.level}
                </span>
                {userStats.isSuperSubscriber && (
                  <span className="text-xs font-black px-3 py-1 rounded-full bg-[#FFF9E6] text-[#8C5000] border border-[#FFE8A3]">
                    Super Member
                  </span>
                )}
              </div>
            </div>

            <p className="text-xs text-[#777777] mt-3">
              Bergabung sejak November 2026 • Zona Waktu: Asia/Jakarta (WIB)
            </p>
          </div>
        </div>

        {/* Mascot companion preview */}
        <div className="mt-6 p-4 rounded-2xl bg-[#F7F9FA] border border-[#E5E5E5] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Mascot mood="happy" size="md" outfit={userStats.activeOutfit} />
            <div>
              <p className="text-xs font-extrabold uppercase text-[#777777]">Maskot Pendamping</p>
              <h3 className="font-black text-sm text-[#1B1C1C]">Kiki Sang Burung Hantu Penjelajah</h3>
            </div>
          </div>
          <span className="text-xs font-bold text-[#1CB0F6]">
            {userStats.activeOutfit === 'default' ? 'Kostum Standar' : 'Kostum Khusus Terpasang'}
          </span>
        </div>
      </div>

      {/* STATS OVERVIEW GRID */}
      <div>
        <h2 className="text-lg font-black text-[#1B1C1C] mb-3">Statistik Belajar Personal</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {/* Streak */}
          <div className="p-4 rounded-2xl bg-white border-2 border-[#E5E5E5] shadow-xs flex flex-col">
            <div className="flex items-center gap-1.5 text-[#FF9600] mb-1">
              <Flame className="w-5 h-5 fill-current" />
              <span className="text-xs font-extrabold uppercase">Streak</span>
            </div>
            <span className="text-2xl font-black text-[#1B1C1C]">{userStats.streak} Hari</span>
            <span className="text-[10px] text-[#777777] mt-0.5">Rekor: {userStats.longestStreak} hari</span>
          </div>

          {/* Total XP */}
          <div className="p-4 rounded-2xl bg-white border-2 border-[#E5E5E5] shadow-xs flex flex-col">
            <div className="flex items-center gap-1.5 text-[#FF9600] mb-1">
              <Zap className="w-5 h-5 fill-current" />
              <span className="text-xs font-extrabold uppercase">Total XP</span>
            </div>
            <span className="text-2xl font-black text-[#1B1C1C]">{userStats.totalXp.toLocaleString()}</span>
            <span className="text-[10px] text-[#777777] mt-0.5">Minggu ini: {userStats.weeklyXp} XP</span>
          </div>

          {/* Current League */}
          <div className="p-4 rounded-2xl bg-white border-2 border-[#E5E5E5] shadow-xs flex flex-col">
            <div className="flex items-center gap-1.5 text-[#9C27B0] mb-1">
              <Trophy className="w-5 h-5" />
              <span className="text-xs font-extrabold uppercase">Liga</span>
            </div>
            <span className="text-2xl font-black text-[#1B1C1C]">{userStats.leagueTier}</span>
            <span className="text-[10px] text-[#58CC02] font-bold mt-0.5">Peringkat #{userStats.leagueRank}</span>
          </div>

          {/* Words Learned */}
          <div className="p-4 rounded-2xl bg-white border-2 border-[#E5E5E5] shadow-xs flex flex-col">
            <div className="flex items-center gap-1.5 text-[#1CB0F6] mb-1">
              <BookOpen className="w-5 h-5" />
              <span className="text-xs font-extrabold uppercase">Kosakata</span>
            </div>
            <span className="text-2xl font-black text-[#1B1C1C]">{userStats.wordsLearnedCount} Kata</span>
            <span className="text-[10px] text-[#777777] mt-0.5">Retrievability tinggi</span>
          </div>
        </div>
      </div>

      {/* SOCIAL FEED & KUDOS */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-black text-[#1B1C1C] flex items-center gap-2">
            <Users className="w-5 h-5 text-[#1CB0F6]" />
            <span>Kabar Sahabat Belajar</span>
          </h2>
          <span className="text-xs font-bold text-[#777777]">Saling dukung dengan Kudos</span>
        </div>

        <div className="space-y-3">
          {activityFeed.map((item) => (
            <div
              key={item.id}
              className="p-4 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-xs flex items-center justify-between gap-4"
            >
              <div className="flex items-center gap-3">
                <img
                  src={item.userAvatar}
                  alt={item.userDisplayName}
                  className="w-11 h-11 rounded-full object-cover border-2 border-[#E5E5E5]"
                />
                <div>
                  <p className="text-sm font-bold text-[#1B1C1C]">
                    <span className="font-black">{item.userDisplayName}</span> {item.action}{' '}
                    <span className="text-[#FF9600] font-black">{item.target}</span>
                  </p>
                  <p className="text-xs text-[#777777] mt-0.5">{item.timeAgo}</p>
                </div>
              </div>

              <button
                onClick={() => sendKudos(item.id)}
                disabled={item.hasKudosGiven}
                className={`px-3 py-2 rounded-xl text-xs font-black flex items-center gap-1.5 transition-all cursor-pointer ${
                  item.hasKudosGiven
                    ? 'bg-[#FFEBEE] text-[#FF4B4B] border border-[#FFCDD2]'
                    : 'bg-[#F7F9FA] border-2 border-[#E5E5E5] text-[#4B4B4B] hover:border-[#FF4B4B] hover:text-[#FF4B4B] active:scale-95'
                }`}
              >
                <ThumbsUp className={`w-3.5 h-3.5 ${item.hasKudosGiven ? 'fill-current' : ''}`} />
                <span>{item.hasKudosGiven ? 'Kudos Terkirim!' : 'Kirim Kudos'}</span>
                <span className="ml-1 text-[10px] opacity-80">({item.kudosCount})</span>
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
