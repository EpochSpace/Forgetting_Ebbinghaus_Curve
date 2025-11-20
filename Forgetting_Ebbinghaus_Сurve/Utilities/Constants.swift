//
//  Constants.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac
//

import Foundation

/// Application-wide constants for configuration and magic numbers
enum Constants {

    // MARK: - Debounce Delays

    /// Delay before running text complexity analysis (in nanoseconds)
    static let textAnalysisDebounceDelay: UInt64 = 300_000_000 // 300ms

    // MARK: - Preview Lengths

    /// Maximum characters to show in flashcard front content preview
    static let frontContentPreviewLength = 100

    /// Maximum characters to show in flashcard back content preview
    static let backContentPreviewLength = 150

    // MARK: - Text Category Thresholds

    /// Character count threshold for short text (below this is short)
    static let shortTextThreshold = 20

    /// Character count threshold for medium text (between short and this is medium, above is long)
    static let mediumTextThreshold = 400

    // MARK: - Night Window Configuration

    /// Hour when night window starts (22:00 = 10 PM)
    static let nightWindowStartHour = 22

    /// Hour when morning wake time is (07:00 = 7 AM)
    static let morningWakeHour = 7

    /// Minimum interval in seconds to check for night window conflicts (10 minutes)
    /// Shorter intervals (5s, 25s, 2min) are not checked as they're for immediate review
    static let nightWindowMinimumIntervalToCheck: TimeInterval = 600 // 10 minutes

    // MARK: - Notification Titles

    /// Title for recall item notifications
    static let recallNotificationTitle = "Time to recall!"

    /// Title for flashcard notifications
    static let flashcardNotificationTitle = "Time to review flashcard!"

    // MARK: - UI Configuration

    /// Maximum width for flashcard detail view
    static let flashcardDetailMaxWidth: CGFloat = 500

    /// Minimum height for flashcard detail view
    static let flashcardDetailMinHeight: CGFloat = 400

    /// Maximum height for flashcard detail view
    static let flashcardDetailMaxHeight: CGFloat = 450

    /// Maximum scroll height for flashcard content
    static let flashcardContentMaxScrollHeight: CGFloat = 250

    // MARK: - Animation Durations

    /// Duration for flashcard flip animation (in seconds)
    static let flashcardFlipAnimationDuration: Double = 0.6

    // MARK: - Adaptive Learning

    /// Minimum interval multiplier for adaptive learning
    static let minimumIntervalMultiplier: Double = 0.5

    /// Maximum interval multiplier for adaptive learning
    static let maximumIntervalMultiplier: Double = 2.0

    /// Multiplier adjustment for "Hard" difficulty
    static let hardDifficultyMultiplier: Double = 0.7

    /// Multiplier adjustment for "Good" difficulty
    static let goodDifficultyMultiplier: Double = 1.0

    /// Multiplier adjustment for "Easy" difficulty
    static let easyDifficultyMultiplier: Double = 1.3
}
