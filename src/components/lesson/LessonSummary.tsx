import React, { useEffect } from 'react';
import confetti from 'canvas-confetti';
import { Zap, Target, Flame, Gem, ArrowRight, Award } from 'lucide-react';
import { sound } from '../../services/soundEffects';
import { TactileButton } from '../ui/TactileButton';
import { Mascot } from '../ui/Mascot';

interface LessonSummaryProps {
  xpBase: number;
  accuracyBonus: number;
  comboBonus: number;
  totalXp: number;
  accuracy: number;
  maxCombo: number;
  gemsEarned: number;
  streakCount: number;
  outfit?: string;
  onContinue: () => void;
}

export const LessonSummary: React.FC<LessonSummaryProps> = ({
  xpBase,
  accuracyBonus,
  comboBonus,
  totalXp,
  accuracy,
  maxCombo,
  gemsEarned,
  streakCount,
  outfit = 'default',
  onContinue
}) => {
  useEffect(() => {
    sound.playLessonComplete();

    // Trigger joyful celebration confetti
    try {
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 },
        colors: ['#58CC02', '#1CB0F6', '#FF9600', '#FFC800']
      });

      const timer = setTimeout(() => {
        confetti({
          particleCount: 50,
          angle: 60,
          spread: 55,
          origin: { x: 0 },
          colors: ['#58CC02', '#FFC800']
        });
        confetti({
          particleCount: 50,
          angle: 120,
          spread: 55,
          origin: { x: 1 },
          colors: ['#1CB0F6', '#FF9600']
        });
      }, 400);

      return () => clearTimeout(timer);
    } catch {
      // Ignore confetti issues if canvas is unavailable
    }
  }, []);

  return (
    <div className="min-h-screen bg-[#F7F9FA] flex flex-col justify-between p-4 sm:p-8 max-w-xl mx-auto animate-in fade-in duration-200">
      {/* Top Victory Section */}
      <div className="text-center pt-4 sm:pt-8">
        <div className="flex justify-center mb-3">
          <Mascot mood="victory" size="xl" outfit={outfit} />
        </div>
        <h1 className="text-3xl sm:text-4xl font-black text-[#58CC02] tracking-tight">
          Pelajaran Selesai!
        </h1>
        <p className="text-sm sm:text-base text-[#777777] font-semibold mt-1">
          Luar biasa! Kamu semakin dekat dengan kemahiran berbahasa.
        </p>
      </div>

      {/* Stats Cards Grid */}
      <div className="grid grid-cols-2 gap-3.5 my-6">
        {/* Total XP Card */}
        <div className="p-4 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_4px_0_0_#E5E5E5] flex flex-col items-center text-center">
          <div className="w-10 h-10 rounded-2xl bg-[#FFF3E0] text-[#FF9600] flex items-center justify-center mb-2">
            <Zap className="w-6 h-6 fill-[#FF9600]" />
          </div>
          <span className="text-xs font-extrabold uppercase tracking-wider text-[#777777]">Total XP</span>
          <span className="text-2xl sm:text-3xl font-black text-[#FF9600]">+{totalXp}</span>
        </div>

        {/* Accuracy Card */}
        <div className="p-4 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_4px_0_0_#E5E5E5] flex flex-col items-center text-center">
          <div className="w-10 h-10 rounded-2xl bg-[#E1F5FE] text-[#1CB0F6] flex items-center justify-center mb-2">
            <Target className="w-6 h-6 text-[#1CB0F6]" />
          </div>
          <span className="text-xs font-extrabold uppercase tracking-wider text-[#777777]">Akurasi</span>
          <span className="text-2xl sm:text-3xl font-black text-[#1CB0F6]">{accuracy}%</span>
        </div>

        {/* Streak Card */}
        <div className="p-4 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_4px_0_0_#E5E5E5] flex flex-col items-center text-center">
          <div className="w-10 h-10 rounded-2xl bg-[#FFF3E0] text-[#FF9600] flex items-center justify-center mb-2">
            <Flame className="w-6 h-6 fill-[#FF9600]" />
          </div>
          <span className="text-xs font-extrabold uppercase tracking-wider text-[#777777]">Streak Hari</span>
          <span className="text-2xl sm:text-3xl font-black text-[#FF9600]">{streakCount} Hari</span>
        </div>

        {/* Gems Card */}
        <div className="p-4 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_4px_0_0_#E5E5E5] flex flex-col items-center text-center">
          <div className="w-10 h-10 rounded-2xl bg-[#E1F5FE] text-[#1CB0F6] flex items-center justify-center mb-2">
            <Gem className="w-6 h-6 fill-[#1CB0F6]" />
          </div>
          <span className="text-xs font-extrabold uppercase tracking-wider text-[#777777]">Gems Diperoleh</span>
          <span className="text-2xl sm:text-3xl font-black text-[#1CB0F6]">+{gemsEarned}</span>
        </div>
      </div>

      {/* XP Breakdown Box (SRS Section 9.1 Formula) */}
      <div className="p-5 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-xs space-y-2 mb-6">
        <div className="flex items-center gap-2 pb-2 border-b border-[#E5E5E5]">
          <Award className="w-5 h-5 text-[#58CC02]" />
          <h3 className="font-extrabold text-sm text-[#1B1C1C]">Rincian Perolehan XP (SRS 9.1)</h3>
        </div>
        <div className="flex justify-between text-xs sm:text-sm text-[#4B4B4B] font-semibold pt-1">
          <span>XP Dasar Sesi</span>
          <span className="font-bold text-[#1B1C1C]">+{xpBase} XP</span>
        </div>
        <div className="flex justify-between text-xs sm:text-sm text-[#4B4B4B] font-semibold">
          <span>Bonus Akurasi ({accuracy}%)</span>
          <span className="font-bold text-[#58CC02]">+{accuracyBonus} XP</span>
        </div>
        <div className="flex justify-between text-xs sm:text-sm text-[#4B4B4B] font-semibold">
          <span>Bonus Max Combo ({maxCombo}x)</span>
          <span className="font-bold text-[#1CB0F6]">+{comboBonus} XP</span>
        </div>
        <div className="pt-2 border-t border-[#E5E5E5] flex justify-between text-sm sm:text-base font-black text-[#1B1C1C]">
          <span>Total Diberikan</span>
          <span className="text-[#58CC02]">+{totalXp} XP</span>
        </div>
      </div>

      {/* Bottom CTA */}
      <div className="pt-2">
        <TactileButton
          variant="primary"
          size="lg"
          fullWidth
          onClick={onContinue}
          icon={<ArrowRight className="w-5 h-5" />}
        >
          Lanjutkan Petualangan
        </TactileButton>
      </div>
    </div>
  );
};
