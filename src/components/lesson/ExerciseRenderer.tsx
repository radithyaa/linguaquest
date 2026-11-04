import React, { useState, useEffect } from 'react';
import { Volume2, VolumeX, Sparkles, CheckCircle2, RotateCcw } from 'lucide-react';
import { Exercise, ExerciseOption, WordPair } from '../../types';
import { sound } from '../../services/soundEffects';

interface ExerciseRendererProps {
  exercise: Exercise;
  userAnswer: string;
  onAnswerChange: (answer: string) => void;
  isEvaluated: boolean;
  isCorrect: boolean;
  onEnterPress?: () => void;
}

// Levenshtein distance for typo tolerance (SRS EXE-03: Distance <= 2)
export function getLevenshteinDistance(a: string, b: string): number {
  const normA = a.trim().toLowerCase().replace(/[.,!?'"]/g, '');
  const normB = b.trim().toLowerCase().replace(/[.,!?'"]/g, '');

  const matrix: number[][] = [];
  for (let i = 0; i <= normB.length; i++) matrix[i] = [i];
  for (let j = 0; j <= normA.length; j++) matrix[0][j] = j;

  for (let i = 1; i <= normB.length; i++) {
    for (let j = 1; j <= normA.length; j++) {
      if (normB.charAt(i - 1) === normA.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1, // substitution
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j] + 1      // deletion
        );
      }
    }
  }
  return matrix[normB.length][normA.length];
}

export const ExerciseRenderer: React.FC<ExerciseRendererProps> = ({
  exercise,
  userAnswer,
  onAnswerChange,
  isEvaluated,
  isCorrect,
  onEnterPress
}) => {
  // Play initial audio if exercise has an audioPhrase
  useEffect(() => {
    if (exercise.audioPhrase && exercise.kind === 'audio_listening') {
      const timer = setTimeout(() => {
        sound.speakText(exercise.audioPhrase!);
      }, 300);
      return () => clearTimeout(timer);
    }
  }, [exercise.id]);

  // Handle Audio playback
  const handlePlayAudio = (rate = 0.9) => {
    if (exercise.audioPhrase) {
      sound.speakText(exercise.audioPhrase, 'en-US', rate);
    }
  };

  // Multiple Choice Renderer
  if (exercise.kind === 'multiple_choice') {
    return (
      <div className="space-y-4">
        {exercise.audioPhrase && (
          <div className="flex items-center gap-3 mb-2">
            <button
              type="button"
              onClick={() => handlePlayAudio(0.9)}
              className="w-12 h-12 rounded-2xl bg-[#E1F5FE] text-[#1CB0F6] flex items-center justify-center hover:bg-[#B3E5FC] active:scale-95 transition-transform cursor-pointer"
            >
              <Volume2 className="w-6 h-6 fill-[#1CB0F6]" />
            </button>
            <span className="text-sm font-semibold text-[#777777]">Dengarkan pelafalan</span>
          </div>
        )}

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
          {exercise.options?.map((opt) => {
            const isSelected = userAnswer === opt.text;
            let btnStyle = 'border-[#E5E5E5] bg-white text-[#4B4B4B] shadow-[0_3px_0_0_#E5E5E5] hover:border-[#1CB0F6] hover:bg-[#F0F9FF]';
            
            if (isSelected) {
              btnStyle = 'border-[#1CB0F6] bg-[#DDF4FF] text-[#006590] shadow-[0_3px_0_0_#1CB0F6]';
            }
            if (isEvaluated) {
              if (opt.text.toLowerCase() === exercise.correctAnswer.toLowerCase()) {
                btnStyle = 'border-[#58CC02] bg-[#D7FFB8] text-[#2B6C00] shadow-[0_3px_0_0_#58CC02]';
              } else if (isSelected && !isCorrect) {
                btnStyle = 'border-[#FF4B4B] bg-[#FFDFE0] text-[#BA1A1A] shadow-[0_3px_0_0_#FF4B4B]';
              }
            }

            return (
              <button
                key={opt.id}
                type="button"
                disabled={isEvaluated}
                onClick={() => {
                  sound.playClick();
                  onAnswerChange(opt.text);
                }}
                className={`w-full p-4.5 rounded-2xl border-2 text-left font-bold text-base transition-all duration-75 active:translate-y-1 active:shadow-none cursor-pointer flex items-center justify-between ${btnStyle}`}
              >
                <span>{opt.text}</span>
                {opt.translation && (
                  <span className="text-xs text-[#777777] font-normal">{opt.translation}</span>
                )}
              </button>
            );
          })}
        </div>
      </div>
    );
  }

  // Word Bank Build Renderer
  if (exercise.kind === 'word_bank') {
    const activeWords = userAnswer ? userAnswer.split(' ').filter(Boolean) : [];
    const pool = exercise.wordBank || [];

    // Count how many times each token is in the answer
    const tokenCounts = activeWords.reduce<Record<string, number>>((acc, w) => {
      acc[w] = (acc[w] || 0) + 1;
      return acc;
    }, {});

    const handleWordClick = (word: string) => {
      if (isEvaluated) return;
      sound.playClick();
      const nextWords = [...activeWords, word];
      onAnswerChange(nextWords.join(' '));
    };

    const handleRemoveWord = (index: number) => {
      if (isEvaluated) return;
      sound.playClick();
      const nextWords = activeWords.filter((_, i) => i !== index);
      onAnswerChange(nextWords.join(' '));
    };

    return (
      <div className="space-y-6">
        {exercise.targetSentence && (
          <div className="p-4 rounded-2xl bg-[#F7F9FA] border-2 border-[#E5E5E5] flex items-center gap-3">
            <span className="text-xl">💬</span>
            <p className="font-extrabold text-lg text-[#1B1C1C]">{exercise.targetSentence}</p>
          </div>
        )}

        {/* Selected Tokens Area */}
        <div className="min-h-[72px] p-4 rounded-2xl border-2 border-dashed border-[#BECBB1] bg-[#FAFDF6] flex flex-wrap gap-2.5 items-center">
          {activeWords.length === 0 ? (
            <span className="text-sm font-semibold text-[#AFAFAF] italic">
              Ketuk kata-kata di bawah untuk menyusun kalimat...
            </span>
          ) : (
            activeWords.map((word, idx) => (
              <button
                key={idx}
                type="button"
                disabled={isEvaluated}
                onClick={() => handleRemoveWord(idx)}
                className="px-4 py-2.5 rounded-xl bg-white border-2 border-[#1CB0F6] text-[#006590] shadow-[0_3px_0_0_#1CB0F6] font-bold text-sm hover:brightness-95 active:translate-y-1 active:shadow-none transition-all cursor-pointer"
              >
                {word}
              </button>
            ))
          )}
        </div>

        {/* Pool of word tokens */}
        <div className="flex flex-wrap gap-2.5 justify-center pt-2">
          {pool.map((word, idx) => {
            // Count how many times this word is available in pool
            const availableCount = pool.filter((w) => w === word).length;
            const usedCount = tokenCounts[word] || 0;
            const isUsed = usedCount >= availableCount;

            return (
              <button
                key={idx}
                type="button"
                disabled={isUsed || isEvaluated}
                onClick={() => handleWordClick(word)}
                className={`px-4 py-2.5 rounded-xl border-2 font-bold text-sm transition-all duration-75 cursor-pointer ${
                  isUsed
                    ? 'border-transparent bg-[#E5E5E5] text-[#AFAFAF] shadow-none cursor-default'
                    : 'border-[#E5E5E5] bg-white text-[#4B4B4B] shadow-[0_3px_0_0_#E5E5E5] hover:border-[#1CB0F6] active:translate-y-1 active:shadow-none'
                }`}
              >
                {word}
              </button>
            );
          })}
        </div>
      </div>
    );
  }

  // Typing Translation Renderer
  if (exercise.kind === 'typing_translation') {
    return (
      <div className="space-y-4">
        {exercise.targetSentence && (
          <div className="p-4 rounded-2xl bg-[#F7F9FA] border-2 border-[#E5E5E5] flex items-center justify-between">
            <div className="flex items-center gap-3">
              <span className="text-xl">✍️</span>
              <p className="font-extrabold text-lg text-[#1B1C1C]">{exercise.targetSentence}</p>
            </div>
            {exercise.audioPhrase && (
              <button
                type="button"
                onClick={() => handlePlayAudio(0.9)}
                className="w-10 h-10 rounded-xl bg-[#E1F5FE] text-[#1CB0F6] flex items-center justify-center hover:bg-[#B3E5FC] active:scale-95 transition-transform cursor-pointer"
              >
                <Volume2 className="w-5 h-5 fill-[#1CB0F6]" />
              </button>
            )}
          </div>
        )}

        <div className="relative">
          <textarea
            disabled={isEvaluated}
            value={userAnswer}
            onChange={(e) => onAnswerChange(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                if (onEnterPress) onEnterPress();
              }
            }}
            placeholder="Ketik terjemahan dalam Bahasa Inggris..."
            rows={3}
            className={`w-full p-4 rounded-2xl border-2 text-base font-semibold focus:outline-hidden transition-all resize-none ${
              isEvaluated
                ? isCorrect
                  ? 'border-[#58CC02] bg-[#D7FFB8] text-[#2B6C00]'
                  : 'border-[#FF4B4B] bg-[#FFDFE0] text-[#BA1A1A]'
                : 'border-[#E5E5E5] bg-white text-[#1B1C1C] focus:border-[#1CB0F6]'
            }`}
          />
        </div>
        {exercise.hint && (
          <p className="text-xs text-[#777777] italic">💡 Petunjuk: {exercise.hint}</p>
        )}
      </div>
    );
  }

  // Audio Listening Renderer
  if (exercise.kind === 'audio_listening') {
    return (
      <div className="space-y-6 text-center">
        <div className="flex items-center justify-center gap-4 py-4">
          <button
            type="button"
            onClick={() => handlePlayAudio(0.9)}
            className="w-20 h-20 rounded-3xl bg-[#1CB0F6] text-white shadow-[0_5px_0_0_#1899D6] flex flex-col items-center justify-center hover:brightness-105 active:translate-y-1 active:shadow-none transition-all cursor-pointer"
          >
            <Volume2 className="w-9 h-9 fill-white" />
            <span className="text-[10px] font-extrabold uppercase mt-1 tracking-wider">Normal</span>
          </button>

          <button
            type="button"
            onClick={() => handlePlayAudio(0.6)}
            className="w-16 h-16 rounded-3xl bg-[#E1F5FE] text-[#1CB0F6] border-2 border-[#B3E5FC] shadow-[0_4px_0_0_#B3E5FC] flex flex-col items-center justify-center hover:bg-[#B3E5FC] active:translate-y-1 active:shadow-none transition-all cursor-pointer"
          >
            <span className="text-lg">🐢</span>
            <span className="text-[10px] font-extrabold uppercase tracking-wider">Lambat</span>
          </button>
        </div>

        <div className="max-w-md mx-auto">
          <input
            type="text"
            disabled={isEvaluated}
            value={userAnswer}
            onChange={(e) => onAnswerChange(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                if (onEnterPress) onEnterPress();
              }
            }}
            placeholder="Ketik apa yang Anda dengar..."
            className={`w-full p-4 rounded-2xl border-2 text-base font-semibold focus:outline-hidden text-center transition-all ${
              isEvaluated
                ? isCorrect
                  ? 'border-[#58CC02] bg-[#D7FFB8] text-[#2B6C00]'
                  : 'border-[#FF4B4B] bg-[#FFDFE0] text-[#BA1A1A]'
                : 'border-[#E5E5E5] bg-white text-[#1B1C1C] focus:border-[#1CB0F6]'
            }`}
          />
        </div>
      </div>
    );
  }

  // Pair Matching Renderer (Interactive 5 pairs)
  if (exercise.kind === 'pair_matching') {
    return (
      <PairMatchingExercise
        pairs={exercise.pairs || []}
        isEvaluated={isEvaluated}
        onComplete={() => onAnswerChange('all_paired')}
      />
    );
  }

  // Fill in the Blank Renderer
  if (exercise.kind === 'fill_in_the_blank') {
    return (
      <div className="space-y-6">
        <div className="p-6 rounded-3xl bg-[#F7F9FA] border-2 border-[#E5E5E5] text-center">
          <p className="text-xl font-black text-[#1B1C1C] leading-relaxed">
            {exercise.blankSentence?.replace('___', userAnswer ? `[ ${userAnswer} ]` : '_______')}
          </p>
        </div>

        <div className="grid grid-cols-2 gap-3 max-w-sm mx-auto">
          {exercise.options?.map((opt) => {
            const isSelected = userAnswer === opt.text;
            return (
              <button
                key={opt.id}
                type="button"
                disabled={isEvaluated}
                onClick={() => {
                  sound.playClick();
                  onAnswerChange(opt.text);
                }}
                className={`p-4 rounded-2xl border-2 font-extrabold text-base transition-all active:translate-y-1 active:shadow-none cursor-pointer ${
                  isSelected
                    ? 'border-[#1CB0F6] bg-[#DDF4FF] text-[#006590] shadow-[0_3px_0_0_#1CB0F6]'
                    : 'border-[#E5E5E5] bg-white text-[#4B4B4B] shadow-[0_3px_0_0_#E5E5E5] hover:border-[#1CB0F6]'
                }`}
              >
                {opt.text}
              </button>
            );
          })}
        </div>
      </div>
    );
  }

  // Interactive Story Renderer
  if (exercise.kind === 'interactive_story') {
    return (
      <div className="space-y-5">
        <div className="p-4 rounded-3xl bg-[#F7F9FA] border-2 border-[#E5E5E5] space-y-3.5 max-h-[320px] overflow-y-auto">
          {exercise.storySteps?.map((step, idx) => (
            <div
              key={idx}
              className="p-3.5 rounded-2xl bg-white border border-[#E5E5E5] shadow-xs flex items-start gap-3"
            >
              <div className="w-10 h-10 rounded-full bg-[#E1F5FE] flex items-center justify-center text-xl flex-shrink-0">
                {step.speakerAvatar}
              </div>
              <div className="flex-1">
                <div className="flex items-center justify-between">
                  <span className="font-extrabold text-xs text-[#006590] uppercase tracking-wider">
                    {step.speaker}
                  </span>
                  {step.audioText && (
                    <button
                      type="button"
                      onClick={() => sound.speakText(step.audioText!)}
                      className="text-[#1CB0F6] hover:scale-110 transition-transform cursor-pointer"
                    >
                      <Volume2 className="w-4 h-4 fill-[#1CB0F6]" />
                    </button>
                  )}
                </div>
                <p className="font-bold text-sm text-[#1B1C1C] mt-0.5">{step.text}</p>
                <p className="text-xs text-[#777777] italic mt-0.5">{step.translation}</p>
              </div>
            </div>
          ))}
        </div>

        <p className="font-extrabold text-sm text-[#1B1C1C] text-center pt-2">
          Pertanyaan Pemahaman: Apa inti dari percakapan di atas?
        </p>

        <div className="space-y-2.5">
          {exercise.options?.map((opt) => {
            const isSelected = userAnswer === opt.text;
            return (
              <button
                key={opt.id}
                type="button"
                disabled={isEvaluated}
                onClick={() => {
                  sound.playClick();
                  onAnswerChange(opt.text);
                }}
                className={`w-full p-4 rounded-2xl border-2 font-bold text-sm text-left transition-all active:translate-y-1 active:shadow-none cursor-pointer ${
                  isSelected
                    ? 'border-[#1CB0F6] bg-[#DDF4FF] text-[#006590] shadow-[0_3px_0_0_#1CB0F6]'
                    : 'border-[#E5E5E5] bg-white text-[#4B4B4B] shadow-[0_3px_0_0_#E5E5E5] hover:border-[#1CB0F6]'
                }`}
              >
                {opt.text}
              </button>
            );
          })}
        </div>
      </div>
    );
  }

  return null;
};

