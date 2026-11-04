import React, { useState } from 'react';
import {
  Brain,
  RotateCw,
  Volume2,
  CheckCircle2,
  AlertTriangle,
  BookOpen,
  Sparkles,
  Search,
  Layers
} from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { sound } from '../../services/soundEffects';
import { TactileButton } from '../ui/TactileButton';
import { FSRSCard } from '../../types';

export const PracticeView: React.FC = () => {
  const { fsrsCards, reviewFsrsCard, mistakesQueue, clearMistakeFromQueue, startLesson } = useApp();
  const [subTab, setSubTab] = useState<'fsrs' | 'mistakes' | 'words'>('fsrs');

  // Flashcards state
  const [currentCardIndex, setCurrentCardIndex] = useState(0);
  const [isFlipped, setIsFlipped] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const currentCard: FSRSCard | undefined = fsrsCards[currentCardIndex % fsrsCards.length];

  const handleCardRate = (rating: 1 | 2 | 3 | 4) => {
    if (!currentCard) return;
    reviewFsrsCard(currentCard.id, rating);
    setIsFlipped(false);
    setCurrentCardIndex((prev) => (prev + 1) % fsrsCards.length);
  };

  const handleSpeak = (text: string) => {
    sound.speakText(text);
  };

  // Filtered vocabulary list
  const filteredWords = fsrsCards.filter(
    (c) =>
      c.word.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.translation.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="w-full max-w-2xl mx-auto pb-24 pt-2">
      {/* Page Header */}
      <div className="mb-6">
        <h1 className="text-2xl sm:text-3xl font-black text-[#1B1C1C]">Hub Latihan Mandiri</h1>
        <p className="text-sm text-[#777777] font-medium mt-1">
          Perkuat ingatan jangka panjangmu dengan metode ilmiah Spaced Repetition (FSRS 4.5).
        </p>

        {/* 3 Sub-Navigation Tabs */}
        <div className="flex gap-2 p-1.5 rounded-2xl bg-[#E5E5E5]/60 mt-4">
          <button
            onClick={() => setSubTab('fsrs')}
            className={`flex-1 py-2.5 px-3 rounded-xl font-bold text-xs sm:text-sm transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
              subTab === 'fsrs'
                ? 'bg-white text-[#1CB0F6] shadow-xs'
                : 'text-[#4B4B4B] hover:text-[#1B1C1C]'
            }`}
          >
            <Brain className="w-4 h-4" />
            <span>FSRS Flashcards</span>
          </button>

          <button
            onClick={() => setSubTab('mistakes')}
            className={`flex-1 py-2.5 px-3 rounded-xl font-bold text-xs sm:text-sm transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
              subTab === 'mistakes'
                ? 'bg-white text-[#FF4B4B] shadow-xs'
                : 'text-[#4B4B4B] hover:text-[#1B1C1C]'
            }`}
          >
            <RotateCw className="w-4 h-4" />
            <span>Ulang Kesalahan ({mistakesQueue.length})</span>
          </button>

          <button
            onClick={() => setSubTab('words')}
            className={`flex-1 py-2.5 px-3 rounded-xl font-bold text-xs sm:text-sm transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
              subTab === 'words'
                ? 'bg-white text-[#58CC02] shadow-xs'
                : 'text-[#4B4B4B] hover:text-[#1B1C1C]'
            }`}
          >
            <BookOpen className="w-4 h-4" />
            <span>Kamus Kosakata</span>
          </button>
        </div>
      </div>

      {/* SUBTAB 1: FSRS FLASHCARDS */}
      {subTab === 'fsrs' && currentCard && (
        <div className="space-y-6 animate-in fade-in duration-150">
          {/* FSRS Stats Strip */}
          <div className="flex items-center justify-between px-4 py-2.5 rounded-2xl bg-[#E1F5FE] border border-[#B3E5FC] text-xs font-bold text-[#006590]">
            <div className="flex items-center gap-2">
              <Layers className="w-4 h-4 text-[#1CB0F6]" />
              <span>Kartu {currentCardIndex + 1} dari {fsrsCards.length}</span>
            </div>
            <div className="flex items-center gap-3">
              <span>Daya Ingat: {Math.round(currentCard.retrievability * 100)}%</span>
              <span className="px-2 py-0.5 rounded-full bg-white text-[#1CB0F6] font-extrabold text-[10px]">
                {currentCard.masteryLevel}
              </span>
            </div>
          </div>

          {/* Interactive Flip Card */}
          <div
            onClick={() => {
              sound.playClick();
              setIsFlipped(!isFlipped);
            }}
            className="w-full min-h-[260px] p-6 sm:p-8 rounded-3xl bg-white border-2 border-[#E5E5E5] shadow-[0_6px_0_0_#E5E5E5] hover:border-[#1CB0F6] transition-all cursor-pointer flex flex-col justify-between text-center select-none"
          >
            <div className="flex items-center justify-between text-[#777777] text-xs font-semibold">
              <span className="uppercase tracking-wider">{currentCard.partOfSpeech}</span>
              <span className="text-[#1CB0F6] flex items-center gap-1">
                <RotateCw className="w-3.5 h-3.5" />
                Ketuk untuk membalik
              </span>
            </div>

            <div className="py-6">
              {!isFlipped ? (
                <div>
                  <h2 className="text-3xl sm:text-4xl font-black text-[#1B1C1C] mb-2">
                    {currentCard.word}
                  </h2>
                  <p className="text-xs sm:text-sm text-[#777777] italic">
                    Apakah kamu mengingat arti dari kata ini?
                  </p>
                </div>
              ) : (
                <div className="animate-in fade-in duration-150">
                  <h2 className="text-2xl sm:text-3xl font-black text-[#58CC02] mb-1">
                    {currentCard.translation}
                  </h2>
                  <div className="mt-4 p-3 rounded-2xl bg-[#F7F9FA] border border-[#E5E5E5] text-left">
                    <p className="text-xs sm:text-sm font-bold text-[#1B1C1C]">
                      "{currentCard.example}"
                    </p>
                    <p className="text-xs text-[#777777] mt-0.5">
                      → {currentCard.exampleTranslation}
                    </p>
                  </div>
                </div>
              )}
            </div>

            <div className="flex items-center justify-center">
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  handleSpeak(currentCard.word);
                }}
                className="w-10 h-10 rounded-full bg-[#E1F5FE] text-[#1CB0F6] flex items-center justify-center hover:bg-[#B3E5FC] active:scale-95 transition-transform cursor-pointer"
              >
                <Volume2 className="w-5 h-5 fill-[#1CB0F6]" />
              </button>
            </div>
          </div>

          {/* FSRS 4.5 Rating Actions */}
          <div className="space-y-2">
            <p className="text-xs font-extrabold uppercase tracking-wider text-[#777777] text-center">
              Tingkat Kemudahan Mengingat (FSRS Algorithm)
            </p>
            <div className="grid grid-cols-4 gap-2">
              <button
                onClick={() => handleCardRate(1)}
                className="p-3 rounded-2xl border-2 border-[#FF4B4B] bg-white text-[#FF4B4B] shadow-[0_3px_0_0_#EA2B2B] font-extrabold text-xs sm:text-sm hover:bg-[#FFDFE0] active:translate-y-1 active:shadow-none transition-all cursor-pointer text-center"
              >
                <div>Again</div>
                <div className="text-[10px] font-normal opacity-80 mt-0.5">Lupa (10m)</div>
              </button>

              <button
                onClick={() => handleCardRate(2)}
                className="p-3 rounded-2xl border-2 border-[#FF9600] bg-white text-[#FF9600] shadow-[0_3px_0_0_#D97F00] font-extrabold text-xs sm:text-sm hover:bg-[#FFF3E0] active:translate-y-1 active:shadow-none transition-all cursor-pointer text-center"
              >
                <div>Hard</div>
                <div className="text-[10px] font-normal opacity-80 mt-0.5">Sulit (1h)</div>
              </button>

              <button
                onClick={() => handleCardRate(3)}
                className="p-3 rounded-2xl border-2 border-[#1CB0F6] bg-white text-[#1CB0F6] shadow-[0_3px_0_0_#1899D6] font-extrabold text-xs sm:text-sm hover:bg-[#E1F5FE] active:translate-y-1 active:shadow-none transition-all cursor-pointer text-center"
              >
                <div>Good</div>
                <div className="text-[10px] font-normal opacity-80 mt-0.5">Bagus (3h)</div>
              </button>

              <button
                onClick={() => handleCardRate(4)}
                className="p-3 rounded-2xl border-2 border-[#58CC02] bg-white text-[#58CC02] shadow-[0_3px_0_0_#46A302] font-extrabold text-xs sm:text-sm hover:bg-[#D7FFB8] active:translate-y-1 active:shadow-none transition-all cursor-pointer text-center"
              >
                <div>Easy</div>
                <div className="text-[10px] font-normal opacity-80 mt-0.5">Mudah (7h)</div>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* SUBTAB 2: ULANG KESALAHAN */}
      {subTab === 'mistakes' && (
        <div className="space-y-4 animate-in fade-in duration-150">
          {mistakesQueue.length === 0 ? (
            <div className="p-8 rounded-3xl bg-white border-2 border-[#E5E5E5] text-center shadow-xs">
              <div className="w-14 h-14 rounded-2xl bg-[#D7FFB8] text-[#58CC02] flex items-center justify-center mx-auto mb-3">
                <CheckCircle2 className="w-8 h-8" />
              </div>
              <h3 className="text-xl font-black text-[#1B1C1C]">Tidak Ada Catatan Kesalahan!</h3>
              <p className="text-sm text-[#777777] font-medium mt-1">
                Kamu menjawab semua soal dengan akurat di sesi belajar terakhir. Kerja bagus!
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              <p className="text-xs font-bold text-[#777777]">
                Daftar soal yang perlu kamu latih ulang agar terbebas dari kesalahan:
              </p>
              {mistakesQueue.map((item, idx) => (
                <div
                  key={idx}
                  className="p-4 rounded-2xl bg-white border-2 border-[#FF4B4B] shadow-[0_3px_0_0_#FF4B4B] flex items-center justify-between gap-4"
                >
                  <div>
                    <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-md bg-[#FFDFE0] text-[#BA1A1A]">
                      {item.kind}
                    </span>
                    <h4 className="font-black text-sm text-[#1B1C1C] mt-1">{item.prompt}</h4>
                    {item.targetSentence && (
                      <p className="text-xs font-bold text-[#4B4B4B] mt-0.5">
                        "{item.targetSentence}"
                      </p>
                    )}
                    <p className="text-xs text-[#58CC02] font-extrabold mt-1">
                      Kunci Jawaban: {item.correctAnswer}
                    </p>
                  </div>

                  <TactileButton
                    variant="neutral"
                    size="sm"
                    onClick={() => {
                      sound.playCorrect();
                      clearMistakeFromQueue(item.id);
                    }}
                  >
                    Tandai Paham
                  </TactileButton>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* SUBTAB 3: KAMUS KOSAKATA */}
      {subTab === 'words' && (
        <div className="space-y-4 animate-in fade-in duration-150">
          {/* Search bar */}
          <div className="relative">
            <Search className="w-5 h-5 text-[#AFAFAF] absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Cari kata atau arti dalam kamus..."
              className="w-full pl-11 pr-4 py-3 rounded-2xl bg-white border-2 border-[#E5E5E5] text-sm font-semibold focus:outline-hidden focus:border-[#1CB0F6]"
            />
          </div>

          <div className="grid gap-3">
            {filteredWords.map((card) => (
              <div
                key={card.id}
                className="p-4 rounded-2xl bg-white border-2 border-[#E5E5E5] shadow-xs flex items-center justify-between gap-4 hover:border-[#1CB0F6] transition-colors"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-black text-base text-[#1B1C1C]">{card.word}</h3>
                    <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-[#E1F5FE] text-[#1CB0F6]">
                      {card.masteryLevel}
                    </span>
                  </div>
                  <p className="text-sm font-medium text-[#777777] mt-0.5">{card.translation}</p>
                  <p className="text-xs text-[#AFAFAF] italic mt-0.5">{card.example}</p>
                </div>

                <button
                  onClick={() => handleSpeak(card.word)}
                  title="Dengarkan pengucapan"
                  className="w-10 h-10 rounded-xl bg-[#F7F9FA] border border-[#E5E5E5] text-[#1CB0F6] flex items-center justify-center hover:bg-[#E1F5FE] active:scale-90 transition-transform cursor-pointer flex-shrink-0"
                >
                  <Volume2 className="w-5 h-5 fill-[#1CB0F6]" />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
