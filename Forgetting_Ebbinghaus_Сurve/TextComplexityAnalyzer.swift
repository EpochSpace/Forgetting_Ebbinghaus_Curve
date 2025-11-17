//
//  TextComplexityAnalyzer.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 17.11.2025.
//

import Foundation

/// Analyzes text to determine appropriate learning category based on length and complexity
struct TextComplexityAnalyzer {

    // MARK: - Thresholds

    /// Character count thresholds for base categorization
    private static let shortThreshold = 150
    private static let mediumThreshold = 400

    /// Complexity score thresholds that can bump category up
    private static let lowComplexityThreshold = 0.15    // 15% complex content
    private static let highComplexityThreshold = 0.30   // 30% complex content

    // MARK: - Regex Patterns

    /// Regex for detecting numbers and percentages
    private static let numberPattern: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\d+\\.?\\d*%?", options: [])
    }()

    /// Regex for detecting acronyms (2+ consecutive uppercase letters)
    private static let acronymPattern: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\b[A-Z]{2,}\\b", options: [])
    }()

    // MARK: - Analysis Result

    struct AnalysisResult {
        let category: TextCategory
        let characterCount: Int
        let complexityScore: Double
        let hasFormulas: Bool
        let hasTechnicalTerms: Bool

        var detailDescription: String {
            var details: [String] = []
            details.append("\(characterCount) characters")
            if complexityScore > 0 {
                details.append(String(format: "%.0f%% complex", complexityScore * 100))
            }
            if hasFormulas {
                details.append("formulas detected")
            }
            if hasTechnicalTerms {
                details.append("technical terms")
            }
            return details.joined(separator: ", ")
        }
    }

    // MARK: - Public API

    /// Analyzes text and returns the recommended category with analysis details
    static func analyze(_ text: String) -> AnalysisResult {
        let charCount = text.count
        let complexityScore = calculateComplexity(text)
        let hasFormulas = detectFormulas(text)
        let hasTechnicalTerms = detectTechnicalTerms(text)

        // Determine base category from character count
        var category: TextCategory
        if charCount < shortThreshold {
            category = .short
        } else if charCount < mediumThreshold {
            category = .medium
        } else {
            category = .long
        }

        // Complexity can bump category up by one level
        if complexityScore >= highComplexityThreshold {
            // High complexity: bump up one category
            if category == .short {
                category = .medium
            } else if category == .medium {
                category = .long
            }
        } else if complexityScore >= lowComplexityThreshold {
            // Moderate complexity: bump up only for short texts
            if category == .short && charCount > shortThreshold / 2 {
                category = .medium
            }
        }

        return AnalysisResult(
            category: category,
            characterCount: charCount,
            complexityScore: complexityScore,
            hasFormulas: hasFormulas,
            hasTechnicalTerms: hasTechnicalTerms
        )
    }

    // MARK: - Complexity Detection

    /// Calculate overall complexity score (0.0 to 1.0)
    private static func calculateComplexity(_ text: String) -> Double {
        guard !text.isEmpty else { return 0.0 }

        var complexityFactors = 0.0
        let totalChars = Double(text.count)

        // 1. Mathematical symbols and formulas
        let mathSymbols = CharacterSet(charactersIn: "+-*/=∑∏∫√∂∞≈≠≤≥±×÷^")
        let mathCount = text.unicodeScalars.filter { mathSymbols.contains($0) }.count
        complexityFactors += Double(mathCount) * 3.0 // Weight formulas heavily

        // 2. Numbers and percentages
        let numberMatches = Self.numberPattern?.numberOfMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ) ?? 0
        complexityFactors += Double(numberMatches) * 1.5

        // 3. Special/scientific characters
        let specialChars = CharacterSet.punctuationCharacters
            .union(CharacterSet.symbols)
            .subtracting(CharacterSet(charactersIn: ".,!?;:"))
        let specialCount = text.unicodeScalars.filter { specialChars.contains($0) }.count
        complexityFactors += Double(specialCount) * 2.0

        // 4. Capital letter density (indicates acronyms, proper nouns, technical terms)
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count > 0 {
            let capitalizedWords = words.filter { word in
                word.first?.isUppercase == true && word.count > 1
            }
            complexityFactors += Double(capitalizedWords.count) * 1.0
        }

        // 5. Parentheses and brackets (often indicate formulas or technical notation)
        let bracketCount = text.filter { "()[]{}".contains($0) }.count
        complexityFactors += Double(bracketCount) * 1.5

        // Normalize to 0.0-1.0 range (cap at 1.0)
        return min(complexityFactors / totalChars, 1.0)
    }

    /// Detect if text contains mathematical formulas
    private static func detectFormulas(_ text: String) -> Bool {
        // Look for mathematical patterns
        let formulaIndicators = [
            "=",           // Equations
            "∑", "∏", "∫", // Mathematical operators
            "√", "∂",      // Advanced math symbols
            "\\^",         // Exponents
            "≈", "≠", "≤", "≥" // Comparison operators
        ]

        return formulaIndicators.contains { text.contains($0) }
    }

    /// Detect if text contains technical terminology
    private static func detectTechnicalTerms(_ text: String) -> Bool {
        // Look for patterns indicating technical content

        // 1. Multiple consecutive capitalized words (technical terms, proper nouns)
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var consecutiveCapitalized = 0
        var maxConsecutiveCapitalized = 0

        for word in words {
            if word.first?.isUppercase == true && word.count > 1 && !isCommonWord(word) {
                consecutiveCapitalized += 1
                maxConsecutiveCapitalized = max(maxConsecutiveCapitalized, consecutiveCapitalized)
            } else {
                consecutiveCapitalized = 0
            }
        }

        if maxConsecutiveCapitalized >= 2 {
            return true
        }

        // 2. Acronyms (2+ consecutive uppercase letters)
        let acronymCount = Self.acronymPattern?.numberOfMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ) ?? 0

        if acronymCount >= 2 {
            return true
        }

        // 3. Technical suffixes/prefixes
        let technicalPatterns = ["-tion", "-ity", "-ism", "-ology", "bio-", "geo-", "neo-"]
        for pattern in technicalPatterns {
            if text.lowercased().contains(pattern) {
                return true
            }
        }

        return false
    }

    // MARK: - Common Words Dictionary

    /// Expanded set of common English words to exclude from technical term detection
    /// Includes articles, pronouns, prepositions, conjunctions, and common verbs
    private static let commonWords: Set<String> = [
        // Articles
        "a", "an", "the",
        // Demonstratives
        "this", "that", "these", "those",
        // Pronouns
        "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them",
        "my", "your", "his", "its", "our", "their", "mine", "yours", "hers", "ours", "theirs",
        "myself", "yourself", "himself", "herself", "itself", "ourselves", "themselves",
        "who", "whom", "whose", "which", "what", "that",
        // Question words
        "when", "where", "why", "how",
        // Common verbs
        "is", "am", "are", "was", "were", "be", "been", "being",
        "have", "has", "had", "having",
        "do", "does", "did", "doing",
        "will", "would", "shall", "should", "can", "could", "may", "might", "must",
        "go", "going", "went", "gone",
        "get", "getting", "got", "gotten",
        "make", "making", "made",
        "take", "taking", "took", "taken",
        "come", "coming", "came",
        "see", "seeing", "saw", "seen",
        "know", "knowing", "knew", "known",
        "think", "thinking", "thought",
        "say", "saying", "said",
        "tell", "telling", "told",
        "find", "finding", "found",
        "give", "giving", "gave", "given",
        "use", "using", "used",
        "work", "working", "worked",
        "call", "calling", "called",
        "try", "trying", "tried",
        "ask", "asking", "asked",
        "need", "needing", "needed",
        "feel", "feeling", "felt",
        "become", "becoming", "became",
        "leave", "leaving", "left",
        "put", "putting",
        // Prepositions
        "in", "on", "at", "to", "for", "with", "from", "by", "about", "as",
        "into", "through", "during", "before", "after", "above", "below", "between",
        "under", "over", "against", "among", "of", "off", "up", "down", "out",
        // Conjunctions
        "and", "but", "or", "nor", "so", "yet", "for",
        "because", "since", "unless", "if", "when", "where", "while", "although",
        // Adverbs
        "not", "no", "yes", "very", "too", "also", "just", "only", "even",
        "now", "then", "there", "here", "still", "already", "always", "never",
        "often", "sometimes", "usually", "again", "back", "well", "really",
        // Common adjectives
        "good", "new", "first", "last", "long", "great", "little", "own",
        "other", "old", "right", "big", "high", "different", "small", "large",
        "next", "early", "young", "important", "few", "public", "bad", "same",
        // Numbers
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        // Other common words
        "all", "each", "every", "some", "any", "many", "much", "more", "most",
        "such", "like", "than", "way", "people", "time", "day", "year",
        "thing", "man", "woman", "child", "world", "life", "hand", "part",
        "place", "case", "point", "fact", "name", "number", "group", "problem",
        "company", "system", "program", "question", "government", "family"
    ]

    /// Check if word is a common word that shouldn't be counted as technical
    /// Uses case-insensitive matching against expanded dictionary
    private static func isCommonWord(_ word: String) -> Bool {
        return commonWords.contains(word.lowercased())
    }
}
