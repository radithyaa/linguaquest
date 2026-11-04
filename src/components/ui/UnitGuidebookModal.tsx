import React from 'react';
import { X, Volume2, BookOpen, Lightbulb, Compass } from 'lucide-react';
import { Unit } from '../../types';
import { sound } from '../../services/soundEffects';
import { TactileButton } from './TactileButton';

interface UnitGuidebookModalProps {
  unit: Unit | null;
  onClose: () => void;
}

export const UnitGuidebookModal: React.FC<UnitGuidebookModalProps> = ({ unit, onClose }) => {
  if (!unit) return null;

  const { guidebook } = unit;

  const handleSpeak = (text: string) => {
    sound.speakText(text);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
      <div className="relative w-full max-w-2xl max-h-[85vh] bg-white rounded-3xl border-2 border-[#E5E5E5] shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Modal Header */}
        <div
          className="p-6 text-white flex items-center justify-between"
          style={{ backgroundColor: unit.color }}
        >
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-white/20 backdrop-blur-xs flex items-center justify-center">
              <BookOpen className="w-6 h-6 text-white" />
            </div>
            <div>
              <p className="text-xs uppercase font-extrabold tracking-wider text-white/80">
                Buku Panduan Unit {unit.unitNumber}
              </p>
              <h2 className="text-xl sm:text-2xl font-black">{unit.title}</h2>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-10 h-10 rounded-full bg-black/10 hover:bg-black/20 text-white flex items-center justify-center transition-colors cursor-pointer"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 overflow-y-auto space-y-6 text-[#4B4B4B]">
          {/* Summary */}
          <div className="p-4 rounded-2xl bg-[#F7F9FA] border border-[#E5E5E5]">
            <p className="text-sm font-medium leading-relaxed">{guidebook.summary}</p>
          </div>

          {/* Key Phrases */}
          {guidebook.keyPhrases && guidebook.keyPhrases.length > 0 && (
            <div>
              <div className="flex items-center gap-2 mb-3">
                <Compass className="w-5 h-5 text-[#1CB0F6]" />
                <h3 className="font-extrabold text-base text-[#1B1C1C]">Frasa Kunci & Pelafalan</h3>
              </div>
              <div className="grid gap-3">
                {guidebook.keyPhrases.map((phrase, idx) => (
                  <div
                    key={idx}
                    className="p-4 rounded-2xl bg-white border-2 border-[#E5E5E5] flex items-center justify-between gap-4 hover:border-[#1CB0F6] transition-colors"
                  >
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-base text-[#1B1C1C]">{phrase.phrase}</span>
                      </div>
                      <p className="text-sm text-[#777777] font-medium mt-0.5">{phrase.translation}</p>
                      <p className="text-xs text-[#AFAFAF] mt-1 italic">{phrase.context}</p>
                    </div>
                    <button
                      onClick={() => handleSpeak(phrase.audioText)}
                      title="Dengarkan pengucapan"
                      className="w-11 h-11 rounded-2xl bg-[#E1F5FE] hover:bg-[#B3E5FC] text-[#1CB0F6] flex items-center justify-center transition-transform active:scale-90 cursor-pointer flex-shrink-0"
                    >
                      <Volume2 className="w-5 h-5 fill-[#1CB0F6]" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Grammar Tips */}
          {guidebook.grammarTips && guidebook.grammarTips.length > 0 && (
            <div>
              <div className="flex items-center gap-2 mb-3">
                <Lightbulb className="w-5 h-5 text-[#FF9600]" />
                <h3 className="font-extrabold text-base text-[#1B1C1C]">Catatan Tata Bahasa Penting</h3>
              </div>
              <div className="space-y-3">
                {guidebook.grammarTips.map((tip, idx) => (
                  <div key={idx} className="p-4 rounded-2xl bg-[#FFF9F0] border-2 border-[#FFE8C2]">
                    <h4 className="font-extrabold text-sm text-[#8C5000] mb-1">{tip.title}</h4>
                    <p className="text-xs sm:text-sm text-[#4B4B4B] leading-relaxed mb-3">
                      {tip.explanation}
                    </p>
                    <div className="space-y-1.5 pt-2 border-t border-[#FFE0B2]">
                      {tip.examples.map((ex, exIdx) => (
                        <div key={exIdx} className="text-xs flex items-center justify-between">
                          <span className="font-bold text-[#2B6C00]">"{ex.source}"</span>
                          <span className="text-[#777777]">→ {ex.translation}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Cultural Note */}
          {guidebook.culturalNote && (
            <div className="p-4 rounded-2xl bg-[#F0FDF4] border-2 border-[#BBF7D0]">
              <h4 className="font-extrabold text-sm text-[#166534] mb-1">💡 Wawasan Budaya</h4>
              <p className="text-xs sm:text-sm text-[#15803D] leading-relaxed">
                {guidebook.culturalNote}
              </p>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="p-4 bg-[#F7F9FA] border-t border-[#E5E5E5] flex justify-end">
          <TactileButton variant="primary" size="md" onClick={onClose}>
            Selesai Membaca
          </TactileButton>
        </div>
      </div>
    </div>
  );
};
