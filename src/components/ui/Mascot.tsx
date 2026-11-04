import React from 'react';

export type MascotMood = 'happy' | 'cheering' | 'thinking' | 'sad' | 'victory';

interface MascotProps {
  mood?: MascotMood;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  outfit?: string;
  className?: string;
}

export const Mascot: React.FC<MascotProps> = ({
  mood = 'happy',
  size = 'md',
  outfit = 'default',
  className = ''
}) => {
  const sizeMap = {
    sm: 'w-10 h-10',
    md: 'w-16 h-16',
    lg: 'w-24 h-24',
    xl: 'w-36 h-36'
  };

  return (
    <div className={`relative inline-flex items-center justify-center ${sizeMap[size]} ${className}`}>
      <svg
        viewBox="0 0 100 100"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-full drop-shadow-md select-none"
      >
        {/* Glow / Shadow base */}
        <ellipse cx="50" cy="92" rx="30" ry="6" fill="#000000" fillOpacity="0.12" />

        {/* Mascot Body (Vibrant Emerald Owl / Fox Hybrid) */}
        <path
          d="M 50 14 C 28 14 18 32 18 56 C 18 78 30 88 50 88 C 70 88 82 78 82 56 C 82 32 72 14 50 14 Z"
          fill="#58CC02"
        />
        {/* 3D Bottom Lip / Shadow */}
        <path
          d="M 21 68 C 26 84 36 88 50 88 C 64 88 74 84 79 68 C 70 76 58 80 50 80 C 42 80 30 76 21 68 Z"
          fill="#46A302"
        />

        {/* Belly patch */}
        <ellipse cx="50" cy="62" rx="20" ry="18" fill="#87FE45" />

        {/* Ears / Tuft */}
        <path d="M 28 16 L 36 28 L 22 28 Z" fill="#46A302" />
        <path d="M 72 16 L 78 28 L 64 28 Z" fill="#46A302" />

        {/* Wings */}
        <path
          d={
            mood === 'cheering' || mood === 'victory'
              ? 'M 20 48 C 10 38 4 30 10 24 C 16 18 24 34 26 42 Z'
              : 'M 20 48 C 12 52 8 62 12 70 C 16 76 22 72 24 64 Z'
          }
          fill="#46A302"
        />
        <path
          d={
            mood === 'cheering' || mood === 'victory'
              ? 'M 80 48 C 90 38 96 30 90 24 C 84 18 76 34 74 42 Z'
              : 'M 80 48 C 88 52 92 62 88 70 C 84 76 78 72 76 64 Z'
          }
          fill="#46A302"
        />

        {/* Eyes based on mood */}
        {mood === 'happy' && (
          <>
            {/* Left Eye */}
            <circle cx="38" cy="42" r="9" fill="#FFFFFF" />
            <circle cx="40" cy="42" r="5" fill="#1B1C1C" />
            <circle cx="42" cy="40" r="2" fill="#FFFFFF" />
            {/* Right Eye */}
            <circle cx="62" cy="42" r="9" fill="#FFFFFF" />
            <circle cx="64" cy="42" r="5" fill="#1B1C1C" />
            <circle cx="66" cy="40" r="2" fill="#FFFFFF" />
            {/* Rosy Cheeks */}
            <ellipse cx="28" cy="52" rx="4" ry="2.5" fill="#FF8BA7" fillOpacity="0.7" />
            <ellipse cx="72" cy="52" rx="4" ry="2.5" fill="#FF8BA7" fillOpacity="0.7" />
          </>
        )}

        {mood === 'cheering' && (
          <>
            {/* Joyful curved eyes (^_^) */}
            <path d="M 31 43 Q 38 34 45 43" stroke="#1B1C1C" strokeWidth="4" strokeLinecap="round" fill="none" />
            <path d="M 55 43 Q 62 34 69 43" stroke="#1B1C1C" strokeWidth="4" strokeLinecap="round" fill="none" />
            <ellipse cx="27" cy="48" rx="4" ry="2.5" fill="#FF5252" fillOpacity="0.8" />
            <ellipse cx="73" cy="48" rx="4" ry="2.5" fill="#FF5252" fillOpacity="0.8" />
          </>
        )}

        {mood === 'victory' && (
          <>
            {/* Starry victory eyes */}
            <circle cx="38" cy="42" r="10" fill="#FFFFFF" />
            <polygon points="38,36 40,40 44,40 41,43 42,47 38,44 34,47 35,43 32,40 36,40" fill="#FFC800" />
            <circle cx="62" cy="42" r="10" fill="#FFFFFF" />
            <polygon points="62,36 64,40 68,40 65,43 66,47 62,44 58,47 59,43 56,40 60,40" fill="#FFC800" />
            <ellipse cx="27" cy="50" rx="4" ry="2.5" fill="#FF8BA7" fillOpacity="0.8" />
            <ellipse cx="73" cy="50" rx="4" ry="2.5" fill="#FF8BA7" fillOpacity="0.8" />
          </>
        )}

        {mood === 'thinking' && (
          <>
            <circle cx="38" cy="40" r="8" fill="#FFFFFF" />
            <circle cx="39" cy="38" r="4" fill="#1B1C1C" />
            <path d="M 54 44 Q 62 38 70 42" stroke="#1B1C1C" strokeWidth="3.5" strokeLinecap="round" fill="none" />
          </>
        )}

        {mood === 'sad' && (
          <>
            <circle cx="38" cy="44" r="8" fill="#FFFFFF" />
            <circle cx="38" cy="45" r="4" fill="#1B1C1C" />
            <circle cx="62" cy="44" r="8" fill="#FFFFFF" />
            <circle cx="62" cy="45" r="4" fill="#1B1C1C" />
            {/* Little tear */}
            <ellipse cx="32" cy="54" rx="2" ry="3" fill="#1CB0F6" />
          </>
        )}

        {/* Beak */}
        <polygon points="46,47 54,47 50,56" fill="#FF9600" />
        <polygon points="48,53 52,53 50,56" fill="#D97F00" />

        {/* Feet */}
        <ellipse cx="40" cy="88" rx="6" ry="3" fill="#FF9600" />
        <ellipse cx="60" cy="88" rx="6" ry="3" fill="#FF9600" />

        {/* OUTFITS */}
        {outfit === 'item_hat_adventurer' && (
          <g>
            <path d="M 24 20 Q 50 12 76 20 L 74 24 Q 50 18 26 24 Z" fill="#8C5000" />
            <path d="M 32 18 C 32 4 68 4 68 18 Z" fill="#FF9C27" />
            <rect x="33" y="16" width="34" height="4" fill="#2B6C00" rx="1" />
            <polygon points="48,15 52,15 50,18" fill="#FFC800" />
          </g>
        )}

        {outfit === 'item_glasses_cool' && (
          <g>
            <rect x="26" y="36" width="22" height="12" rx="4" fill="#1B1C1C" />
            <rect x="52" y="36" width="22" height="12" rx="4" fill="#1B1C1C" />
            <rect x="46" y="40" width="8" height="3" fill="#1B1C1C" />
            <line x1="28" y1="38" x2="36" y2="46" stroke="#FFFFFF" strokeWidth="1.5" strokeOpacity="0.5" />
            <line x1="54" y1="38" x2="62" y2="46" stroke="#FFFFFF" strokeWidth="1.5" strokeOpacity="0.5" />
          </g>
        )}

        {outfit === 'item_suit_gold' && (
          <g>
            {/* Gold Champion Suit */}
            <path d="M 32 64 L 50 84 L 68 64 L 62 86 L 38 86 Z" fill="#FFC800" />
            {/* Bowtie */}
            <polygon points="46,58 50,61 46,64" fill="#BA1A1A" />
            <polygon points="54,58 50,61 54,64" fill="#BA1A1A" />
            <circle cx="50" cy="61" r="2" fill="#BA1A1A" />
          </g>
        )}
      </svg>
    </div>
  );
};
