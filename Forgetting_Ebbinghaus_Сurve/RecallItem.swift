//
//   RecallItem.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 05.11.2025.
//

import Foundation

// Represents a single piece of information the user wants to remember.
// Includes text category for adaptive spaced repetition scheduling.
struct RecallItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let createdAt: Date

    /// The complexity category of this text, determining reminder intervals
    /// Defaults to .medium for backwards compatibility with existing data
    var textCategory: TextCategory

    /// Indicates whether the user manually overrode the auto-detected category
    var isManuallyOverridden: Bool

    // MARK: - Computed Properties

    /// Character count of the content
    var characterCount: Int {
        content.count
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        textCategory: TextCategory = .medium,
        isManuallyOverridden: Bool = false
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.textCategory = textCategory
        self.isManuallyOverridden = isManuallyOverridden
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, content, createdAt, textCategory, isManuallyOverridden
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)

        // Backwards compatibility: default to .medium if not present
        textCategory = (try? container.decode(TextCategory.self, forKey: .textCategory)) ?? .medium
        isManuallyOverridden = (try? container.decode(Bool.self, forKey: .isManuallyOverridden)) ?? false
    }
}
