//
//  StudyProgress.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac
//

import Foundation

/// Tracks the review performance and adaptive learning progress for a flashcard
/// Implements Anki-style interval adjustment based on difficulty ratings
struct StudyProgress: Codable {
    /// Total number of times this flashcard has been reviewed
    var totalReviews: Int = 0

    /// Count of "Easy" ratings
    var easyCount: Int = 0

    /// Count of "Good" ratings
    var goodCount: Int = 0

    /// Count of "Hard" ratings
    var hardCount: Int = 0

    /// The last time this flashcard was reviewed
    var lastReviewDate: Date?

    /// Current adaptive multiplier applied to base intervals (clamped 0.5-2.0)
    /// Starts at 1.0 and adjusts based on review difficulty
    var currentIntervalMultiplier: Double = 1.0

    // MARK: - Computed Properties

    /// Success rate (Easy + Good) / Total
    var successRate: Double {
        guard totalReviews > 0 else { return 0.0 }
        let successfulReviews = easyCount + goodCount
        return Double(successfulReviews) / Double(totalReviews)
    }

    /// Average difficulty as a string
    var averageDifficulty: String {
        guard totalReviews > 0 else { return "Not reviewed yet" }

        if easyCount > goodCount && easyCount > hardCount {
            return "Easy"
        } else if hardCount > goodCount && hardCount > easyCount {
            return "Hard"
        } else {
            return "Normal"
        }
    }

    // MARK: - Methods

    /// Records a review and updates the adaptive interval multiplier
    /// - Parameter difficulty: The difficulty rating given by the user
    mutating func recordReview(difficulty: ReviewDifficulty) {
        totalReviews += 1
        lastReviewDate = Date()

        // Update counts
        switch difficulty {
        case .easy:
            easyCount += 1
            currentIntervalMultiplier *= difficulty.intervalMultiplier // ×1.3
        case .good:
            goodCount += 1
            currentIntervalMultiplier *= difficulty.intervalMultiplier // ×1.0 (no change)
        case .hard:
            hardCount += 1
            currentIntervalMultiplier *= difficulty.intervalMultiplier // ×0.7
        }

        // Clamp multiplier to reasonable bounds (0.5x to 2.0x)
        // This prevents intervals from becoming too short or too long
        currentIntervalMultiplier = max(0.5, min(2.0, currentIntervalMultiplier))
    }

    /// Resets the progress (useful if user wants to start over)
    mutating func reset() {
        totalReviews = 0
        easyCount = 0
        goodCount = 0
        hardCount = 0
        lastReviewDate = nil
        currentIntervalMultiplier = 1.0
    }
}
