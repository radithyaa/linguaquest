import React from 'react';
import { sound } from '../../services/soundEffects';

interface TactileButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'neutral' | 'danger' | 'orange' | 'gold';
  size?: 'sm' | 'md' | 'lg';
  fullWidth?: boolean;
  icon?: React.ReactNode;
}

export const TactileButton: React.FC<TactileButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  fullWidth = false,
  icon,
  className = '',
  disabled = false,
  onClick,
  ...props
}) => {
  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    if (disabled) return;
    sound.playClick();
    if (onClick) onClick(e);
  };

  const variantStyles = {
    primary: 'bg-[#58CC02] text-white shadow-[0_4px_0_0_#46A302] hover:brightness-105 active:translate-y-1 active:shadow-none',
    secondary: 'bg-[#1CB0F6] text-white shadow-[0_4px_0_0_#1899D6] hover:brightness-105 active:translate-y-1 active:shadow-none',
    neutral: 'bg-white text-[#4B4B4B] border-2 border-[#E5E5E5] shadow-[0_4px_0_0_#E5E5E5] hover:bg-[#F7F9FA] active:translate-y-1 active:shadow-none',
    danger: 'bg-[#FF4B4B] text-white shadow-[0_4px_0_0_#EA2B2B] hover:brightness-105 active:translate-y-1 active:shadow-none',
    orange: 'bg-[#FF9600] text-white shadow-[0_4px_0_0_#D97F00] hover:brightness-105 active:translate-y-1 active:shadow-none',
    gold: 'bg-[#FFC800] text-[#683A00] shadow-[0_4px_0_0_#D9A700] hover:brightness-105 active:translate-y-1 active:shadow-none'
  };

  const sizeStyles = {
    sm: 'py-2 px-3.5 text-xs font-bold rounded-xl tracking-wider uppercase',
    md: 'py-3 px-5 text-sm font-extrabold rounded-2xl tracking-wider uppercase',
    lg: 'py-4 px-6 text-base font-extrabold rounded-2xl tracking-wider uppercase'
  };

  const disabledStyles = 'opacity-50 cursor-not-allowed transform-none shadow-none pointer-events-none bg-[#E5E5E5] text-[#AFAFAF] border-none';

  return (
    <button
      {...props}
      disabled={disabled}
      onClick={handleClick}
      className={`inline-flex items-center justify-center gap-2 cursor-pointer transition-all duration-75 select-none font-sans ${
        disabled ? disabledStyles : variantStyles[variant]
      } ${sizeStyles[size]} ${fullWidth ? 'w-full' : ''} ${className}`}
    >
      {icon && <span className="flex-shrink-0">{icon}</span>}
      <span>{children}</span>
    </button>
  );
};
