import React, { useState } from 'react';
import { X, Database, Sliders, Volume2, Plus, Sparkles, RefreshCw, Check } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { TactileButton } from '../ui/TactileButton';
import { sound } from '../../services/soundEffects';

interface AdminCMSModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const AdminCMSModal: React.FC<AdminCMSModalProps> = ({ isOpen, onClose }) => {
  const { currentCourse, userStats, refillHearts } = useApp();
  const [offlineSyncEnabled, setOfflineSyncEnabled] = useState(true);
  const [fsrsVersion, setFsrsVersion] = useState('4.5');
  const [testTtsText, setTestTtsText] = useState('Welcome to LinguaQuest audio test.');
  const [isCopied, setIsCopied] = useState(false);

  if (!isOpen) return null;

  const handleTestTts = () => {
    sound.speakText(testTtsText);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/55 backdrop-blur-xs">
      <div className="relative w-full max-w-2xl bg-white rounded-3xl border-2 border-[#E5E5E5] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="p-5 bg-[#1B1C1C] text-white flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#2D3748] flex items-center justify-center text-[#1CB0F6]">
              <Database className="w-5 h-5" />
            </div>
            <div>
              <span className="text-[10px] font-extrabold uppercase tracking-wider text-gray-400">
                LinguaQuest Admin & Content Management (CMS)
              </span>
              <h2 className="text-lg font-black">Panel Kontrol Kurikulum & Fitur (SRS 5.12)</h2>
            </div>
          </div>

          <button
            onClick={onClose}
            className="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 text-white flex items-center justify-center transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 overflow-y-auto space-y-6 text-[#4B4B4B]">
          {/* Active Course Status */}
          <div className="p-4 rounded-2xl bg-[#F7F9FA] border border-[#E5E5E5] space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-black uppercase text-[#777777]">Kurikulum Aktif</span>
              <span className="text-xs font-black px-2 py-0.5 rounded-full bg-[#D7FFB8] text-[#2B6C00]">
                v1.0 Published
              </span>
            </div>
            <h3 className="font-black text-base text-[#1B1C1C]">
              {currentCourse.title} ({currentCourse.flag})
            </h3>
            <p className="text-xs text-[#777777]">
              Total {currentCourse.units.length} Unit • {currentCourse.totalLearners} • Target bahasa: {currentCourse.toLang}
            </p>
          </div>

          {/* Cloud TTS Testing (SRS 5.12) */}
          <div className="space-y-2">
            <h4 className="font-black text-sm text-[#1B1C1C] flex items-center gap-2">
              <Volume2 className="w-4 h-4 text-[#1CB0F6]" />
              <span>Otomatisasi Audio Text-to-Speech (TTS Cloud Simulator)</span>
            </h4>
            <div className="flex gap-2">
              <input
                type="text"
                value={testTtsText}
                onChange={(e) => setTestTtsText(e.target.value)}
                className="flex-1 px-3.5 py-2.5 rounded-xl border-2 border-[#E5E5E5] text-sm font-semibold focus:outline-hidden focus:border-[#1CB0F6]"
                placeholder="Ketik teks kalimat untuk diuji suara..."
              />
              <TactileButton variant="secondary" size="sm" onClick={handleTestTts}>
                Uji Suara
              </TactileButton>
            </div>
          </div>

          {/* Feature Flags & A/B Config */}
          <div className="space-y-3 pt-2">
            <h4 className="font-black text-sm text-[#1B1C1C] flex items-center gap-2">
              <Sliders className="w-4 h-4 text-[#FF9600]" />
              <span>Feature Flags & Gamifikasi</span>
            </h4>

            <div className="space-y-2">
              <label className="flex items-center justify-between p-3.5 rounded-2xl border border-[#E5E5E5] hover:bg-[#F7F9FA] cursor-pointer">
                <div>
                  <p className="font-bold text-sm text-[#1B1C1C]">Offline Progress Sync Engine</p>
                  <p className="text-xs text-[#777777]">
                    Simpan operasi pelajaran ke antrean lokal Drift/IndexedDB dan sync otomatis saat online
                  </p>
                </div>
                <input
                  type="checkbox"
                  checked={offlineSyncEnabled}
                  onChange={(e) => setOfflineSyncEnabled(e.target.checked)}
                  className="w-5 h-5 accent-[#58CC02] cursor-pointer"
                />
              </label>

              <div className="flex items-center justify-between p-3.5 rounded-2xl border border-[#E5E5E5]">
                <div>
                  <p className="font-bold text-sm text-[#1B1C1C]">Algoritma Penjadwalan Spaced Repetition</p>
                  <p className="text-xs text-[#777777]">Model matematis stabilitas memori kosakata</p>
                </div>
                <select
                  value={fsrsVersion}
                  onChange={(e) => setFsrsVersion(e.target.value)}
                  className="px-3 py-1.5 rounded-xl border border-[#E5E5E5] text-xs font-black bg-white"
                >
                  <option value="4.5">FSRS v4.5 (Default)</option>
                  <option value="sm2">SuperMemo SM-2 (Legacy)</option>
                </select>
              </div>
            </div>
          </div>

          {/* Quick Dev Action Tools */}
          <div className="pt-2 border-t border-[#E5E5E5]">
            <h4 className="font-black text-sm text-[#1B1C1C] mb-2">Peralatan Pengujian Cepat</h4>
            <div className="flex flex-wrap gap-2">
              <TactileButton variant="primary" size="sm" onClick={refillHearts}>
                Pulihkan 5 Hearts
              </TactileButton>

              <TactileButton
                variant="neutral"
                size="sm"
                onClick={() => {
                  sound.playChestClaim();
                  window.location.reload();
                }}
                icon={<RefreshCw className="w-4 h-4" />}
              >
                Muat Ulang Aplikasi
              </TactileButton>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 bg-[#F7F9FA] border-t border-[#E5E5E5] flex justify-end">
          <TactileButton variant="neutral" size="sm" onClick={onClose}>
            Selesai
          </TactileButton>
        </div>
      </div>
    </div>
  );
};
