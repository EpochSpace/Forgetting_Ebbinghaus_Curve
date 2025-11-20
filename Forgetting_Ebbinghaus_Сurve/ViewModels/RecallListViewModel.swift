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

    @Published private(set) var flashcardItems: [FlashcardItem] = [] {
        didSet {
            persistenceManager.saveFlashcards(flashcardItems)
        }
    }

    @Published var studyMode: Bool = false

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
        self.flashcardItems = persistenceManager.loadFlashcards()
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

    // MARK: - Flashcard Management

    /// Checks if scheduling flashcard notifications would result in night-time conflicts
    /// - Parameters:
    ///   - frontContent: The question/front of the card
    ///   - backContent: The answer/back of the card
    ///   - category: Optional text category. If nil, will auto-detect.
    /// - Returns: NotificationConflict if conflicts detected, nil otherwise
    func checkForFlashcardConflicts(frontContent: String, backContent: String, category: TextCategory? = nil) -> NotificationConflict? {
        guard !frontContent.isEmpty else { return nil }

        let combinedContent = frontContent + " " + backContent
        let textCategory = category ?? determineCategory(for: combinedContent)

        // Create a temporary flashcard to calculate notification dates
        let tempFlashcard = FlashcardItem(
            frontContent: frontContent,
            backContent: backContent,
            textCategory: textCategory
        )

        let allDates = ForgettingCurve.reminderDates(from: tempFlashcard.createdAt, category: textCategory)

        // Filter to only check intervals >= 10 minutes (indices 3+)
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

        // Create a temporary RecallItem for conflict structure
        let tempItem = RecallItem(content: combinedContent, textCategory: textCategory)

        return NotificationConflict(
            item: tempItem,
            allScheduledDates: allDates,
            conflictingDates: conflictingDates,
            postponedDates: postponedDates,
            userRegion: region
        )
    }

    /// Adds a new flashcard with optional conflict postponement
    /// - Parameters:
    ///   - frontContent: The question/prompt (front of card)
    ///   - backContent: The answer/explanation (back of card)
    ///   - manualCategory: Optional manually-selected category. If nil, auto-detects based on combined text.
    ///   - conflict: Optional conflict information. If provided, conflicting dates will be postponed.
    func addFlashcard(frontContent: String, backContent: String, manualCategory: TextCategory? = nil, withConflict conflict: NotificationConflict? = nil) {
        guard !frontContent.isEmpty else { return }

        let combinedContent = frontContent + " " + backContent

        // Determine category (manual override or auto-detect)
        let category: TextCategory
        let isManualOverride: Bool
        if let manualCategory = manualCategory {
            category = manualCategory
            isManualOverride = true
        } else {
            category = determineCategory(for: combinedContent)
            isManualOverride = false
        }

        let newFlashcard = FlashcardItem(
            frontContent: frontContent,
            backContent: backContent,
            textCategory: category,
            isManuallyOverridden: isManualOverride
        )

        flashcardItems.insert(newFlashcard, at: 0)

        // Determine which dates to use for scheduling
        var scheduleDates: [Date]
        if let conflict = conflict {
            // Use the final schedule that combines non-conflicting and postponed dates
            scheduleDates = conflict.finalSchedule
        } else {
            // Use all original dates with the determined category
            scheduleDates = ForgettingCurve.reminderDates(from: newFlashcard.createdAt, category: category)
        }

        // Make the first review immediately due by setting it to the creation time
        if !scheduleDates.isEmpty {
            scheduleDates[0] = newFlashcard.createdAt
        }

        notificationManager.scheduleNotifications(for: newFlashcard, on: scheduleDates)
    }

    /// Deletes flashcards at the specified indices and cancels their notifications
    /// - Parameter offsets: The index set of flashcards to delete
    func deleteFlashcards(at offsets: IndexSet) {
        // First, collect the flashcards that will be deleted
        let flashcardsToDelete = offsets.map { flashcardItems[$0] }

        // Cancel scheduled notifications for each flashcard
        flashcardsToDelete.forEach { flashcard in
            notificationManager.cancelNotifications(for: flashcard)
        }

        // Finally, remove the flashcards from our array
        flashcardItems.remove(atOffsets: offsets)
    }

    /// Returns all flashcards that are due for review (next reminder date has passed)
    func getDueFlashcards() -> [FlashcardItem] {
        return flashcardItems.filter { flashcard in
            let allDates = getFlashcardReminderDates(for: flashcard)

            // Count how many scheduled reviews should have happened by now
            let dueReviewCount = allDates.filter { $0 <= Date() }.count

            // Flashcard is due if there are more scheduled reviews than completed reviews
            return dueReviewCount > flashcard.studyProgress.totalReviews
        }
    }

    /// Gets all scheduled reminder dates for a flashcard (with adaptive multiplier applied)
    /// - Parameter flashcard: The flashcard to get dates for
    /// - Returns: Array of reminder dates
    func getFlashcardReminderDates(for flashcard: FlashcardItem) -> [Date] {
        let multiplier = flashcard.studyProgress.currentIntervalMultiplier
        var dates = ForgettingCurve.adjustedReminderDates(
            from: flashcard.createdAt,
            category: flashcard.textCategory,
            multiplier: multiplier
        )

        // Make the first review immediately due for new flashcards (never reviewed)
        if flashcard.studyProgress.totalReviews == 0 && !dates.isEmpty {
            dates[0] = flashcard.createdAt
        }

        return dates
    }

    /// Gets the next upcoming reminder date for a flashcard
    /// - Parameter flashcard: The flashcard to check
    /// - Returns: The next scheduled reminder date, or nil if all have passed
    func getNextFlashcardReminderDate(for flashcard: FlashcardItem) -> Date? {
        let allDates = getFlashcardReminderDates(for: flashcard)
        return allDates.first(where: { $0 > Date() })
    }

    /// Records a review for a flashcard and reschedules notifications with adjusted intervals
    /// - Parameters:
    ///   - flashcardId: The ID of the flashcard being reviewed
    ///   - difficulty: The difficulty rating given by the user
    func recordReview(flashcardId: UUID, difficulty: ReviewDifficulty) {
        guard let index = flashcardItems.firstIndex(where: { $0.id == flashcardId }) else {
            print("⚠️ WARNING: Attempted to review non-existent flashcard: \(flashcardId)")
            return
        }

        var updatedFlashcard = flashcardItems[index]

        // Record the review and update the adaptive multiplier
        updatedFlashcard.studyProgress.recordReview(difficulty: difficulty)

        // Update the flashcard in the array FIRST to ensure atomic state consistency
        // This prevents race conditions where other code reads stale data
        flashcardItems[index] = updatedFlashcard

        // Now update external systems (notifications) - order matters for consistency
        notificationManager.cancelNotifications(for: updatedFlashcard)

        // Calculate new dates with adjusted intervals
        let adjustedDates = getFlashcardReminderDates(for: updatedFlashcard)

        // Reschedule with new intervals
        notificationManager.scheduleNotifications(for: updatedFlashcard, on: adjustedDates)

        print("Recorded \(difficulty.rawValue) review for flashcard. New multiplier: \(updatedFlashcard.studyProgress.currentIntervalMultiplier)")
    }

    /// Updates the text category for an existing flashcard and reschedules notifications
    /// - Parameters:
    ///   - flashcardId: The ID of the flashcard to update
    ///   - newCategory: The new category to apply
    func updateFlashcardCategory(for flashcardId: UUID, to newCategory: TextCategory) {
        guard let index = flashcardItems.firstIndex(where: { $0.id == flashcardId }) else { return }

        var updatedFlashcard = flashcardItems[index]

        // Cancel existing notifications
        notificationManager.cancelNotifications(for: updatedFlashcard)

        // Update the flashcard with new category
        updatedFlashcard.textCategory = newCategory
        updatedFlashcard.isManuallyOverridden = true
        flashcardItems[index] = updatedFlashcard

        // Reschedule notifications with new intervals (including current multiplier)
        let newDates = getFlashcardReminderDates(for: updatedFlashcard)
        notificationManager.scheduleNotifications(for: updatedFlashcard, on: newDates)
    }
}
