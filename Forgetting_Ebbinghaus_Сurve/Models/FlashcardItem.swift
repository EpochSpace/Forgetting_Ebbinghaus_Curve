//
//  FlashcardItem.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac
//

import Foundation

/// Represents a flashcard with front (question) and back (answer) content
/// Supports spaced repetition with adaptive learning based on review performance
struct FlashcardItem: Identifiable, Codable {
    let id: UUID

    /// The front of the card (question/prompt)
    let frontContent: String

    /// The back of the card (answer/explanation)
    let backContent: String

    /// When this flashcard was created
    let createdAt: Date

    /// Text category determines the base interval schedule
    /// Calculated from combined front+back character count
    var textCategory: TextCategory

    /// Whether the user manually overrode the auto-detected category
    var isManuallyOverridden: Bool

    /// Tracks review performance and adaptive learning progress
    var studyProgress: StudyProgress

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        frontContent: String,
        backContent: String,
        createdAt: Date = Date(),
        textCategory: TextCategory = .medium,
        isManuallyOverridden: Bool = false,
        studyProgress: StudyProgress = StudyProgress()
    ) {
        self.id = id
        self.frontContent = frontContent
        self.backContent = backContent
        self.createdAt = createdAt
        self.textCategory = textCategory
        self.isManuallyOverridden = isManuallyOverridden
        self.studyProgress = studyProgress
    }

    // MARK: - Computed Properties

    /// Total character count (front + back)
    /// Used for text category detection
    var characterCount: Int {
        return frontContent.count + backContent.count
    }

    /// Short preview of the front content for list views
    var frontPreview: String {
        if frontContent.count <= 100 {
            return frontContent
        }
        return String(frontContent.prefix(100)) + "..."
    }

    /// Short preview of the back content for detail views
    var backPreview: String {
        if backContent.count <= 150 {
            return backContent
        }
        return String(backContent.prefix(150)) + "..."
    }

    /// Whether this flashcard has been reviewed at least once
    var hasBeenReviewed: Bool {
        return studyProgress.totalReviews > 0
    }

    /// Combined content for complexity analysis
    var combinedContent: String {
        return frontContent + " " + backContent
    }
}

// MARK: - Equatable
extension FlashcardItem: Equatable {
    static func == (lhs: FlashcardItem, rhs: FlashcardItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension FlashcardItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
