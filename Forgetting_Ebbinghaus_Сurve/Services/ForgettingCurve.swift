//
//  ForgettingCurve.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 05.11.2025.
//

import Foundation

// Defines the Ebbinghaus forgetting curve intervals.
// This is a dedicated business logic module with support for adaptive scheduling
// based on text length and complexity.
enum ForgettingCurve {

    // MARK: - Interval Sets

    /// Intervals for short, simple text (< 150 chars)
    /// Compressed schedule with faster early repetitions
    private static let shortTextIntervals: [TimeInterval] = [
        3,           // 3 seconds
        15,          // 15 seconds
        90,          // 1.5 minutes
        300,         // 5 minutes
        1800,        // 30 minutes
        9000,        // 2.5 hours
        43200,       // 12 hours
        172800,      // 2 days
        864000,      // 10 days
        5184000,     // 2 months (approx)
        31536000     // 1 year (approx)
    ]

    /// Intervals for medium text (150-400 chars)
    /// Standard Ebbinghaus curve - balanced approach
    private static let mediumTextIntervals: [TimeInterval] = [
        5,           // 5 seconds
        25,          // 25 seconds
        120,         // 2 minutes
        600,         // 10 minutes
        3600,        // 1 hour
        18000,       // 5 hours
        86400,       // 1 day
        432000,      // 5 days
        2160000,     // 25 days
        10368000,    // 4 months (approx)
        63072000     // 2 years (approx)
    ]

    /// Intervals for long, complex text (> 400 chars)
    /// Extended schedule with more time between repetitions
    private static let longTextIntervals: [TimeInterval] = [
        10,          // 10 seconds
        60,          // 1 minute
        300,         // 5 minutes
        1800,        // 30 minutes
        10800,       // 3 hours
        43200,       // 12 hours
        259200,      // 3 days
        1296000,     // 15 days
        5184000,     // 60 days
        20736000,    // 8 months (approx)
        94608000     // 3 years (approx)
    ]

    // MARK: - Backwards Compatibility

    /// Legacy intervals property - defaults to medium for backwards compatibility
    /// - Warning: This property will be removed in version 2.0. Use `intervals(for:)` instead.
    /// - Migration: Replace `ForgettingCurve.intervals` with `ForgettingCurve.intervals(for: .medium)`
    @available(*, deprecated, renamed: "intervals(for:)",
               message: "Use intervals(for:) to support adaptive text categories. Defaults to .medium. Will be removed in version 2.0.")
    static let intervals: [TimeInterval] = mediumTextIntervals

    // MARK: - Public API

    /// Returns the appropriate interval set for a given text category
    static func intervals(for category: TextCategory) -> [TimeInterval] {
        switch category {
        case .short:
            return shortTextIntervals
        case .medium:
            return mediumTextIntervals
        case .long:
            return longTextIntervals
        }
    }

    /// Calculates all reminder dates based on a starting date and text category
    static func reminderDates(from startDate: Date, category: TextCategory = .medium) -> [Date] {
        let selectedIntervals = intervals(for: category)
        return selectedIntervals.map { interval in
            startDate.addingTimeInterval(interval)
        }
    }

    /// Returns adjusted intervals with an adaptive multiplier for flashcard learning
    /// Used to speed up or slow down the schedule based on review performance
    /// - Parameters:
    ///   - category: The text category determining base intervals
    ///   - multiplier: Adaptive multiplier (typically 0.5-2.0)
    /// - Returns: Array of adjusted intervals, clamped to reasonable bounds
    static func adjustedIntervals(for category: TextCategory, multiplier: Double) -> [TimeInterval] {
        let baseIntervals = intervals(for: category)

        return baseIntervals.map { interval in
            let adjusted = interval * multiplier
            // Clamp to reasonable bounds: min 5 seconds, max 5 years
            let minInterval: TimeInterval = 5
            let maxInterval: TimeInterval = 157680000 // ~5 years
            return max(minInterval, min(maxInterval, adjusted))
        }
    }

    /// Calculates adjusted reminder dates with adaptive multiplier
    /// Used for flashcard items with performance-based interval adjustment
    /// - Parameters:
    ///   - startDate: The starting date for calculations
    ///   - category: The text category determining base intervals
    ///   - multiplier: Adaptive multiplier based on review performance
    /// - Returns: Array of reminder dates with adjusted intervals
    static func adjustedReminderDates(from startDate: Date, category: TextCategory, multiplier: Double) -> [Date] {
        let selectedIntervals = adjustedIntervals(for: category, multiplier: multiplier)
        return selectedIntervals.map { interval in
            startDate.addingTimeInterval(interval)
        }
    }

    // MARK: - Legacy Method (Backwards Compatibility)

    /// Legacy method - defaults to medium category for backwards compatibility
    /// - Warning: This method will be removed in version 2.0. Use `reminderDates(from:category:)` instead.
    /// - Migration: Replace `reminderDates(from: date)` with `reminderDates(from: date, category: .medium)`
    ///   or let the system auto-detect by using the default parameter value
    @available(*, deprecated, renamed: "reminderDates(from:category:)",
               message: "Use reminderDates(from:category:) to support adaptive text categories. Defaults to .medium. Will be removed in version 2.0.")
    static func reminderDates(from startDate: Date) -> [Date] {
        return reminderDates(from: startDate, category: .medium)
    }
}
