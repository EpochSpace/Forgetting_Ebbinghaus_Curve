//
//  RecallListViewModel.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 05.11.2025.
//

import Foundation

@MainActor
class RecallListViewModel: ObservableObject {

    @Published private(set) var items: [RecallItem] = [] {
        didSet {
            persistenceManager.saveItems(items)
        }
    }

    private let notificationManager: NotificationManagerProtocol
    private let persistenceManager: PersistenceManagerProtocol

    // Dependency injection with default parameters for backward compatibility
    init(
        notificationManager: NotificationManagerProtocol = NotificationManager.shared,
        persistenceManager: PersistenceManagerProtocol = PersistenceManager.shared
    ) {
        self.notificationManager = notificationManager
        self.persistenceManager = persistenceManager
        self.items = persistenceManager.loadItems()
    }
    
    // MARK: - Item Deletion

    /// Safely deletes items at the specified indices and cancels their associated notifications
    /// - Parameter offsets: The index set of items to delete
    func delete(at offsets: IndexSet) {
        // First, collect the items that will be deleted
        let itemsToDelete = offsets.map { items[$0] }

        // Cancel scheduled notifications for each item
        itemsToDelete.forEach { item in
            notificationManager.cancelNotifications(for: item)
        }

        // Finally, remove the items from our array
        items.remove(atOffsets: offsets)
    }

    // MARK: - Notification Management
    
    func requestNotificationPermission() {
        notificationManager.requestAuthorization()
    }

    // MARK: - Text Complexity Analysis

    /// Analyzes text content and returns the recommended category with details
    func analyzeText(_ content: String) -> TextComplexityAnalyzer.AnalysisResult {
        return TextComplexityAnalyzer.analyze(content)
    }

    /// Analyzes text and returns just the category (convenience method)
    func determineCategory(for content: String) -> TextCategory {
        return TextComplexityAnalyzer.analyze(content).category
    }

    /// Checks if scheduling notifications for the given content would result in night-time conflicts.
    /// Only checks intervals >= 10 minutes (skips 5s, 25s, 2min).
    /// - Parameters:
    ///   - content: The content to be added
    ///   - category: Optional text category. If nil, will auto-detect.
    /// - Returns: NotificationConflict if conflicts detected, nil otherwise
    func checkForConflicts(content: String, category: TextCategory? = nil) -> NotificationConflict? {
        guard !content.isEmpty else { return nil }

        // Determine category (use provided or auto-detect)
        let textCategory = category ?? determineCategory(for: content)

        // Create a temporary item to calculate notification dates
        let tempItem = RecallItem(content: content, textCategory: textCategory)
        let allDates = ForgettingCurve.reminderDates(from: tempItem.createdAt, category: textCategory)

        // Filter to only check intervals >= 10 minutes (indices 3+)
        // Index 0: 5s, Index 1: 25s, Index 2: 2min (skip these)
        // Index 3: 10min and beyond (check these)
        let datesToCheck = Array(allDates.dropFirst(3))

        // Find dates that fall in the night window
        let conflictingDates = datesToCheck.filter { NightWindow.isDateInNightWindow($0) }

        // If no conflicts, return nil
        guard !conflictingDates.isEmpty else { return nil }

        // Calculate postponed dates (next 7 AM after each conflicting notification)
        let postponedDates = conflictingDates.map { date in
            NightWindow.nextMorningWakeTime(after: date)
        }

        // Detect user's region
        let region = NightWindow.detectUserRegion()

        return NotificationConflict(
            item: tempItem,
            allScheduledDates: allDates,
            conflictingDates: conflictingDates,
            postponedDates: postponedDates,
            userRegion: region
        )
    }

    /// Adds an item with optional postponement of conflicting notifications.
    /// - Parameters:
    ///   - content: The content to remember
    ///   - manualCategory: Optional manually-selected category. If nil, auto-detects based on text.
    ///   - conflict: Optional conflict information. If provided, conflicting dates will be postponed.
    func addItem(content: String, manualCategory: TextCategory? = nil, withConflict conflict: NotificationConflict? = nil) {
        guard !content.isEmpty else { return }

        // Determine category (manual override or auto-detect)
        let category: TextCategory
        let isManualOverride: Bool
        if let manualCategory = manualCategory {
            category = manualCategory
            isManualOverride = true
        } else {
            category = determineCategory(for: content)
            isManualOverride = false
        }

        let newItem = RecallItem(
            content: content,
            textCategory: category,
            isManuallyOverridden: isManualOverride
        )
        items.insert(newItem, at: 0)

        // Determine which dates to use for scheduling
        let scheduleDates: [Date]
        if let conflict = conflict {
            // Use the final schedule that combines non-conflicting and postponed dates
            scheduleDates = conflict.finalSchedule
        } else {
            // Use all original dates with the determined category
            scheduleDates = ForgettingCurve.reminderDates(from: newItem.createdAt, category: category)
        }

        notificationManager.scheduleNotifications(for: newItem, on: scheduleDates)
    }
    
    func getReminderDates(for item: RecallItem) -> [Date] {
        return ForgettingCurve.reminderDates(from: item.createdAt, category: item.textCategory)
    }

    func getNextReminderDate(for item: RecallItem) -> Date? {
        let allDates = ForgettingCurve.reminderDates(from: item.createdAt, category: item.textCategory)
        return allDates.first(where: { $0 > Date() })
    }

    // MARK: - Category Management

    /// Updates the text category for an existing item and reschedules notifications
    /// - Parameters:
    ///   - itemId: The ID of the item to update
    ///   - newCategory: The new category to apply
    func updateCategory(for itemId: UUID, to newCategory: TextCategory) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }

        var updatedItem = items[index]

        // Cancel existing notifications
        notificationManager.cancelNotifications(for: updatedItem)

        // Update the item with new category
        updatedItem.textCategory = newCategory
        updatedItem.isManuallyOverridden = true
        items[index] = updatedItem

        // Reschedule notifications with new intervals
        let newDates = ForgettingCurve.reminderDates(from: updatedItem.createdAt, category: newCategory)
        notificationManager.scheduleNotifications(for: updatedItem, on: newDates)
    }

    func cancelAllPendingNotifications() {
        notificationManager.cancelAllNotifications()
    }

    func logAllPendingNotifications() {
        notificationManager.logPendingNotifications()
    }
}
