//
//  NotificationConflict.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 16.11.2025.
//

import Foundation

/// Represents a conflict between scheduled notifications and the night window.
struct NotificationConflict {

    /// The item being added that has conflicting notifications
    let item: RecallItem

    /// All originally scheduled notification dates for this item
    let allScheduledDates: [Date]

    /// Notification dates that fall within the night window
    let conflictingDates: [Date]

    /// Suggested postponement dates (7 AM for each conflicting notification)
    let postponedDates: [Date]

    /// The user's detected region for context-aware messaging
    let userRegion: String

    /// Computed property: number of conflicting notifications
    var conflictCount: Int {
        conflictingDates.count
    }

    /// Creates a mapping from original dates to postponed dates
    var dateMapping: [Date: Date] {
        var mapping: [Date: Date] = [:]
        for (index, originalDate) in conflictingDates.enumerated() {
            if index < postponedDates.count {
                mapping[originalDate] = postponedDates[index]
            }
        }
        return mapping
    }

    /// Generates a user-friendly alert message describing the conflict
    var alertMessage: String {
        let count = conflictCount
        let reminderText = count == 1 ? "reminder" : "reminders"

        return """
        We've detected that it is currently nighttime in \(userRegion). \
        We suggest that learning is more effective after a good night's sleep. \
        Would you like to postpone \(count) \(reminderText) until the morning?
        """
    }

    /// Generates the final schedule combining non-conflicting and postponed dates
    var finalSchedule: [Date] {
        let nonConflictingDates = allScheduledDates.filter { !conflictingDates.contains($0) }
        return (nonConflictingDates + postponedDates).sorted()
    }
}
