import React from 'react';
import { Flame, Heart, Gem, Infinity } from 'lucide-react';

interface StatBadgeProps {
  type: 'streak' | 'hearts' | 'gems';
  value: number;
  isSuper?: boolean;
  onClick?: () => void;
  className?: string;
}

export const StatBadge: React.FC<StatBadgeProps> = ({
  type,
  value,
  isSuper = false,
  onClick,
  className = ''
}) => {
  if (type === 'streak') {
    return (
      <button
        onClick={onClick}
        title="Streak Belajar Harian"
        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#FFF3E0] text-[#FF9600] border border-[#FFE0B2] font-black text-sm tracking-wide transition-transform active:scale-95 cursor-pointer shadow-xs ${className}`}
      >
        <Flame className="w-5 h-5 fill-[#FF9600] text-[#FF9600] animate-bounce" style={{ animationDuration: '3s' }} />
        <span>{value}</span>
      </button>
    );
  }

  if (type === 'gems') {
    return (
      <button
        onClick={onClick}
        title="Saldo Gems Virtual"
        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#E1F5FE] text-[#1CB0F6] border border-[#B3E5FC] font-black text-sm tracking-wide transition-transform active:scale-95 cursor-pointer shadow-xs ${className}`}
      >
        <Gem className="w-4.5 h-4.5 fill-[#1CB0F6] text-[#1CB0F6]" />
        <span>{value}</span>
      </button>
    );
  }

  if (type === 'hearts') {
    return (
      <button
        onClick={onClick}
        title={isSuper ? 'Hearts Tak Terbatas (LinguaQuest Super)' : 'Sisa Hearts / Nyawa Belajar'}
        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#FFEBEE] text-[#FF4B4B] border border-[#FFCDD2] font-black text-sm tracking-wide transition-transform active:scale-95 cursor-pointer shadow-xs ${className}`}
      >
        <Heart className="w-4.5 h-4.5 fill-[#FF4B4B] text-[#FF4B4B]" />
        {isSuper ? (
          <Infinity className="w-4.5 h-4.5 stroke-[3] text-[#FF4B4B]" />
        ) : (
          <span>{value}</span>
        )}
      </button>
    );
  }

  return null;
};
