//! Seed kurikulum untuk backend in-memory.
//!
//! Isinya dijaga identik dengan `migrations/0003_seed_curriculum.sql`
//! (file SQL dipakai untuk PostgreSQL, file ini untuk mode demo).
//! Uji `tests::seed_has_expected_shape` memastikan jumlah baris tidak menyimpang.

use lq_types::{Exercise, ExerciseKind, MatchingPair};
use uuid::Uuid;

use crate::db::{CourseRow, DbState, LessonRow, NodeRow, UnitRow};

/// UUID tetap agar seed dapat diverifikasi dan direferensikan antar platform.
pub const COURSE_EN_ID: &str = "00000000-0000-4000-8000-000000000001";
pub const UNIT_1_ID: &str = "00000000-0000-4000-8000-000000000101";
pub const UNIT_2_ID: &str = "00000000-0000-4000-8000-000000000102";
pub const NODE_U1_1: &str = "00000000-0000-4000-8000-000000000201";
pub const NODE_U1_2: &str = "00000000-0000-4000-8000-000000000202";
pub const NODE_U1_3: &str = "00000000-0000-4000-8000-000000000203";
pub const NODE_U2_1: &str = "00000000-0000-4000-8000-000000000204";

pub const DEMO_USER_ID: &str = "00000000-0000-4000-8000-000000000901";

fn id(value: &str) -> Uuid {
    Uuid::parse_str(value).expect("uuid seed valid")
}

fn texts(items: &[&str]) -> Vec<String> {
    items.iter().map(|s| s.to_string()).collect()
}

struct Ex(Exercise);

impl Ex {
    fn new(id_str: &str, kind: ExerciseKind, position: i32, prompt: &str, instruction: &str) -> Self {
        Ex(Exercise {
            id: id(id_str),
            lesson_id: None,
            kind,
            position,
            prompt: prompt.to_string(),
            instruction: Some(instruction.to_string()),
            translation: None,
            audio_url: None,
            options: vec![],
            correct_answer: String::new(),
            acceptable_answers: vec![],
            word_bank: vec![],
            pairs: vec![],
            explanation: None,
        })
    }

    fn answer(mut self, answer: &str) -> Self {
        self.0.correct_answer = answer.to_string();
        self
    }

    fn options(mut self, options: &[&str]) -> Self {
        self.0.options = texts(options);
        self
    }

    fn alternatives(mut self, alternatives: &[&str]) -> Self {
        self.0.acceptable_answers = texts(alternatives);
        self
    }

    fn bank(mut self, bank: &[&str]) -> Self {
        self.0.word_bank = texts(bank);
        self
    }

    fn pairs(mut self, pairs: &[(&str, &str)]) -> Self {
        self.0.pairs = pairs
            .iter()
            .map(|(left, right)| MatchingPair {
                left: left.to_string(),
                right: right.to_string(),
            })
            .collect();
        self.0.correct_answer = self
            .0
            .pairs
            .iter()
            .map(|p| format!("{}={}", p.left, p.right))
            .collect::<Vec<_>>()
            .join("|");
        self
    }

    fn translation(mut self, translation: &str) -> Self {
        self.0.translation = Some(translation.to_string());
        self
    }

    fn explanation(mut self, explanation: &str) -> Self {
        self.0.explanation = Some(explanation.to_string());
        self
    }
}

fn mc(id_str: &str, position: i32, prompt: &str, answer: &str, options: &[&str]) -> Ex {
    Ex::new(id_str, ExerciseKind::MultipleChoice, position, prompt, "Pilih arti kata berikut:")
        .answer(answer)
        .options(options)
}

fn mc_translate(id_str: &str, position: i32, prompt: &str, answer: &str, options: &[&str]) -> Ex {
    Ex::new(id_str, ExerciseKind::MultipleChoice, position, prompt, "Pilih terjemahan yang tepat:")
        .answer(answer)
        .options(options)
}

fn typing(id_str: &str, position: i32, prompt: &str, answer: &str, alternatives: &[&str]) -> Ex {
    Ex::new(id_str, ExerciseKind::Typing, position, prompt, "Ketik dalam Bahasa Indonesia:")
        .answer(answer)
        .alternatives(alternatives)
}

fn word_bank(id_str: &str, position: i32, prompt: &str, answer: &str, bank: &[&str]) -> Ex {
    Ex::new(id_str, ExerciseKind::WordBank, position, prompt, "Susun terjemahan yang benar:")
        .answer(answer)
        .bank(bank)
}

