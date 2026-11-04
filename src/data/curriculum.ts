import { Course } from '../types';

export const initialCourses: Course[] = [
  {
    id: 'en_id',
    title: 'Bahasa Inggris',
    fromLang: 'Bahasa Indonesia',
    toLang: 'English',
    flag: '🇺🇸',
    totalLearners: '4.2 Juta Pembelajar',
    units: [
      {
        id: 'unit_1',
        courseId: 'en_id',
        unitNumber: 1,
        title: 'Unit 1: Dasar Bahasa & Perkenalan',
        description: 'Menyapa orang lain, memesan kopi sederhana, dan mengenalkan diri.',
        color: '#58CC02',
        shadowColor: '#46A302',
        guidebook: {
          title: 'Panduan Unit 1: Dasar & Salam',
          unitNumber: 1,
          summary: 'Kuasai pola kalimat dasar Bahasa Inggris untuk salam, ungkapan terima kasih, dan pengenalan diri.',
          culturalNote: 'Di negara berbahasa Inggris seperti Amerika Serikat dan Inggris, menyapa dengan "Good morning" atau "How are you?" adalah bentuk kesopanan umum bahkan dengan orang yang belum dikenal.',
          keyPhrases: [
            {
              phrase: 'Good morning, how are you?',
              translation: 'Selamat pagi, apa kabar?',
              audioText: 'Good morning, how are you?',
              context: 'Salam standar yang ramah di pagi hari hingga pukul 12.00 siang.'
            },
            {
              phrase: 'Nice to meet you!',
              translation: 'Senang bertemu denganmu!',
              audioText: 'Nice to meet you!',
              context: 'Digunakan saat pertama kali diperkenalkan kepada seseorang.'
            },
            {
              phrase: 'I would like a coffee, please.',
              translation: 'Saya ingin secangkir kopi, tolong.',
              audioText: 'I would like a coffee, please.',
              context: 'Cara memesan minuman secara sopan di kafe atau restoran.'
            },
            {
              phrase: 'Thank you very much!',
              translation: 'Terima kasih banyak!',
              audioText: 'Thank you very much!',
              context: 'Menunjukkan rasa terima kasih yang hangat.'
            }
          ],
          grammarTips: [
            {
              title: 'Subjek & To Be (Am / Is / Are)',
              explanation: 'Dalam Bahasa Inggris, kata kerja bantu (to be) wajib disesuaikan dengan subjek kalimat.',
              examples: [
                { source: 'I am a student.', translation: 'Saya adalah seorang siswa.' },
                { source: 'She is my teacher.', translation: 'Dia adalah guru saya.' },
                { source: 'They are very friendly.', translation: 'Mereka sangat ramah.' }
              ]
            },
            {
              title: 'Artikel "A" vs "An"',
              explanation: 'Gunakan "a" sebelum kata yang berawalan bunyi konsonan (a book, a cat), dan gunakan "an" sebelum bunyi vokal (an apple, an hour).',
              examples: [
                { source: 'I have an apple.', translation: 'Saya mempunyai sebuah apel.' },
                { source: 'This is a cup of coffee.', translation: 'Ini adalah secangkir kopi.' }
              ]
            }
          ]
        },
        nodes: [
          {
            id: 'node_1_1',
            unitId: 'unit_1',
            position: 1,
            kind: 'lesson',
            status: 'mastered',
            title: 'Salam & Sapaan',
            subtitle: 'Halo, Selamat Pagi, Sampai Jumpa',
            iconName: 'hand',
            rewardXp: 15,
            rewardGems: 10,
            totalExercises: 5,
            exercises: [
              {
                id: 'ex_1_1_1',
                lessonId: 'node_1_1',
                kind: 'multiple_choice',
                position: 1,
                prompt: 'Pilihlah terjemahan yang benar untuk "Halo":',
                correctAnswer: 'Hello',
                options: [
                  { id: 'opt_1', text: 'Hello', translation: 'Halo' },
                  { id: 'opt_2', text: 'Goodbye', translation: 'Selamat tinggal' },
                  { id: 'opt_3', text: 'Water', translation: 'Air' },
                  { id: 'opt_4', text: 'Night', translation: 'Malam' }
                ],
                audioPhrase: 'Hello'
              },
              {
                id: 'ex_1_1_2',
                lessonId: 'node_1_1',
                kind: 'word_bank',
                position: 2,
                prompt: 'Susun kalimat terjemahan untuk:',
                targetSentence: 'Selamat pagi, apa kabar?',
                correctAnswer: 'Good morning, how are you?',
                wordBank: ['how', 'Good', 'you?', 'are', 'morning,', 'coffee', 'night', 'water'],
                audioPhrase: 'Good morning, how are you?'
              },
              {
                id: 'ex_1_1_3',
                lessonId: 'node_1_1',
                kind: 'pair_matching',
                position: 3,
                prompt: 'Cocokkan pasangan kata berikut:',
                correctAnswer: 'all_paired',
                pairs: [
                  { id: 'p1', source: 'Halo', target: 'Hello' },
                  { id: 'p2', source: 'Terima kasih', target: 'Thank you' },
                  { id: 'p3', source: 'Pagi', target: 'Morning' },
                  { id: 'p4', source: 'Selamat tinggal', target: 'Goodbye' },
                  { id: 'p5', source: 'Tolong', target: 'Please' }
                ]
              },
              {
                id: 'ex_1_1_4',
                lessonId: 'node_1_1',
                kind: 'audio_listening',
                position: 4,
                prompt: 'Dengarkan audio dan ketik apa yang Anda dengar:',
                targetSentence: 'Tekan tombol speaker untuk mendengar',
                correctAnswer: 'Thank you very much',
                audioPhrase: 'Thank you very much',
                hint: 'Ucapan terima kasih yang tulus.'
              },
              {
                id: 'ex_1_1_5',
                lessonId: 'node_1_1',
                kind: 'typing_translation',
                position: 5,
                prompt: 'Ketik dalam Bahasa Inggris:',
                targetSentence: 'Sampai jumpa besok',
                correctAnswer: 'See you tomorrow',
                hint: 'Kata "see" berarti melihat atau menjumpai.'
              }
            ]
          },
          {
            id: 'node_1_2',
            unitId: 'unit_1',
            position: 2,
            kind: 'lesson',
            status: 'mastered',
            title: 'Kopi & Kafe',
            subtitle: 'Memesan minuman & makanan ringan',
            iconName: 'coffee',
            rewardXp: 15,
            rewardGems: 10,
            totalExercises: 5,
            exercises: [
              {
                id: 'ex_1_2_1',
                lessonId: 'node_1_2',
                kind: 'multiple_choice',
                position: 1,
                prompt: 'Bagaimana cara mengatakan "Kopi dengan susu"?',
                correctAnswer: 'Coffee with milk',
                options: [
                  { id: 'o1', text: 'Coffee with milk', translation: 'Kopi dengan susu' },
                  { id: 'o2', text: 'Tea without sugar', translation: 'Teh tanpa gula' },
                  { id: 'o3', text: 'Water and bread', translation: 'Air dan roti' },
                  { id: 'o4', text: 'Cold juice', translation: 'Jus dingin' }
                ],
                audioPhrase: 'Coffee with milk'
              },
              {
                id: 'ex_1_2_2',
                lessonId: 'node_1_2',
                kind: 'fill_in_the_blank',
                position: 2,
                prompt: 'Lengkapi bagian kalimat yang kosong:',
                blankSentence: 'A cup of ___ , please.',
                correctAnswer: 'coffee',
                options: [
                  { id: 'b1', text: 'coffee' },
                  { id: 'b2', text: 'morning' },
                  { id: 'b3', text: 'see' },
                  { id: 'b4', text: 'happy' }
                ],
                hint: 'Minuman hitam berkafein.',
                audioPhrase: 'A cup of coffee, please.'
              },
              {
                id: 'ex_1_2_3',
                lessonId: 'node_1_2',
                kind: 'word_bank',
                position: 3,
                prompt: 'Susun kata menjadi terjemahan yang tepat:',
                targetSentence: 'Saya ingin teh hangat, tolong.',
                correctAnswer: 'I would like hot tea, please.',
                wordBank: ['would', 'I', 'tea,', 'hot', 'like', 'please.', 'coffee', 'ice'],
                audioPhrase: 'I would like hot tea, please.'
              },
              {
                id: 'ex_1_2_4',
                lessonId: 'node_1_2',
                kind: 'typing_translation',
                position: 4,
                prompt: 'Terjemahkan kalimat ini ke Bahasa Inggris:',
                targetSentence: 'Secangkir kopi panas',
                correctAnswer: 'A hot cup of coffee',
                hint: 'Gunakan kata hot dan coffee'
              },
              {
                id: 'ex_1_2_5',
                lessonId: 'node_1_2',
                kind: 'pair_matching',
                position: 5,
                prompt: 'Pasangkan kata-kata kafe ini:',
                correctAnswer: 'all_paired',
                pairs: [
                  { id: 'c1', source: 'Susu', target: 'Milk' },
                  { id: 'c2', source: 'Gula', target: 'Sugar' },
                  { id: 'c3', source: 'Cangkir', target: 'Cup' },
                  { id: 'c4', source: 'Hangat', target: 'Hot' },
                  { id: 'c5', source: 'Dingin', target: 'Cold' }
                ]
              }
            ]
          },
          {
            id: 'node_1_3',
            unitId: 'unit_1',
            position: 3,
            kind: 'story',
            status: 'unlocked', // Current active node!
            title: 'Cerita: Pagi di Kafe',
            subtitle: 'Dengarkan percakapan seru antara Sarah dan barista!',
            iconName: 'book',
            rewardXp: 20,
            rewardGems: 15,
            totalExercises: 4,
            exercises: [
              {
                id: 'ex_1_3_1',
                lessonId: 'node_1_3',
                kind: 'interactive_story',
                position: 1,
                prompt: 'Ikuti alur percakapan cerita pendek berikut:',
                correctAnswer: 'Sarah memesan kopi dan roti',
                storySteps: [
                  {
                    speaker: 'Barista (Leo)',
                    speakerAvatar: '☕',
                    text: 'Good morning! Welcome to Central Cafe. What can I get for you today?',
                    translation: 'Selamat pagi! Selamat datang di Central Cafe. Mau pesan apa hari ini?',
                    audioText: 'Good morning! Welcome to Central Cafe. What can I get for you today?'
                  },
                  {
                    speaker: 'Sarah',
                    speakerAvatar: '👩',
                    text: 'Hello! I would like a large cappuccino with oat milk, please.',
                    translation: 'Halo! Saya ingin segelas cappuccino besar dengan susu oat, tolong.',
                    audioText: 'Hello! I would like a large cappuccino with oat milk, please.'
                  },
                  {
                    speaker: 'Barista (Leo)',
                    speakerAvatar: '☕',
                    text: 'Sure thing! Would you like a warm croissant with that?',
                    translation: 'Tentu saja! Apakah Anda ingin croissant hangat juga?',
                    audioText: 'Sure thing! Would you like a warm croissant with that?'
                  },
                  {
                    speaker: 'Sarah',
                    speakerAvatar: '👩',
                    text: 'Yes, please! That sounds delicious.',
                    translation: 'Ya, tolong! Kedengarannya lezat.',
                    audioText: 'Yes, please! That sounds delicious.'
                  }
                ],
                options: [
                  { id: 's1', text: 'Sarah memesan cappuccino dan croissant' },
                  { id: 's2', text: 'Sarah mencari stasiun kereta' },
                  { id: 's3', text: 'Sarah menolak minuman dingin' },
                  { id: 's4', text: 'Leo menyuruh Sarah pergi' }
                ]
              },
              {
                id: 'ex_1_3_2',
                lessonId: 'node_1_3',
                kind: 'multiple_choice',
                position: 2,
                prompt: 'Susu apa yang dipesan oleh Sarah?',
                correctAnswer: 'Susu oat (Oat milk)',
                options: [
                  { id: 'm1', text: 'Susu oat (Oat milk)' },
                  { id: 'm2', text: 'Susu sapi biasa' },
                  { id: 'm3', text: 'Susu kedelai' },
                  { id: 'm4', text: 'Tanpa susu sama sekali' }
                ],
                audioPhrase: 'Oat milk'
              },
              {
                id: 'ex_1_3_3',
                lessonId: 'node_1_3',
                kind: 'word_bank',
                position: 3,
                prompt: 'Susun kembali kalimat ramah barista:',
                targetSentence: 'Selamat pagi! Mau pesan apa hari ini?',
                correctAnswer: 'Good morning! What can I get for you?',
                wordBank: ['Good', 'morning!', 'What', 'get', 'can', 'for', 'I', 'you?', 'tea', 'apple'],
                audioPhrase: 'Good morning! What can I get for you?'
              },
              {
                id: 'ex_1_3_4',
                lessonId: 'node_1_3',
                kind: 'typing_translation',
                position: 4,
                prompt: 'Ketik dalam Bahasa Inggris dengan sopan:',
                targetSentence: 'Itu kedengarannya lezat!',
                correctAnswer: 'That sounds delicious',
                hint: 'Gunakan kata "sounds" dan "delicious".'
              }
            ]
          },
          {
            id: 'node_1_chest',
            unitId: 'unit_1',
            position: 4,
            kind: 'chest',
            status: 'unlocked',
            title: 'Peti Harta Karun!',
            subtitle: 'Klaim 25 Gems bonus!',
            iconName: 'chest',
            rewardXp: 0,
            rewardGems: 25,
            totalExercises: 0,
            exercises: [],
            chestClaimed: false
          },
          {
            id: 'node_1_4',
            unitId: 'unit_1',
            position: 5,
            kind: 'lesson',
            status: 'locked',
            title: 'Perkenalan Diri',
            subtitle: 'Nama, profesi, dan asal negara',
            iconName: 'user',
            rewardXp: 15,
            rewardGems: 10,
            totalExercises: 4,
            exercises: [
              {
                id: 'ex_1_4_1',
                lessonId: 'node_1_4',
                kind: 'multiple_choice',
                position: 1,
                prompt: 'Bagaimana cara memperkenalkan diri "Nama saya Budi"?',
                correctAnswer: 'My name is Budi',
                options: [
                  { id: 'nm1', text: 'My name is Budi' },
                  { id: 'nm2', text: 'I am book Budi' },
                  { id: 'nm3', text: 'Where is Budi' },
                  { id: 'nm4', text: 'Your name Budi' }
                ],
                audioPhrase: 'My name is Budi'
              }
            ]
          },
          {
            id: 'node_1_5',
            unitId: 'unit_1',
            position: 6,
            kind: 'checkpoint',
            status: 'locked',
            title: 'Evaluasi Unit 1 (Checkpoint)',
            subtitle: 'Uji kemampuan seluruh materi Unit 1 untuk membuka Unit 2',
            iconName: 'trophy',
            rewardXp: 30,
            rewardGems: 20,
            totalExercises: 5,
            exercises: []
          }
        ]
      },
      {
        id: 'unit_2',
        courseId: 'en_id',
        unitNumber: 2,
        title: 'Unit 2: Frasa Sehari-hari & Makanan',
        description: 'Membicarakan hobi, menanyakan arah jalan, dan belanja di supermarket.',
        color: '#1CB0F6',
        shadowColor: '#1899D6',
        guidebook: {
          title: 'Panduan Unit 2: Menanyakan Arah & Belanja',
          unitNumber: 2,
          summary: 'Pelajari kata tanya (Where, How much, Can I) dan kosakata tempat umum.',
          culturalNote: 'Ketika meminta bantuan di jalan, selalu awali dengan "Excuse me, could you help me?" sebelum mengajukan pertanyaan.',
          keyPhrases: [
            {
              phrase: 'Excuse me, where is the train station?',
              translation: 'Permisi, di mana stasiun kereta?',
              audioText: 'Excuse me, where is the train station?',
              context: 'Menanyakan lokasi fasilitas umum.'
            },
            {
              phrase: 'How much does this cost?',
              translation: 'Berapa harga barang ini?',
              audioText: 'How much does this cost?',
              context: 'Menanyakan harga saat berbelanja.'
            }
          ],
          grammarTips: [
            {
              title: 'Kata Tanya: Where, What, How Much',
              explanation: 'Gunakan Where untuk menanyakan tempat, What untuk benda, dan How Much untuk harga atau jumlah barang yang tidak dapat dihitung.',
              examples: [
                { source: 'Where is the library?', translation: 'Di mana perpustakaan?' },
                { source: 'How much is the ticket?', translation: 'Berapa harga tiketnya?' }
              ]
            }
          ]
        },
        nodes: [
          {
            id: 'node_2_1',
            unitId: 'unit_2',
            position: 1,
            kind: 'lesson',
            status: 'locked',
            title: 'Arah & Navigasi',
            subtitle: 'Kiri, Kanan, Lurus, Stasiun',
            iconName: 'compass',
            rewardXp: 15,
            rewardGems: 10,
            totalExercises: 4,
            exercises: []
          },
          {
            id: 'node_2_2',
            unitId: 'unit_2',
            position: 2,
            kind: 'lesson',
            status: 'locked',
            title: 'Di Supermarket',
            subtitle: 'Buah-buahan, sayur, dan pembayaran',
            iconName: 'cart',
            rewardXp: 15,
            rewardGems: 10,
            totalExercises: 4,
            exercises: []
          }
        ]
      },
      {
        id: 'unit_3',
        courseId: 'en_id',
        unitNumber: 3,
        title: 'Unit 3: Di Restoran & Perjalanan',
        description: 'Reservasi meja, memesan menu utama, dan check-in hotel.',
        color: '#FF9600',
        shadowColor: '#D97F00',
        guidebook: {
          title: 'Panduan Unit 3: Hotel & Restoran',
          unitNumber: 3,
          summary: 'Frasa tingkat menengah untuk perjalanan internasional dan pengalaman kuliner.',
          keyPhrases: [],
          grammarTips: []
        },
        nodes: [
          {
            id: 'node_3_1',
            unitId: 'unit_3',
            position: 1,
            kind: 'lesson',
            status: 'locked',
            title: 'Check-in Hotel',
            subtitle: 'Kamar, kunci, dan waktu sarapan',
            iconName: 'hotel',
            rewardXp: 20,
            rewardGems: 15,
            totalExercises: 4,
            exercises: []
          }
        ]
      }
    ]
  },
  {
    id: 'ja_id',
    title: 'Bahasa Jepang',
    fromLang: 'Bahasa Indonesia',
    toLang: 'Japanese',
    flag: '🇯🇵',
    totalLearners: '1.8 Juta Pembelajar',
    units: [
      {
        id: 'unit_ja_1',
        courseId: 'ja_id',
        unitNumber: 1,
        title: 'Unit 1: Hiragana & Salam Dasar',
        description: 'Belajar mengucapkan Konnichiwa, Arigatou, dan karakter dasar.',
        color: '#58CC02',
        shadowColor: '#46A302',
        guidebook: {
          title: 'Panduan Unit 1: Hiragana & Etika Salam Jepang',
          unitNumber: 1,
          summary: 'Pengenalan sistem penulisan Hiragana dan salam sopan.',
          keyPhrases: [
            {
              phrase: 'Konnichiwa (こんにちは)',
              translation: 'Halo / Selamat Siang',
              audioText: 'こんにちは',
              context: 'Salam umum di siang hari.'
            },
            {
              phrase: 'Arigatou gozaimasu (ありがとうございます)',
              translation: 'Terima kasih banyak (formal)',
              audioText: 'ありがとうございます',
              context: 'Ungkapan terima kasih yang sopan kepada siapapun.'
            }
          ],
          grammarTips: [
            {
              title: 'Partikel "Wa" (は)',
              explanation: 'Partikel "wa" ditulis dengan huruf hiragana "ha" namun dibaca "wa", berfungsi sebagai penanda topik kalimat.',
              examples: [
                { source: 'Watashi wa gakusei desu.', translation: 'Saya adalah seorang pelajar.' }
              ]
            }
          ]
        },
        nodes: [
          {
            id: 'node_ja_1_1',
            unitId: 'unit_ja_1',
            position: 1,
            kind: 'lesson',
            status: 'unlocked',
            title: 'Salam Dasar Jepang',
            subtitle: 'Konnichiwa, Ohayou, Sayounara',
            iconName: 'hand',
            rewardXp: 15,
            rewardGems: 10,
            totalExercises: 3,
            exercises: [
              {
                id: 'ex_ja_1',
                lessonId: 'node_ja_1_1',
                kind: 'multiple_choice',
                position: 1,
                prompt: 'Bagaimana cara mengucapkan "Terima kasih banyak" secara sopan dalam Bahasa Jepang?',
                correctAnswer: 'Arigatou gozaimasu (ありがとうございます)',
                options: [
                  { id: 'j1', text: 'Arigatou gozaimasu (ありがとうございます)' },
                  { id: 'j2', text: 'Sayounara (さようなら)' },
                  { id: 'j3', text: 'Konnichiwa (こんにちは)' },
                  { id: 'j4', text: 'Gomen nasai (ごめんなさい)' }
                ],
                audioPhrase: 'ありがとうございます'
              },
              {
                id: 'ex_ja_2',
                lessonId: 'node_ja_1_1',
                kind: 'pair_matching',
                position: 2,
                prompt: 'Cocokkan kata Jepang dengan artinya:',
                correctAnswer: 'all_paired',
                pairs: [
                  { id: 'jp1', source: 'Konnichiwa', target: 'Halo' },
                  { id: 'jp2', source: 'Ohayou', target: 'Selamat pagi' },
                  { id: 'jp3', source: 'Mizu', target: 'Air' },
                  { id: 'jp4', source: 'Neko', target: 'Kucing' },
                  { id: 'jp5', source: 'Hai', target: 'Ya' }
                ]
              },
              {
                id: 'ex_ja_3',
                lessonId: 'node_ja_1_1',
                kind: 'word_bank',
                position: 3,
                prompt: 'Susun kalimat bahasa Jepang:',
                targetSentence: 'Saya adalah seorang pelajar.',
                correctAnswer: 'Watashi wa gakusei desu',
                wordBank: ['Watashi', 'wa', 'gakusei', 'desu', 'neko', 'mizu', 'arigatou'],
                audioPhrase: 'Watashi wa gakusei desu'
              }
            ]
          }
        ]
      }
    ]
  },
  {
    id: 'es_id',
    title: 'Bahasa Spanyol',
    fromLang: 'Bahasa Indonesia',
    toLang: 'Español',
    flag: '🇪🇸',
    totalLearners: '950 Ribu Pembelajar',
    units: [
      {
        id: 'unit_es_1',
        courseId: 'es_id',
        unitNumber: 1,
        title: 'Unit 1: ¡Hola! Perkenalan Spanyol',
        description: 'Menyapa dalam bahasa Spanyol dan memesan tapas.',
        color: '#58CC02',
        shadowColor: '#46A302',
        guidebook: {
          title: 'Panduan Unit 1: Dasar Bahasa Spanyol',
          unitNumber: 1,
          summary: 'Dasar sapaan ¡Hola!, Buenos días, dan kata ganti.',
          keyPhrases: [
            {
              phrase: '¡Hola! ¿Cómo estás?',
              translation: 'Halo! Apa kabar?',
              audioText: 'Hola, ¿cómo estás?',
              context: 'Salam ramah santai sehari-hari.'
            }
          ],
          grammarTips: [
            {
              title: 'Gender Kata Benda (Masculino & Femenino)',
              explanation: 'Kebanyakan kata yang berakhiran -o bersifat maskulin (el café, el libro), dan kata berakhiran -a bersifat feminin (la mesa, la casa).',
              examples: [
                { source: 'El libro', translation: 'Buku itu' },
                { source: 'La casa', translation: 'Rumah itu' }
              ]
            }
          ]
        },
        nodes: [
          {
            id: 'node_es_1_1',
            unitId: 'unit_es_1',
            position: 1,
            kind: 'lesson',
            status: 'unlocked',
            title: 'Sapaan Spanyol',
            subtitle: 'Hola, Buenos días, Gracias',
            iconName: 'hand',
            rewardXp: 15,
            rewardGems: 10,
            totalExercises: 2,
            exercises: [
              {
                id: 'ex_es_1',
                lessonId: 'node_es_1_1',
                kind: 'multiple_choice',
                position: 1,
                prompt: 'Bagaimana cara mengucapkan "Selamat pagi" dalam Bahasa Spanyol?',
                correctAnswer: 'Buenos días',
                options: [
                  { id: 'es1', text: 'Buenos días' },
                  { id: 'es2', text: 'Buenas noches' },
                  { id: 'es3', text: 'Por favor' },
                  { id: 'es4', text: 'Adiós' }
                ],
                audioPhrase: 'Buenos días'
              },
              {
                id: 'ex_es_2',
                lessonId: 'node_es_1_1',
                kind: 'pair_matching',
                position: 2,
                prompt: 'Cocokkan kata Spanyol dengan artinya:',
                correctAnswer: 'all_paired',
                pairs: [
                  { id: 'sp1', source: 'Hola', target: 'Halo' },
                  { id: 'sp2', source: 'Gracias', target: 'Terima kasih' },
                  { id: 'sp3', source: 'Agua', target: 'Air' },
                  { id: 'sp4', source: 'Amigo', target: 'Teman' },
                  { id: 'sp5', source: 'Sí', target: 'Ya' }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
];
