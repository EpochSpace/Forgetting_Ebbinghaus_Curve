//
//  ReviewDifficulty.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac
//

import SwiftUI

/// Enum representing the difficulty rating for flashcard reviews
/// Used in adaptive learning to adjust reminder intervals
enum ReviewDifficulty: String, Codable, CaseIterable {
    case hard = "Hard"
    case good = "Good"
    case easy = "Easy"

    /// Display color matching the demo design (#ef4444, #eab308, #22c55e)
    var color: Color {
        switch self {
        case .hard: return Color(red: 0.937, green: 0.267, blue: 0.267) // #ef4444
        case .good: return Color(red: 0.918, green: 0.702, blue: 0.031) // #eab308
        case .easy: return Color(red: 0.133, green: 0.773, blue: 0.369) // #22c55e
        }
    }

    /// SF Symbol icon for this difficulty level
    var icon: String {
        switch self {
        case .hard: return "exclamationmark.circle.fill"
        case .good: return "checkmark.circle.fill"
        case .easy: return "star.circle.fill"
        }
    }

    /// Interval multiplier applied to base forgetting curve
    /// Hard slows down (×0.7), Good maintains (×1.0), Easy speeds up (×1.3)
    var intervalMultiplier: Double {
        switch self {
        case .hard: return 0.7
        case .good: return 1.0
        case .easy: return 1.3
        }
    }

    /// User-friendly description shown in UI
    var description: String {
        switch self {
        case .hard: return "Didn't remember well"
        case .good: return "Remembered correctly"
        case .easy: return "Too easy!"
        }
    }
}