fn pairs(id_str: &str, position: i32, prompt: &str, list: &[(&str, &str)]) -> Ex {
    Ex::new(id_str, ExerciseKind::PairMatching, position, prompt, "Pilih kata yang berpasangan:")
        .pairs(list)
}

fn fill_blank(id_str: &str, position: i32, prompt: &str, answer: &str, options: &[&str], explanation: &str) -> Ex {
    Ex::new(id_str, ExerciseKind::FillInTheBlank, position, prompt, "Lengkapi kalimat sapaan berikut:")
        .answer(answer)
        .options(options)
        .explanation(explanation)
}

fn speech(id_str: &str, position: i32, prompt: &str) -> Ex {
    Ex::new(id_str, ExerciseKind::Speech, position, prompt, "Ucapkan kalimat berikut dengan jelas:")
        .answer(prompt)
        .alternatives(&["Nice to meet you too"])
        .explanation("Latihan pelafalan: rekam suaramu lalu sistem menilai kemiripan transkripsi.")
}

pub fn seed_curriculum(state: &mut DbState) {
    state.courses.push(CourseRow {
        id: id(COURSE_EN_ID),
        from_lang: "en".into(),
        to_lang: "id".into(),
        title: "Bahasa Inggris untuk Penutur Indonesia".into(),
        version: 1,
    });

    state.units.extend([
        UnitRow {
            id: id(UNIT_1_ID),
            course_id: id(COURSE_EN_ID),
            position: 1,
            title: "Salam & Perkenalan".into(),
            description: "Pelajari dasar menyapa, berkenalan, dan frasa penting sehari-hari.".into(),
            theme_color: "#58CC02".into(),
            guidebook: serde_json::json!({
                "summary": "Setiap percakapan dimulai dari sapaan. Di unit ini kamu belajar salam formal dan informal.",
                "grammarTips": [
                    "\"Good morning\" dipakai sebelum pukul 12 siang.",
                    "\"Hello\" cocok untuk situasi santai maupun profesional.",
                    "\"How are you?\" adalah sapaan, bukan pertanyaan medis."
                ]
            }),
        },
        UnitRow {
            id: id(UNIT_2_ID),
            course_id: id(COURSE_EN_ID),
            position: 2,
            title: "Di Restoran & Kafe".into(),
            description: "Memesan makanan, minuman, dan meminta tagihan.".into(),
            theme_color: "#1CB0F6".into(),
            guidebook: serde_json::json!({
                "summary": "Gunakan \"I would like\" untuk memesan dengan sopan.",
                "grammarTips": [
                    "\"I'd like\" = \"I would like\", lebih sopan daripada \"I want\".",
                    "Gunakan \"Could I have...\" saat meminta sesuatu.",
                    "\"The bill, please\" cukup diucapkan di akhir makan."
                ]
            }),
        },
    ]);

    state.nodes.extend([
        NodeRow { id: id(NODE_U1_1), unit_id: id(UNIT_1_ID), position: 1, kind: "lesson".into(), title: "Halo & Selamat Pagi".into(), description: "Belajar kosakata salam mendasar.".into() },
        NodeRow { id: id(NODE_U1_2), unit_id: id(UNIT_1_ID), position: 2, kind: "lesson".into(), title: "Memperkenalkan Diri".into(), description: "Sebutkan nama dan asal usulmu.".into() },
        NodeRow { id: id(NODE_U1_3), unit_id: id(UNIT_1_ID), position: 3, kind: "review".into(), title: "Review Unit 1".into(), description: "Uji kemampuanmu pada unit ini.".into() },
        NodeRow { id: id(NODE_U2_1), unit_id: id(UNIT_2_ID), position: 1, kind: "lesson".into(), title: "Memesan Minuman".into(), description: "Pesan kopi, teh, atau air putih.".into() },
    ]);

    let lesson_1 = id("00000000-0000-4000-8000-000000000301");
    let lesson_2 = id("00000000-0000-4000-8000-000000000302");
    let lesson_3 = id("00000000-0000-4000-8000-000000000303");
    let lesson_4 = id("00000000-0000-4000-8000-000000000304");

    for (lesson_id, node_id) in [
        (lesson_1, NODE_U1_1),
        (lesson_2, NODE_U1_2),
        (lesson_3, NODE_U1_3),
        (lesson_4, NODE_U2_1),
    ] {
        state.lessons.push(LessonRow { id: lesson_id, node_id: id(node_id), position: 1 });
    }

    let unit_1 = [
        mc("00000000-0000-4000-8000-000000000401", 1, "Hello", "Halo", &["Halo", "Selamat tinggal", "Terima kasih", "Maaf"])
            .translation("Halo")
            .explanation("\"Hello\" adalah salam umum untuk menyapa seseorang."),
        word_bank("00000000-0000-4000-8000-000000000402", 2, "Good morning, friend", "Selamat pagi teman", &["Selamat", "pagi", "teman", "malam", "guru", "kamu"])
            .translation("Selamat pagi teman"),
        typing("00000000-0000-4000-8000-000000000403", 3, "Thank you very much", "Terima kasih banyak", &["Makasih banyak", "Terima kasih"])
            .translation("Terima kasih banyak"),
        pairs("00000000-0000-4000-8000-000000000404", 4, "Cocokkan pasangan kata berikut", &[("Hello", "Halo"), ("Friend", "Teman"), ("Morning", "Pagi"), ("Thank you", "Terima kasih")]),
        fill_blank("00000000-0000-4000-8000-000000000405", 5, "How ___ you?", "are", &["are", "is", "am", "be"], "Untuk subjek \"you\" kata kerja bantu yang benar adalah \"are\".")
            .translation("are"),
    ];
    let unit_1b = [
        mc_translate("00000000-0000-4000-8000-000000000411", 1, "My name is Sarah", "Nama saya Sarah", &["Nama saya Sarah", "Dia adalah Sarah", "Teman saya Sarah", "Kamu kenal Sarah"])
            .translation("Nama saya Sarah"),
        typing("00000000-0000-4000-8000-000000000412", 2, "I am from Indonesia", "Saya dari Indonesia", &["Aku dari Indonesia"])
            .translation("Saya dari Indonesia"),
        word_bank("00000000-0000-4000-8000-000000000413", 3, "Nice to meet you", "Senang bertemu denganmu", &["Senang", "bertemu", "denganmu", "selamat", "tinggal", "pagi"])
            .translation("Senang bertemu denganmu"),
        speech("00000000-0000-4000-8000-000000000414", 4, "Nice to meet you"),
    ];
    let unit_1c = [
        mc("00000000-0000-4000-8000-000000000421", 1, "Good night", "Selamat malam", &["Selamat malam", "Selamat pagi", "Selamat siang", "Selamat sore"])
            .translation("Selamat malam"),
        typing("00000000-0000-4000-8000-000000000422", 2, "See you tomorrow", "Sampai jumpa besok", &["Sampai besok"])
            .translation("Sampai jumpa besok"),
    ];
    let unit_2 = [
        mc_translate("00000000-0000-4000-8000-000000000431", 1, "Can I have a coffee, please?", "Boleh saya pesan kopi?", &["Boleh saya pesan kopi?", "Saya tidak suka kopi", "Kopinya mahal sekali", "Di mana kedai kopi?"])
            .translation("Boleh saya pesan kopi?"),
        word_bank("00000000-0000-4000-8000-000000000432", 2, "I would like some water", "Saya ingin air putih", &["Saya", "ingin", "air", "putih", "makan", "nasi"])
            .translation("Saya ingin air putih"),
        pairs("00000000-0000-4000-8000-000000000433", 3, "Cocokkan pasangan kata berikut", &[("Tea", "Teh"), ("Coffee", "Kopi"), ("Water", "Air"), ("Bill", "Tagihan")]),
    ];

    state.exercises.insert(lesson_1, attach(unit_1, lesson_1));
    state.exercises.insert(lesson_2, attach(unit_1b, lesson_2));
    state.exercises.insert(lesson_3, attach(unit_1c, lesson_3));
    state.exercises.insert(lesson_4, attach(unit_2, lesson_4));
}

