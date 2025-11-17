//
//  TextCategory.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 17.11.2025.
//

import Foundation

/// Represents the complexity category of recall item text
/// Used to determine appropriate spaced repetition intervals
enum TextCategory: String, Codable, CaseIterable {
    case short
    case medium
    case long

    /// Human-readable display name for the category
    var displayName: String {
        switch self {
        case .short:
            return "Short"
        case .medium:
            return "Medium"
        case .long:
            return "Long"
        }
    }

    /// Description of what this category represents
    var description: String {
        switch self {
        case .short:
            return "< 150 characters - Quick review intervals"
        case .medium:
            return "150-400 characters - Standard intervals"
        case .long:
            return "> 400 characters - Extended intervals"
        }
    }

    /// Icon representation for UI display
    var icon: String {
        switch self {
        case .short:
            return "doc.text"
        case .medium:
            return "doc.text.fill"
        case .long:
            return "doc.richtext.fill"
        }
    }
}
