import React from 'react';
import { X, Heart, Gem, ShieldCheck, Dumbbell } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { TactileButton } from './TactileButton';
import { Mascot } from './Mascot';

interface HeartDepletedModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const HeartDepletedModal: React.FC<HeartDepletedModalProps> = ({ isOpen, onClose }) => {
  const { userStats, refillHearts, toggleSuperSubscription, setActiveTab } = useApp();

  if (!isOpen) return null;

  const handleRefillWithGems = () => {
    if (userStats.gems >= 100) {
      refillHearts();
    } else {
      setActiveTab('shop');
      onClose();
    }
  };

  const handlePractice = () => {
    onClose();
    setActiveTab('practice');
  };

  const handleSuper = () => {
    toggleSuperSubscription();
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/55 backdrop-blur-xs">
      <div className="relative w-full max-w-md bg-white rounded-3xl border-2 border-[#E5E5E5] shadow-2xl overflow-hidden flex flex-col p-6 text-center animate-in fade-in zoom-in-95 duration-150">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 w-9 h-9 rounded-full hover:bg-[#F7F9FA] text-[#777777] flex items-center justify-center transition-colors cursor-pointer"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="my-2 flex justify-center">
          <Mascot mood="sad" size="xl" outfit={userStats.activeOutfit} />
        </div>

        <div className="flex items-center justify-center gap-1.5 text-[#FF4B4B] my-2">
          <Heart className="w-6 h-6 fill-[#FF4B4B]" />
          <Heart className="w-6 h-6 fill-[#E5E5E5] text-[#E5E5E5]" />
          <Heart className="w-6 h-6 fill-[#E5E5E5] text-[#E5E5E5]" />
          <Heart className="w-6 h-6 fill-[#E5E5E5] text-[#E5E5E5]" />
          <Heart className="w-6 h-6 fill-[#E5E5E5] text-[#E5E5E5]" />
        </div>

        <h2 className="text-2xl font-black text-[#1B1C1C]">Hearts Kamu Telah Habis!</h2>
        <p className="text-sm text-[#777777] font-medium mt-1 mb-6">
          Jangan menyerah! Setiap kesalahan adalah bagian dari proses belajar. Pilih cara untuk mengisi ulang:
        </p>

        <div className="space-y-3 text-left">
          {/* Refill with gems */}
          <button
            onClick={handleRefillWithGems}
            className="w-full p-4 rounded-2xl border-2 border-[#1CB0F6] bg-[#F0F9FF] shadow-[0_3px_0_0_#1CB0F6] flex items-center justify-between transition-transform active:translate-y-1 active:shadow-none cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#1CB0F6] text-white flex items-center justify-center">
                <Heart className="w-5 h-5 fill-white" />
              </div>
              <div>
                <p className="font-extrabold text-sm text-[#1B1C1C]">Pulihkan 5 Hearts</p>
                <p className="text-xs text-[#777777]">Saldo Gems: {userStats.gems} Gems</p>
              </div>
            </div>
            <div className="flex items-center gap-1 font-black text-[#1CB0F6] text-sm">
              <Gem className="w-4 h-4 fill-[#1CB0F6]" />
              <span>100</span>
            </div>
          </button>

          {/* Practice */}
          <button
            onClick={handlePractice}
            className="w-full p-4 rounded-2xl border-2 border-[#E5E5E5] bg-white shadow-[0_3px_0_0_#E5E5E5] flex items-center justify-between hover:bg-[#F7F9FA] transition-transform active:translate-y-1 active:shadow-none cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#58CC02] text-white flex items-center justify-center">
                <Dumbbell className="w-5 h-5" />
              </div>
              <div>
                <p className="font-extrabold text-sm text-[#1B1C1C]">Latihan Mandiri Bebas</p>
                <p className="text-xs text-[#777777]">Ulas kartu kata FSRS tanpa risiko kehilangan nyawa</p>
              </div>
            </div>
            <span className="text-xs font-black text-[#58CC02] uppercase tracking-wider">Gratis</span>
          </button>

          {/* Super Subscription */}
          <button
            onClick={handleSuper}
            className="w-full p-4 rounded-2xl border-2 border-[#FFC800] bg-gradient-to-r from-[#FFFBEA] to-[#FFF3C4] shadow-[0_3px_0_0_#D9A700] flex items-center justify-between transition-transform active:translate-y-1 active:shadow-none cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#FFC800] text-[#683A00] flex items-center justify-center">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <div>
                <p className="font-extrabold text-sm text-[#683A00]">LinguaQuest Super</p>
                <p className="text-xs text-[#8C5000]">Hearts Tanpa Batas Selamanya</p>
              </div>
            </div>
            <span className="text-xs font-black text-[#683A00] uppercase tracking-wider bg-white/70 px-2 py-1 rounded-lg">Coba</span>
          </button>
        </div>

        <div className="mt-5">
          <TactileButton variant="neutral" size="sm" fullWidth onClick={onClose}>
            Nanti Saja
          </TactileButton>
        </div>
      </div>
    </div>
  );
};
