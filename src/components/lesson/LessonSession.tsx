import React, { useState } from 'react';
import { X, Heart, Flame, Infinity, Check, AlertCircle, ArrowRight } from 'lucide-react';
import { LearningNode, Exercise } from '../../types';
import { useApp } from '../../context/AppContext';
import { sound } from '../../services/soundEffects';
import { ExerciseRenderer, getLevenshteinDistance } from './ExerciseRenderer';
import { LessonSummary } from './LessonSummary';
import { TactileButton } from '../ui/TactileButton';
import { Mascot } from '../ui/Mascot';

interface LessonSessionProps {
  node: LearningNode;
  onClose: () => void;
}

export const LessonSession: React.FC<LessonSessionProps> = ({ node, onClose }) => {
  const { userStats, finishLesson, deductHeart, addMistakeToQueue } = useApp();

  // Queue of exercises (including wrong ones re-added to end of queue per LES-02)
  const [exerciseQueue, setExerciseQueue] = useState<Exercise[]>(node.exercises);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [userAnswer, setUserAnswer] = useState('');
  const [isEvaluated, setIsEvaluated] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);
  const [feedbackMessage, setFeedbackMessage] = useState('');

  // Stats tracking for summary calculation
  const [totalAttempts, setTotalAttempts] = useState(0);
  const [firstTryCorrectCount, setFirstTryCorrectCount] = useState(0);
  const [currentCombo, setCurrentCombo] = useState(0);
  const [maxCombo, setMaxCombo] = useState(0);
  const [isCompleted, setIsCompleted] = useState(false);
  const [showExitConfirm, setShowExitConfirm] = useState(false);

  // Original total questions count
  const initialTotal = node.exercises.length || 1;
  const currentExercise = exerciseQueue[currentIndex];

  // Evaluate Answer
  const handleCheck = () => {
    if (!userAnswer.trim() || isEvaluated) return;

    setTotalAttempts((prev) => prev + 1);

    const targetNorm = currentExercise.correctAnswer.trim().toLowerCase();
    const userNorm = userAnswer.trim().toLowerCase();

    let correct = false;

    if (currentExercise.kind === 'typing_translation') {
      // Typing translation: distance <= 2 (SRS EXE-03)
      const dist = getLevenshteinDistance(userNorm, targetNorm);
      correct = dist <= 2;
    } else if (currentExercise.kind === 'pair_matching') {
      correct = userAnswer === 'all_paired';
    } else {
      correct = userNorm === targetNorm;
    }

    setIsCorrect(correct);
    setIsEvaluated(true);

    if (correct) {
      sound.playCorrect();
      const nextCombo = currentCombo + 1;
      setCurrentCombo(nextCombo);
      if (nextCombo > maxCombo) setMaxCombo(nextCombo);
      if (nextCombo >= 3) {
        sound.playCombo(nextCombo);
      }

      if (totalAttempts === currentIndex) {
        setFirstTryCorrectCount((prev) => prev + 1);
      }

      const praises = ['Bagus sekali! 🎉', 'Luar biasa! ⭐', 'Hebat! Kamu menguasainya! 🔥', 'Tepat sekali! 👏'];
      setFeedbackMessage(praises[Math.floor(Math.random() * praises.length)]);
    } else {
      sound.playIncorrect();
      setCurrentCombo(0);
      deductHeart();
      addMistakeToQueue(currentExercise);

      // LES-02: Repeat missed question at the end of session
      setExerciseQueue((prev) => [...prev, currentExercise]);
      setFeedbackMessage(`Jawaban yang benar: ${currentExercise.correctAnswer}`);
    }
  };

  const handleNext = () => {
    sound.playClick();
    setIsEvaluated(false);
    setUserAnswer('');

    if (currentIndex + 1 < exerciseQueue.length) {
      setCurrentIndex((prev) => prev + 1);
    } else {
      // Session Completed!
      setIsCompleted(true);
    }
  };

  // Summary XP Calculations (SRS Section 9.1)
  const accuracy = Math.round((firstTryCorrectCount / initialTotal) * 100);
  const xpBase = 10;
  const accuracyBonus = accuracy === 100 ? 5 : accuracy >= 90 ? 3 : 0;
  const comboBonus = Math.min(6, Math.floor(maxCombo / 5) * 2);
  const totalXp = xpBase + accuracyBonus + comboBonus;
  const gemsEarned = node.rewardGems || 10;

  const handleFinish = () => {
    finishLesson(node.id, totalXp, gemsEarned, accuracy);
  };

  if (isCompleted) {
    return (
      <LessonSummary
        xpBase={xpBase}
        accuracyBonus={accuracyBonus}
        comboBonus={comboBonus}
        totalXp={totalXp}
        accuracy={accuracy}
        maxCombo={maxCombo}
        gemsEarned={gemsEarned}
        streakCount={userStats.streak + 1}
        outfit={userStats.activeOutfit}
        onContinue={handleFinish}
      />
    );
  }

  // Calculate progress bar percentage
  const progressPercent = Math.min(100, Math.round(((currentIndex) / exerciseQueue.length) * 100));

  return (
    <div className="fixed inset-0 z-50 bg-[#F7F9FA] flex flex-col justify-between overflow-hidden">
      {/* Top Chrome / Progress Rail */}
      <div className="w-full max-w-3xl mx-auto px-4 py-4 sm:py-6 flex items-center justify-between gap-4">
        {/* Close Button */}
        <button
          onClick={() => setShowExitConfirm(true)}
          className="w-10 h-10 rounded-full hover:bg-[#E5E5E5] text-[#777777] flex items-center justify-center transition-colors cursor-pointer flex-shrink-0"
        >
          <X className="w-6 h-6" />
        </button>

        {/* Progress Gel Bar */}
        <div className="flex-1 h-4 bg-[#E5E5E5] rounded-full overflow-hidden relative">
          <div
            className="h-full gel-progress-fill rounded-full transition-all duration-300 ease-out"
            style={{ width: `${progressPercent}%` }}
          />
        </div>

        {/* Combo Multiplier indicator */}
        {currentCombo > 1 && (
          <div className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-[#FFF3E0] text-[#FF9600] border border-[#FFE0B2] text-xs font-black animate-pulse">
            <Flame className="w-4 h-4 fill-[#FF9600]" />
            <span>{currentCombo}x</span>
          </div>
        )}

        {/* Heart Count */}
        <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#FFEBEE] text-[#FF4B4B] border border-[#FFCDD2] font-black text-sm flex-shrink-0">
          <Heart className="w-5 h-5 fill-[#FF4B4B] animate-pulse" />
          {userStats.isSuperSubscriber ? (
            <Infinity className="w-4 h-4 stroke-[3]" />
          ) : (
            <span>{userStats.hearts}</span>
          )}
        </div>
      </div>

      {/* Main Interactive Exercise Workspace */}
      <div className="w-full max-w-2xl mx-auto px-4 py-2 flex-1 flex flex-col justify-center overflow-y-auto">
        {currentExercise ? (
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <Mascot
                mood={isEvaluated ? (isCorrect ? 'cheering' : 'sad') : 'happy'}
                size="md"
                outfit={userStats.activeOutfit}
              />
              <div>
                <span className="text-xs font-extrabold uppercase tracking-wider text-[#1CB0F6]">
                  Latihan {currentIndex + 1} dari {exerciseQueue.length}
                </span>
                <h2 className="text-lg sm:text-2xl font-black text-[#1B1C1C] leading-snug">
                  {currentExercise.prompt}
                </h2>
              </div>
            </div>

            <div className="pt-2">
              <ExerciseRenderer
                exercise={currentExercise}
                userAnswer={userAnswer}
                onAnswerChange={(ans) => setUserAnswer(ans)}
                isEvaluated={isEvaluated}
                isCorrect={isCorrect}
                onEnterPress={handleCheck}
              />
            </div>
          </div>
        ) : (
          <div className="text-center py-12">
            <p className="text-lg font-bold text-[#777777]">Memuat soal...</p>
          </div>
        )}
      </div>

      {/* Bottom Evaluation Banner & Action Bar */}
      <div
        className={`w-full border-t-2 transition-all duration-150 ${
          isEvaluated
            ? isCorrect
              ? 'bg-[#D7FFB8] border-[#58CC02] text-[#2B6C00]'
              : 'bg-[#FFDFE0] border-[#FF4B4B] text-[#BA1A1A]'
            : 'bg-white border-[#E5E5E5]'
        }`}
      >
        <div className="max-w-2xl mx-auto px-4 py-4 sm:py-5 flex flex-col sm:flex-row items-center justify-between gap-4">
          {isEvaluated ? (
            <>
              <div className="flex items-center gap-3 w-full sm:w-auto">
                <div
                  className={`w-12 h-12 rounded-2xl flex items-center justify-center flex-shrink-0 ${
                    isCorrect ? 'bg-[#58CC02] text-white' : 'bg-[#FF4B4B] text-white'
                  }`}
                >
                  {isCorrect ? (
                    <Check className="w-7 h-7 stroke-[3]" />
                  ) : (
                    <AlertCircle className="w-7 h-7" />
                  )}
                </div>
                <div>
                  <h3 className="font-black text-lg sm:text-xl">
                    {isCorrect ? feedbackMessage : 'Kurang tepat'}
                  </h3>
                  {!isCorrect && (
                    <p className="text-xs sm:text-sm font-semibold opacity-90">
                      {feedbackMessage}
                    </p>
                  )}
                </div>
              </div>

              <div className="w-full sm:w-auto">
                <TactileButton
                  variant={isCorrect ? 'primary' : 'danger'}
                  size="lg"
                  fullWidth
                  onClick={handleNext}
                  icon={<ArrowRight className="w-5 h-5" />}
                >
                  Lanjutkan
                </TactileButton>
              </div>
            </>
          ) : (
            <div className="w-full flex justify-end">
              <TactileButton
                variant="primary"
                size="lg"
                fullWidth
                disabled={!userAnswer.trim()}
                onClick={handleCheck}
              >
                Periksa
              </TactileButton>
            </div>
          )}
        </div>
      </div>

      {/* Exit Confirmation Dialog */}
      {showExitConfirm && (
        <div className="fixed inset-0 z-60 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
          <div className="bg-white rounded-3xl p-6 max-w-sm w-full text-center border-2 border-[#E5E5E5] shadow-2xl">
            <h3 className="text-xl font-black text-[#1B1C1C]">Yakin Ingin Keluar?</h3>
            <p className="text-sm text-[#777777] font-medium mt-1 mb-6">
              Kemajuan sesi ini tidak akan tersimpan jika kamu keluar sekarang.
            </p>
            <div className="space-y-2.5">
              <TactileButton variant="danger" size="md" fullWidth onClick={onClose}>
                Keluar Sekarang
              </TactileButton>
              <TactileButton
                variant="neutral"
                size="md"
                fullWidth
                onClick={() => setShowExitConfirm(false)}
              >
                Tetap Belajar
              </TactileButton>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