fn attach<const N: usize>(list: [Ex; N], lesson_id: Uuid) -> Vec<Exercise> {
    list.into_iter()
        .map(|mut ex| {
            ex.0.lesson_id = Some(lesson_id);
            ex.0
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn seed_has_expected_shape() {
        let mut state = DbState::default();
        seed_curriculum(&mut state);
        assert_eq!(state.courses.len(), 1);
        assert_eq!(state.units.len(), 2);
        assert_eq!(state.nodes.len(), 4);
        assert_eq!(state.lessons.len(), 4);
        let total: usize = state.exercises.values().map(|v| v.len()).sum();
        assert_eq!(total, 14);
    }

    #[test]
    fn answer_key_sent_to_client_for_text_exercises() {
        let mut state = DbState::default();
        seed_curriculum(&mut state);
        for list in state.exercises.values() {
            for exercise in list {
                match exercise.kind {
                    ExerciseKind::PairMatching | ExerciseKind::Speech => {}
                    _ => assert!(
                        exercise.translation.is_some(),
                        "translation (kunci klien) wajib ada: {}",
                        exercise.id
                    ),
                }
            }
        }
    }

    #[test]
    fn every_exercise_has_valid_answer() {
        let mut state = DbState::default();
        seed_curriculum(&mut state);
        for list in state.exercises.values() {
            for exercise in list {
                assert!(!exercise.correct_answer.trim().is_empty(), "jawaban kosong: {}", exercise.id);
                assert_eq!(exercise.lesson_id.is_some(), true);
            }
        }
    }
}

#[cfg(test)]
mod dump {
    //! Utilitas verifikasi: mencetak seed Rust sebagai JSON agar dapat
    //! dibandingkan dengan hasil migrasi PostgreSQL (`scripts/verify_seeds.py`).
    use super::*;

    fn arr(items: &[String]) -> String {
        format!("{{{}}}", items.join(","))
    }

    fn pairs_json(pairs: &[MatchingPair]) -> String {
        let body: Vec<String> = pairs
            .iter()
            .map(|p| format!("{{\"left\": \"{}\", \"right\": \"{}\"}}", p.left, p.right))
            .collect();
        format!("[{}]", body.join(", "))
    }

    #[test]
    fn dump_seed_json() {
        let mut state = DbState::default();
        seed_curriculum(&mut state);
        let mut out = serde_json::Map::new();

        let mut courses: Vec<(String, Vec<String>)> = state
            .courses
            .iter()
            .map(|c| (c.id.to_string(), vec![c.id.to_string(), c.from_lang.clone(), c.to_lang.clone(), c.title.clone()]))
            .collect();
        courses.sort();
        out.insert("courses".into(), serde_json::json!(courses.into_iter().map(|(_, r)| r).collect::<Vec<_>>()));

        let mut units: Vec<(String, Vec<String>)> = state
            .units
            .iter()
            .map(|u| {
                (
                    u.id.to_string(),
                    vec![
                        u.id.to_string(),
                        u.course_id.to_string(),
                        u.position.to_string(),
                        u.title.clone(),
                        u.theme_color.clone(),
                    ],
                )
            })
            .collect();
        units.sort();
        out.insert("units".into(), serde_json::json!(units.into_iter().map(|(_, r)| r).collect::<Vec<_>>()));

        let mut nodes: Vec<(String, Vec<String>)> = state
            .nodes
            .iter()
            .map(|n| {
                (
                    n.id.to_string(),
                    vec![
                        n.id.to_string(),
                        n.unit_id.to_string(),
                        n.position.to_string(),
                        n.kind.clone(),
                        n.title.clone(),
                    ],
                )
            })
            .collect();
        nodes.sort();
        out.insert("nodes".into(), serde_json::json!(nodes.into_iter().map(|(_, r)| r).collect::<Vec<_>>()));

        let mut lessons: Vec<(String, Vec<String>)> = state
            .lessons
            .iter()
            .map(|l| {
                (
                    l.id.to_string(),
                    vec![l.id.to_string(), l.node_id.to_string(), l.position.to_string()],
                )
            })
            .collect();
        lessons.sort();
        out.insert("lessons".into(), serde_json::json!(lessons.into_iter().map(|(_, r)| r).collect::<Vec<_>>()));

        let mut exercises: Vec<(String, Vec<String>)> = Vec::new();
        for (lesson_id, list) in &state.exercises {
            for ex in list {
                let kind = serde_json::to_value(ex.kind).unwrap().as_str().unwrap().to_string();
                let pairs = pairs_json(&ex.pairs).replace(", \"", ", \"").replace("\": \"", "\": \"");
                exercises.push((
                    ex.id.to_string(),
                    vec![
                        ex.id.to_string(),
                        lesson_id.to_string(),
                        kind,
                        ex.position.to_string(),
                        ex.prompt.clone(),
                        ex.instruction.clone().unwrap_or_default(),
                        ex.translation.clone().unwrap_or_default(),
                        ex.correct_answer.clone(),
                        arr(&ex.acceptable_answers),
                        arr(&ex.options),
                        arr(&ex.word_bank),
                        pairs,
                        ex.explanation.clone().unwrap_or_default(),
                    ],
                ));
            }
        }
        exercises.sort();
        out.insert("exercises".into(), serde_json::json!(exercises.into_iter().map(|(_, r)| r).collect::<Vec<_>>()));

        println!("SEED_JSON:{}", serde_json::Value::Object(out));
    }
}
