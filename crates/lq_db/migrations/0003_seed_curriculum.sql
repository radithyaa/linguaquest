-- Seed kurikulum Bahasa Inggris -> Indonesia (sumber data awal untuk peta belajar).
-- Semua id memakai UUID tetap agar dapat direferensikan ulang oleh seed demo user.

INSERT INTO courses (id, from_lang, to_lang, title, status, version) VALUES
  ('00000000-0000-4000-8000-000000000001', 'en', 'id', 'Bahasa Inggris untuk Penutur Indonesia', 'published', 1);

INSERT INTO units (id, course_id, position, title, description, theme_color, guidebook_json) VALUES
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000001', 1,
   'Salam & Perkenalan',
   'Pelajari dasar menyapa, berkenalan, dan frasa penting sehari-hari.',
   '#58CC02',
   '{"summary":"Setiap percakapan dimulai dari sapaan. Di unit ini kamu belajar salam formal dan informal.","grammarTips":["\"Good morning\" dipakai sebelum pukul 12 siang.","\"Hello\" cocok untuk situasi santai maupun profesional.","\"How are you?\" adalah sapaan, bukan pertanyaan medis."]}'::jsonb),
  ('00000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-000000000001', 2,
   'Di Restoran & Kafe',
   'Memesan makanan, minuman, dan meminta tagihan.',
   '#1CB0F6',
   '{"summary":"Gunakan \"I would like\" untuk memesan dengan sopan.","grammarTips":["\"I''d like\" = \"I would like\", lebih sopan daripada \"I want\".","Gunakan \"Could I have...\" saat meminta sesuatu.","\"The bill, please\" cukup diucapkan di akhir makan."]}'::jsonb);

INSERT INTO nodes (id, unit_id, position, kind, title, description) VALUES
  ('00000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-000000000101', 1, 'lesson', 'Halo & Selamat Pagi', 'Belajar kosakata salam mendasar.'),
  ('00000000-0000-4000-8000-000000000202', '00000000-0000-4000-8000-000000000101', 2, 'lesson', 'Memperkenalkan Diri', 'Sebutkan nama dan asal usulmu.'),
  ('00000000-0000-4000-8000-000000000203', '00000000-0000-4000-8000-000000000101', 3, 'review', 'Review Unit 1', 'Uji kemampuanmu pada unit ini.'),
  ('00000000-0000-4000-8000-000000000204', '00000000-0000-4000-8000-000000000102', 1, 'lesson', 'Memesan Minuman', 'Pesan kopi, teh, atau air putih.');

INSERT INTO lessons (id, node_id, position) VALUES
  ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000201', 1),
  ('00000000-0000-4000-8000-000000000302', '00000000-0000-4000-8000-000000000202', 1),
  ('00000000-0000-4000-8000-000000000303', '00000000-0000-4000-8000-000000000203', 1),
  ('00000000-0000-4000-8000-000000000304', '00000000-0000-4000-8000-000000000204', 1);

INSERT INTO exercises
  (id, lesson_id, kind, position, prompt, instruction, translation, correct_answer, acceptable_answers, options, word_bank, pairs, explanation)
