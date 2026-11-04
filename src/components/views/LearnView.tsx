import React, { useState } from 'react';
import {
  BookOpen,
  Star,
  Lock,
  Gift,
  CheckCircle,
  Play,
  Trophy,
  Sparkles,
  BookMarked
} from 'lucide-react';
import { LearningNode, Unit } from '../../types';
import { useApp } from '../../context/AppContext';
import { sound } from '../../services/soundEffects';
import { TactileButton } from '../ui/TactileButton';
import { Mascot } from '../ui/Mascot';

export const LearnView: React.FC = () => {
  const { currentCourse, startLesson, openGuidebook, claimChest, userStats } = useApp();
  const [selectedNode, setSelectedNode] = useState<LearningNode | null>(null);

  // Horizontal curve offsets for winding path effect
  const getNodeOffset = (index: number) => {
    const offsets = ['translate-x-0', '-translate-x-12 sm:-translate-x-16', 'translate-x-12 sm:translate-x-16', '-translate-x-8 sm:-translate-x-10', 'translate-x-8 sm:translate-x-10'];
    return offsets[index % offsets.length];
  };

  const handleNodeClick = (node: LearningNode, unit: Unit) => {
    sound.playClick();
    if (node.kind === 'chest') {
      if (!node.chestClaimed) {
        claimChest(node.id);
      }
      return;
    }
    if (node.status === 'locked') {
      sound.playIncorrect();
      return;
    }
    setSelectedNode(node);
  };

  return (
    <div className="w-full max-w-xl mx-auto pb-24 pt-2">
      {currentCourse.units.map((unit) => (
        <div key={unit.id} className="mb-12">
          {/* Unit Header Banner */}
          <div
            className="p-5 rounded-3xl text-white shadow-md mb-8 relative overflow-hidden"
            style={{
              backgroundColor: unit.color,
              boxShadow: `0 6px 0 0 ${unit.shadowColor}`
            }}
          >
            <div className="relative z-10 flex items-center justify-between gap-4">
              <div>
                <p className="text-xs font-black uppercase tracking-wider text-white/80">
                  Unit {unit.unitNumber}
                </p>
                <h2 className="text-xl sm:text-2xl font-black mt-0.5">{unit.title}</h2>
                <p className="text-xs sm:text-sm text-white/90 font-medium mt-1">
                  {unit.description}
                </p>
              </div>

              <TactileButton
                variant="neutral"
                size="sm"
                onClick={() => openGuidebook(unit)}
                icon={<BookOpen className="w-4 h-4 text-[#1CB0F6]" />}
                className="flex-shrink-0 !text-[#1B1C1C]"
              >
                Panduan
              </TactileButton>
            </div>

            {/* Subtle background decorative shapes */}
            <div className="absolute -bottom-6 -right-6 w-28 h-28 rounded-full bg-white/10 pointer-events-none" />
          </div>

          {/* Vertical Winding Learning Path */}
          <div className="flex flex-col items-center gap-7 relative">
            {unit.nodes.map((node, idx) => {
              const isMastered = node.status === 'mastered';
              const isUnlocked = node.status === 'unlocked';
              const isLocked = node.status === 'locked';
              const offsetClass = getNodeOffset(idx);

              // Connecting dotted line between nodes
              return (
                <div key={node.id} className="flex flex-col items-center relative">
                  {idx > 0 && (
                    <div className="w-2.5 h-6 bg-[#E5E5E5] rounded-full my-[-8px] z-0" />
                  )}

                  {/* Node Button */}
                  <div className={`relative transition-transform duration-150 ${offsetClass} z-10`}>
                    {/* Bouncing Mascot indicator on the current active unlocked node */}
                    {isUnlocked && node.kind !== 'chest' && (
                      <div className="absolute -top-12 left-1/2 -translate-x-1/2 flex flex-col items-center animate-soft-bounce pointer-events-none">
                        <div className="bg-[#58CC02] text-white text-[10px] font-black uppercase px-2.5 py-1 rounded-full shadow-md tracking-wider">
                          Mulai!
                        </div>
                        <div className="w-2 h-2 bg-[#58CC02] rotate-45 -mt-1" />
                      </div>
                    )}

                    {/* Chest Node */}
                    {node.kind === 'chest' ? (
                      <button
                        onClick={() => handleNodeClick(node, unit)}
                        title="Buka Peti Hadiah Gems"
                        className={`w-18 h-18 rounded-3xl border-2 flex items-center justify-center transition-all cursor-pointer ${
                          node.chestClaimed
                            ? 'bg-[#E5E5E5] border-[#CCCCCC] text-[#AFAFAF] shadow-none cursor-default'
                            : 'bg-[#FFC800] border-[#D9A700] text-[#683A00] shadow-[0_5px_0_0_#D9A700] hover:scale-105 active:translate-y-1 active:shadow-none animate-pulse-glow'
                        }`}
                      >
                        <Gift className="w-8 h-8" />
                      </button>
                    ) : (
                      /* Circular Lesson Node (72px x 72px) */
                      <button
                        onClick={() => handleNodeClick(node, unit)}
                        disabled={isLocked}
                        className={`w-18 h-18 sm:w-20 sm:h-20 rounded-full flex flex-col items-center justify-center transition-all duration-75 select-none cursor-pointer node-btn ${
                          isMastered
                            ? 'bg-[#FFC800] text-[#683A00] shadow-[0_6px_0_0_#D9A700] border-2 border-[#FFE885]'
                            : isUnlocked
                            ? 'bg-[#58CC02] text-white shadow-[0_6px_0_0_#46A302] border-2 border-[#87FE45]'
                            : 'bg-[#E5E5E5] text-[#AFAFAF] shadow-[0_5px_0_0_#CCCCCC] border-none cursor-not-allowed'
                        }`}
                      >
                        {isMastered && (
                          <div className="flex flex-col items-center">
                            <Trophy className="w-7 h-7 text-[#683A00]" />
                            <div className="flex gap-0.5 -mt-0.5">
                              <Star className="w-2.5 h-2.5 fill-[#683A00] text-[#683A00]" />
                              <Star className="w-3 h-3 fill-[#683A00] text-[#683A00]" />
                              <Star className="w-2.5 h-2.5 fill-[#683A00] text-[#683A00]" />
                            </div>
                          </div>
                        )}

                        {isUnlocked && (
                          <Star className="w-8 h-8 fill-white text-white drop-shadow-xs" />
                        )}

                        {isLocked && <Lock className="w-6 h-6 text-[#AFAFAF]" />}
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      ))}

      {/* Selected Node Bottom Drawer / Modal */}
      {selectedNode && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4 bg-black/45 backdrop-blur-xs">
          <div className="relative w-full max-w-sm bg-white rounded-3xl border-2 border-[#E5E5E5] shadow-2xl p-6 text-center animate-in fade-in slide-in-from-bottom-6 duration-150">
            <div className="flex justify-center mb-2">
              <Mascot mood="cheering" size="lg" outfit={userStats.activeOutfit} />
            </div>

            <span className="text-xs font-black uppercase tracking-wider text-[#1CB0F6]">
              {selectedNode.status === 'mastered' ? 'Ulas Materi' : 'Pelajaran Berikutnya'}
            </span>
            <h3 className="text-xl font-black text-[#1B1C1C] mt-0.5">{selectedNode.title}</h3>
            <p className="text-xs sm:text-sm text-[#777777] font-medium mt-1 mb-6">
              {selectedNode.subtitle}
            </p>

            <div className="flex items-center justify-center gap-4 mb-6 text-xs font-black text-[#4B4B4B]">
              <span className="px-3 py-1.5 rounded-xl bg-[#FFF3E0] text-[#FF9600] border border-[#FFE0B2]">
                +{selectedNode.rewardXp} XP
              </span>
              <span className="px-3 py-1.5 rounded-xl bg-[#E1F5FE] text-[#1CB0F6] border border-[#B3E5FC]">
                +{selectedNode.rewardGems} Gems
              </span>
            </div>

            <div className="space-y-2.5">
              <TactileButton
                variant="primary"
                size="lg"
                fullWidth
                onClick={() => {
                  const nodeToStart = selectedNode;
                  setSelectedNode(null);
                  startLesson(nodeToStart);
                }}
                icon={<Play className="w-5 h-5 fill-white" />}
              >
                Mulai Sesi
              </TactileButton>

              <TactileButton
                variant="neutral"
                size="md"
                fullWidth
                onClick={() => setSelectedNode(null)}
              >
                Batal
              </TactileButton>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
