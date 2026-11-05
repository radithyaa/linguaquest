-- Migrasi inkremental: kunci jawaban klien untuk latihan word bank /
-- fill in the blank (dibandingkan di perangkat via engine lq_core).
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS translation TEXT NULL;

-- Backfill data lama: untuk latihan non-pair/non-speech, kunci jawaban
-- sama dengan `correct_answer` agar klien dapat menampilkan/menilai lokal.
UPDATE exercises
   SET translation = correct_answer
 WHERE translation IS NULL
   AND kind NOT IN ('pair_matching', 'speech');