VALUES
  ('00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000301', 'multiple_choice', 1,
   'Hello', 'Pilih arti kata berikut:', 'Halo', 'Halo', '{}',
   ARRAY['Halo','Selamat tinggal','Terima kasih','Maaf'], '{}', '[]'::jsonb,
   '"Hello" adalah salam umum untuk menyapa seseorang.'),

  ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000301', 'word_bank', 2,
   'Good morning, friend', 'Susun terjemahan yang benar:', 'Selamat pagi teman', 'Selamat pagi teman', '{}',
   '{}', ARRAY['Selamat','pagi','teman','malam','guru','kamu'], '[]'::jsonb, NULL),

  ('00000000-0000-4000-8000-000000000403', '00000000-0000-4000-8000-000000000301', 'typing', 3,
   'Thank you very much', 'Ketik dalam Bahasa Indonesia:', 'Terima kasih banyak', 'Terima kasih banyak',
   ARRAY['Makasih banyak','Terima kasih'], '{}', '{}', '[]'::jsonb, NULL),

  ('00000000-0000-4000-8000-000000000404', '00000000-0000-4000-8000-000000000301', 'pair_matching', 4,
   'Cocokkan pasangan kata berikut', 'Pilih kata yang berpasangan:', NULL, 'Hello=Halo|Friend=Teman|Morning=Pagi|Thank you=Terima kasih', '{}',
   '{}', '{}',
   '[{"left":"Hello","right":"Halo"},{"left":"Friend","right":"Teman"},{"left":"Morning","right":"Pagi"},{"left":"Thank you","right":"Terima kasih"}]'::jsonb,
   NULL),

  ('00000000-0000-4000-8000-000000000405', '00000000-0000-4000-8000-000000000301', 'fill_in_the_blank', 5,
   'How ___ you?', 'Lengkapi kalimat sapaan berikut:', 'are', 'are', '{}',
   ARRAY['are','is','am','be'], '{}', '[]'::jsonb,
   'Untuk subjek "you" kata kerja bantu yang benar adalah "are".'),

  ('00000000-0000-4000-8000-000000000411', '00000000-0000-4000-8000-000000000302', 'multiple_choice', 1,
   'My name is Sarah', 'Pilih terjemahan yang tepat:', 'Nama saya Sarah', 'Nama saya Sarah', '{}',
   ARRAY['Nama saya Sarah','Dia adalah Sarah','Teman saya Sarah','Kamu kenal Sarah'], '{}', '[]'::jsonb, NULL),

  ('00000000-0000-4000-8000-000000000412', '00000000-0000-4000-8000-000000000302', 'typing', 2,
   'I am from Indonesia', 'Ketik dalam Bahasa Indonesia:', 'Saya dari Indonesia', 'Saya dari Indonesia',
   ARRAY['Aku dari Indonesia'], '{}', '{}', '[]'::jsonb, NULL),

  ('00000000-0000-4000-8000-000000000413', '00000000-0000-4000-8000-000000000302', 'word_bank', 3,
   'Nice to meet you', 'Susun terjemahan yang benar:', 'Senang bertemu denganmu', 'Senang bertemu denganmu', '{}',
   '{}', ARRAY['Senang','bertemu','denganmu','selamat','tinggal','pagi'], '[]'::jsonb, NULL),

  ('00000000-0000-4000-8000-000000000414', '00000000-0000-4000-8000-000000000302', 'speech', 4,
   'Nice to meet you', 'Ucapkan kalimat berikut dengan jelas:', NULL, 'Nice to meet you',
   ARRAY['Nice to meet you too'], '{}', '{}', '[]'::jsonb,
   'Latihan pelafalan: rekam suaramu lalu sistem menilai kemiripan transkripsi.'),

  ('00000000-0000-4000-8000-000000000421', '00000000-0000-4000-8000-000000000303', 'multiple_choice', 1,
   'Good night', 'Pilih arti kata berikut:', 'Selamat malam', 'Selamat malam', '{}',
   ARRAY['Selamat malam','Selamat pagi','Selamat siang','Selamat sore'], '{}', '[]'::jsonb, NULL),

  ('00000000-0000-4000-8000-000000000422', '00000000-0000-4000-8000-000000000303', 'typing', 2,
   'See you tomorrow', 'Ketik dalam Bahasa Indonesia:', 'Sampai jumpa besok', 'Sampai jumpa besok',
   ARRAY['Sampai besok'], '{}', '{}', '[]'::jsonb, NULL),

  ('00000000-0000-4000-8000-000000000431', '00000000-0000-4000-8000-000000000304', 'multiple_choice', 1,
   'Can I have a coffee, please?', 'Pilih terjemahan yang tepat:', 'Boleh saya pesan kopi?', 'Boleh saya pesan kopi?', '{}',
   ARRAY['Boleh saya pesan kopi?','Saya tidak suka kopi','Kopinya mahal sekali','Di mana kedai kopi?'], '{}', '[]'::jsonb, NULL),

  ('00000000-0000-4000-8000-000000000432', '00000000-0000-4000-8000-000000000304', 'word_bank', 2,
   'I would like some water', 'Susun terjemahan yang benar:', 'Saya ingin air putih', 'Saya ingin air putih', '{}',
   '{}', ARRAY['Saya','ingin','air','putih','makan','nasi'], '[]'::jsonb, NULL),

  ('00000000-0000-4000-8000-000000000433', '00000000-0000-4000-8000-000000000304', 'pair_matching', 3,
   'Cocokkan pasangan kata berikut', 'Pilih kata yang berpasangan:', NULL, 'Tea=Teh|Coffee=Kopi|Water=Air|Bill=Tagihan', '{}',
   '{}', '{}',
   '[{"left":"Tea","right":"Teh"},{"left":"Coffee","right":"Kopi"},{"left":"Water","right":"Air"},{"left":"Bill","right":"Tagihan"}]'::jsonb,
   NULL);
