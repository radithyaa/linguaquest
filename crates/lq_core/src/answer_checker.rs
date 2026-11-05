use unicode_normalization::UnicodeNormalization;

/// Calculate the Levenshtein distance between two strings
pub fn levenshtein_distance(a: &str, b: &str) -> usize {
    let a_chars: Vec<char> = a.chars().collect();
    let b_chars: Vec<char> = b.chars().collect();
    let m = a_chars.len();
    let n = b_chars.len();

    let mut dp = vec![vec![0; n + 1]; m + 1];

    for i in 0..=m {
        dp[i][0] = i;
    }
    for j in 0..=n {
        dp[0][j] = j;
    }

    for i in 1..=m {
        for j in 1..=n {
            let cost = if a_chars[i - 1] == b_chars[j - 1] { 0 } else { 1 };
            dp[i][j] = (dp[i - 1][j] + 1) // deletion
                .min(dp[i][j - 1] + 1) // insertion
                .min(dp[i - 1][j - 1] + cost); // substitution
        }
    }

    dp[m][n]
}

/// Normalize text: NFKD decomposition, lowercase, trim punctuation & whitespace
pub fn normalize_text(input: &str) -> String {
    input
        .nfkd()
        .filter(|c| !c.is_ascii_punctuation())
        .collect::<String>()
        .trim()
        .to_lowercase()
}

#[derive(Debug, PartialEq, Eq)]
pub enum EvaluationResult {
    Correct,
    TypoWarning(String), // Acceptable with typo (Levenshtein <= 2)
    Incorrect,
}

/// Evaluates if user answer is correct against canonical and acceptable alternatives
pub fn check_answer(
    user_input: &str,
    correct_answer: &str,
    acceptable_alternatives: &[String],
) -> EvaluationResult {
    let norm_input = normalize_text(user_input);
    let norm_correct = normalize_text(correct_answer);

    if norm_input == norm_correct {
        return EvaluationResult::Correct;
    }

    for alt in acceptable_alternatives {
        if norm_input == normalize_text(alt) {
            return EvaluationResult::Correct;
        }
    }

    // Check Levenshtein typo tolerance (distance <= 2 for strings with length >= 4)
    let dist = levenshtein_distance(&norm_input, &norm_correct);
    if dist > 0 && dist <= 2 && norm_correct.len() >= 4 {
        return EvaluationResult::TypoWarning(correct_answer.to_string());
    }

    EvaluationResult::Incorrect
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_levenshtein() {
        assert_eq!(levenshtein_distance("kitten", "sitting"), 3);
        assert_eq!(levenshtein_distance("apple", "aple"), 1);
        assert_eq!(levenshtein_distance("buku", "buku"), 0);
    }

    #[test]
    fn test_check_answer_exact_and_alternatives() {
        assert_eq!(
            check_answer("Good morning!", "Good morning", &[]),
            EvaluationResult::Correct
        );
        assert_eq!(
            check_answer("guten tag", "halo", &["guten tag".to_string()]),
            EvaluationResult::Correct
        );
    }

    #[test]
    fn test_check_answer_typo_tolerance() {
        match check_answer("tehcer", "teacher", &[]) {
            EvaluationResult::TypoWarning(canonical) => assert_eq!(canonical, "teacher"),
            _ => panic!("Expected TypoWarning"),
        }
        assert_eq!(check_answer("xyz", "teacher", &[]), EvaluationResult::Incorrect);
    }
}
