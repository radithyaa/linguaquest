import React from 'react';
import { X, Check, Globe } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { TactileButton } from './TactileButton';

interface CourseSelectModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const CourseSelectModal: React.FC<CourseSelectModalProps> = ({ isOpen, onClose }) => {
  const { courses, currentCourseId, switchCourse } = useApp();

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
      <div className="relative w-full max-w-md bg-white rounded-3xl border-2 border-[#E5E5E5] shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-5 border-b border-[#E5E5E5] flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <Globe className="w-6 h-6 text-[#1CB0F6]" />
            <h2 className="text-xl font-black text-[#1B1C1C]">Pilih Kursus Bahasa</h2>
          </div>
          <button
            onClick={onClose}
            className="w-9 h-9 rounded-full hover:bg-[#F7F9FA] text-[#777777] flex items-center justify-center transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Course List */}
        <div className="p-5 space-y-3">
          {courses.map((course) => {
            const isSelected = course.id === currentCourseId;
            return (
              <button
                key={course.id}
                onClick={() => switchCourse(course.id)}
                className={`w-full p-4 rounded-2xl border-2 flex items-center justify-between text-left transition-all cursor-pointer ${
                  isSelected
                    ? 'border-[#58CC02] bg-[#F4FBEA] shadow-[0_3px_0_0_#58CC02]'
                    : 'border-[#E5E5E5] bg-white hover:border-[#1CB0F6] hover:bg-[#F0F9FF]'
                }`}
              >
                <div className="flex items-center gap-3.5">
                  <span className="text-3xl leading-none">{course.flag}</span>
                  <div>
                    <h3 className="font-extrabold text-base text-[#1B1C1C]">{course.title}</h3>
                    <p className="text-xs text-[#777777] font-medium">
                      Untuk penutur {course.fromLang} • {course.totalLearners}
                    </p>
                  </div>
                </div>
                {isSelected && (
                  <div className="w-7 h-7 rounded-full bg-[#58CC02] text-white flex items-center justify-center">
                    <Check className="w-4 h-4 stroke-[3]" />
                  </div>
                )}
              </button>
            );
          })}
        </div>

        {/* Footer */}
        <div className="p-4 bg-[#F7F9FA] border-t border-[#E5E5E5] flex justify-end">
          <TactileButton variant="neutral" size="sm" onClick={onClose}>
            Tutup
          </TactileButton>
        </div>
      </div>
    </div>
  );
};