// Sub-component for 5-word Pair Matching Exercise
const PairMatchingExercise: React.FC<{
  pairs: WordPair[];
  isEvaluated: boolean;
  onComplete: () => void;
}> = ({ pairs, isEvaluated, onComplete }) => {
  const [selectedSource, setSelectedSource] = useState<string | null>(null);
  const [selectedTarget, setSelectedTarget] = useState<string | null>(null);
  const [matchedIds, setMatchedIds] = useState<string[]>([]);
  const [targetItems, setTargetItems] = useState<{ id: string; target: string }[]>([]);

  // Shuffle targets once on mount
  useEffect(() => {
    const shuffled = [...pairs]
      .sort(() => Math.random() - 0.5)
      .map((p) => ({ id: p.id, target: p.target }));
    setTargetItems(shuffled);
  }, [pairs]);

  const handleSourceClick = (id: string) => {
    if (isEvaluated || matchedIds.includes(id)) return;
    sound.playClick();
    setSelectedSource(id);

    if (selectedTarget) {
      checkMatch(id, selectedTarget);
    }
  };

  const handleTargetClick = (id: string) => {
    if (isEvaluated || matchedIds.includes(id)) return;
    sound.playClick();
    setSelectedTarget(id);

    if (selectedSource) {
      checkMatch(selectedSource, id);
    }
  };

  const checkMatch = (sourceId: string, targetId: string) => {
    if (sourceId === targetId) {
      // Correct pair!
      sound.playCorrect();
      const nextMatched = [...matchedIds, sourceId];
      setMatchedIds(nextMatched);
      setSelectedSource(null);
      setSelectedTarget(null);

      if (nextMatched.length === pairs.length) {
        onComplete();
      }
    } else {
      // Wrong pair
      sound.playIncorrect();
      setTimeout(() => {
        setSelectedSource(null);
        setSelectedTarget(null);
      }, 400);
    }
  };

  return (
    <div className="grid grid-cols-2 gap-4">
      {/* Left Column: Source words */}
      <div className="space-y-3">
        {pairs.map((p) => {
          const isMatched = matchedIds.includes(p.id);
          const isSelected = selectedSource === p.id;
          return (
            <button
              key={p.id}
              type="button"
              disabled={isMatched || isEvaluated}
              onClick={() => handleSourceClick(p.id)}
              className={`w-full p-4 rounded-2xl border-2 font-bold text-sm transition-all duration-75 cursor-pointer ${
                isMatched
                  ? 'border-transparent bg-[#E5E5E5] text-[#AFAFAF] shadow-none cursor-default'
                  : isSelected
                  ? 'border-[#1CB0F6] bg-[#DDF4FF] text-[#006590] shadow-[0_3px_0_0_#1CB0F6]'
                  : 'border-[#E5E5E5] bg-white text-[#4B4B4B] shadow-[0_3px_0_0_#E5E5E5] hover:border-[#1CB0F6]'
              }`}
            >
              {p.source}
            </button>
          );
        })}
      </div>

      {/* Right Column: Target words */}
      <div className="space-y-3">
        {targetItems.map((p) => {
          const isMatched = matchedIds.includes(p.id);
          const isSelected = selectedTarget === p.id;
          return (
            <button
              key={p.id}
              type="button"
              disabled={isMatched || isEvaluated}
              onClick={() => handleTargetClick(p.id)}
              className={`w-full p-4 rounded-2xl border-2 font-bold text-sm transition-all duration-75 cursor-pointer ${
                isMatched
                  ? 'border-transparent bg-[#E5E5E5] text-[#AFAFAF] shadow-none cursor-default'
                  : isSelected
                  ? 'border-[#1CB0F6] bg-[#DDF4FF] text-[#006590] shadow-[0_3px_0_0_#1CB0F6]'
                  : 'border-[#E5E5E5] bg-white text-[#4B4B4B] shadow-[0_3px_0_0_#E5E5E5] hover:border-[#1CB0F6]'
              }`}
            >
              {p.target}
            </button>
          );
        })}
      </div>
    </div>
  );
};
