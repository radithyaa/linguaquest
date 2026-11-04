import React from 'react';
import {
  Gem,
  Heart,
  Snowflake,
  ShieldCheck,
  Glasses,
  Sparkles,
  Check,
  ShoppingBag
} from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { ShopItem } from '../../types';
import { TactileButton } from '../ui/TactileButton';
import { Mascot } from '../ui/Mascot';

export const ShopView: React.FC = () => {
  const { shopItems, buyShopItem, userStats, toggleSuperSubscription, equipOutfit } = useApp();

  const handleBuy = (item: ShopItem) => {
    buyShopItem(item);
  };

  return (
    <div className="w-full max-w-2xl mx-auto pb-24 pt-2 space-y-8">
      {/* Header & Wallet Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-6 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_4px_0_0_#E5E5E5]">
        <div>
          <h1 className="text-2xl sm:text-3xl font-black text-[#1B1C1C]">Toko Virtual</h1>
          <p className="text-sm text-[#777777] font-medium mt-0.5">
            Gunakan Gems hasil belajarmu untuk membeli item perlindungan dan kostum maskot.
          </p>
        </div>

        <div className="flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-[#E1F5FE] border border-[#B3E5FC] self-start sm:self-center">
          <Gem className="w-6 h-6 fill-[#1CB0F6] text-[#1CB0F6]" />
          <div>
            <p className="text-[10px] font-extrabold uppercase tracking-wider text-[#006590]">
              Saldo Kamu
            </p>
            <p className="text-xl font-black text-[#1CB0F6] leading-none">{userStats.gems} Gems</p>
          </div>
        </div>
      </div>

      {/* SUPER / PREMIUM SUBSCRIPTION BANNER */}
      <div className="p-6 sm:p-8 rounded-3xl bg-gradient-to-r from-[#1B1C1C] to-[#2D3748] text-white shadow-xl relative overflow-hidden">
        <div className="relative z-10 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#FFC800] text-[#683A00] text-xs font-black uppercase tracking-wider">
              <Sparkles className="w-3.5 h-3.5" />
              <span>LinguaQuest Super</span>
            </div>
            <h2 className="text-2xl sm:text-3xl font-black">Belajar Tanpa Batas</h2>
            <p className="text-xs sm:text-sm text-gray-300 max-w-md">
              Dapatkan Hearts tak terbatas, latihan review kesalahan cerdas, bebas jeda iklan, dan unduh kurikulum offline!
            </p>

            <div className="flex flex-wrap gap-4 pt-2 text-xs font-bold text-gray-200">
              <span className="flex items-center gap-1">
                <Check className="w-4 h-4 text-[#58CC02]" /> Hearts Tak Terbatas
              </span>
              <span className="flex items-center gap-1">
                <Check className="w-4 h-4 text-[#58CC02]" /> FSRS Unlimited
              </span>
              <span className="flex items-center gap-1">
                <Check className="w-4 h-4 text-[#58CC02]" /> Paket Offline
              </span>
            </div>
          </div>

          <div className="flex-shrink-0 w-full sm:w-auto">
            <TactileButton
              variant="gold"
              size="lg"
              fullWidth
              onClick={toggleSuperSubscription}
            >
              {userStats.isSuperSubscriber ? 'Aktif (Super)' : 'Mulai Super'}
            </TactileButton>
          </div>
        </div>

        {/* Ambient glow */}
        <div className="absolute top-0 right-0 w-64 h-64 bg-[#1CB0F6]/10 rounded-full blur-3xl pointer-events-none" />
      </div>

      {/* ITEMS CATALOG */}
      <div>
        <h2 className="text-lg font-black text-[#1B1C1C] flex items-center gap-2 mb-4">
          <ShoppingBag className="w-5 h-5 text-[#58CC02]" />
          <span>Item Penguat Belajar & Kostum</span>
        </h2>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {shopItems
            .filter((item) => item.category !== 'subscription')
            .map((item) => {
              const isEquipped = userStats.activeOutfit === item.id;
              const isAffordable = item.costGems ? userStats.gems >= item.costGems : true;

              return (
                <div
                  key={item.id}
                  className="p-5 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_4px_0_0_#E5E5E5] flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-start justify-between gap-2 mb-3">
                      <div className="w-12 h-12 rounded-2xl bg-[#F7F9FA] border-2 border-[#E5E5E5] flex items-center justify-center flex-shrink-0">
                        {item.icon === 'snowflake' && (
                          <Snowflake className="w-6 h-6 text-[#1CB0F6]" />
                        )}
                        {item.icon === 'heart' && (
                          <Heart className="w-6 h-6 fill-[#FF4B4B] text-[#FF4B4B]" />
                        )}
                        {item.icon === 'hat' && <span className="text-2xl">🤠</span>}
                        {item.icon === 'glasses' && <Glasses className="w-6 h-6 text-[#1B1C1C]" />}
                        {item.icon === 'sparkles' && (
                          <Sparkles className="w-6 h-6 text-[#FFC800]" />
                        )}
                      </div>

                      {item.badge && (
                        <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-full bg-[#FFF3E0] text-[#FF9600] border border-[#FFE0B2]">
                          {item.badge}
                        </span>
                      )}
                    </div>

                    <h3 className="font-black text-base text-[#1B1C1C]">{item.name}</h3>
                    <p className="text-xs text-[#777777] font-medium mt-1 leading-relaxed">
                      {item.description}
                    </p>
                  </div>

                  <div className="pt-4 mt-3 border-t border-[#E5E5E5] flex items-center justify-between gap-3">
                    <div className="flex items-center gap-1 font-black text-[#1CB0F6] text-sm">
                      <Gem className="w-4 h-4 fill-[#1CB0F6]" />
                      <span>{item.costGems} Gems</span>
                    </div>

                    {item.category === 'cosmetic' ? (
                      <TactileButton
                        variant={isEquipped ? 'neutral' : 'secondary'}
                        size="sm"
                        onClick={() => {
                          if (isEquipped) {
                            equipOutfit('default');
                          } else {
                            if (isAffordable) {
                              buyShopItem(item);
                            }
                          }
                        }}
                      >
                        {isEquipped ? 'Dilepas' : 'Pakai'}
                      </TactileButton>
                    ) : (
                      <TactileButton
                        variant="primary"
                        size="sm"
                        disabled={!isAffordable}
                        onClick={() => handleBuy(item)}
                      >
                        Beli
                      </TactileButton>
                    )}
                  </div>
                </div>
              );
            })}
        </div>
      </div>
    </div>
  );
};
