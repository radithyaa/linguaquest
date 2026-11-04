/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { AppProvider, useApp } from './context/AppContext';
import { AppLayout } from './components/layout/AppLayout';
import { LearnView } from './components/views/LearnView';
import { PracticeView } from './components/views/PracticeView';
import { QuestsView } from './components/views/QuestsView';
import { LeagueView } from './components/views/LeagueView';
import { ShopView } from './components/views/ShopView';
import { ProfileView } from './components/views/ProfileView';
import { LessonSession } from './components/lesson/LessonSession';
import { UnitGuidebookModal } from './components/ui/UnitGuidebookModal';
import { CourseSelectModal } from './components/ui/CourseSelectModal';
import { HeartDepletedModal } from './components/ui/HeartDepletedModal';
import { AdminCMSModal } from './components/admin/AdminCMSModal';

const MainAppContent: React.FC = () => {
  const {
    activeTab,
    activeLesson,
    closeLesson,
    activeGuidebookUnit,
    closeGuidebook,
    isCourseSelectOpen,
    setIsCourseSelectOpen,
    isHeartDepletedModalOpen,
    setIsHeartDepletedModalOpen,
    isAdminModalOpen,
    setIsAdminModalOpen
  } = useApp();

  // If a lesson is currently active, render the headless distraction-free lesson shell
  if (activeLesson) {
    return <LessonSession node={activeLesson} onClose={closeLesson} />;
  }

  return (
    <AppLayout>
      {activeTab === 'learn' && <LearnView />}
      {activeTab === 'practice' && <PracticeView />}
      {activeTab === 'quests' && <QuestsView />}
      {activeTab === 'league' && <LeagueView />}
      {activeTab === 'shop' && <ShopView />}
      {activeTab === 'profile' && <ProfileView />}

      {/* Global Modals */}
      <UnitGuidebookModal unit={activeGuidebookUnit} onClose={closeGuidebook} />
      <CourseSelectModal
        isOpen={isCourseSelectOpen}
        onClose={() => setIsCourseSelectOpen(false)}
      />
      <HeartDepletedModal
        isOpen={isHeartDepletedModalOpen}
        onClose={() => setIsHeartDepletedModalOpen(false)}
      />
      <AdminCMSModal
        isOpen={isAdminModalOpen}
        onClose={() => setIsAdminModalOpen(false)}
      />
    </AppLayout>
  );
};

export default function App() {
  return (
    <AppProvider>
      <MainAppContent />
    </AppProvider>
  );
}
