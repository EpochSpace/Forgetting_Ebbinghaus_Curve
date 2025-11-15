//
//  Forgetting_Ebbinghaus__urveTests.swift
//  Forgetting_Ebbinghaus_СurveTests
//
//  Created by mac on 05.11.2025.
//

import Testing
import Foundation
@testable import Forgetting_Ebbinghaus_Сurve

// MARK: - Mock Implementations for Testing

/// Mock PersistenceManager for testing without file system dependencies
@MainActor
final class MockPersistenceManager: PersistenceManagerProtocol {
    var savedItems: [RecallItem] = []
    var itemsToLoad: [RecallItem] = []
    var saveCallCount = 0
    var loadCallCount = 0

    func loadItems() -> [RecallItem] {
        loadCallCount += 1
        return itemsToLoad
    }

    func saveItems(_ items: [RecallItem]) {
        saveCallCount += 1
        savedItems = items
    }
}

/// Mock NotificationManager for testing without system notification dependencies
@MainActor
final class MockNotificationManager: NotificationManagerProtocol {
    var authorizationRequested = false
    var scheduledNotifications: [(item: RecallItem, dates: [Date])] = []
    var cancelledItems: [RecallItem] = []
    var allNotificationsCancelled = false
    var delegateSetup = false
    var loggingRequested = false

    func setupDelegate() {
        delegateSetup = true
    }

    func requestAuthorization() {
        authorizationRequested = true
    }

    func scheduleNotifications(for item: RecallItem, on dates: [Date]) {
        scheduledNotifications.append((item, dates))
    }

    func cancelAllNotifications() {
        allNotificationsCancelled = true
    }

    func cancelNotifications(for item: RecallItem) {
        cancelledItems.append(item)
    }

    func logPendingNotifications() {
        loggingRequested = true
    }
}

// MARK: - RecallItem Tests

@Suite("RecallItem Tests")
struct RecallItemTests {

    @Test("RecallItem initialization with default values")
    func testInitializationWithDefaults() {
        let item = RecallItem(content: "Test content")

        #expect(item.content == "Test content")
        #expect(item.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(item.createdAt.timeIntervalSinceNow < 1.0) // Created within last second
    }

    @Test("RecallItem initialization with custom values")
    func testInitializationWithCustomValues() {
        let customUUID = UUID()
        let customDate = Date(timeIntervalSince1970: 1000000)

        let item = RecallItem(id: customUUID, content: "Custom content", createdAt: customDate)

        #expect(item.id == customUUID)
        #expect(item.content == "Custom content")
        #expect(item.createdAt == customDate)
    }

    @Test("RecallItem Codable conformance - encode and decode roundtrip")
    func testCodableConformance() throws {
        let originalItem = RecallItem(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            content: "Test encoding",
            createdAt: Date(timeIntervalSince1970: 1234567890)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalItem)

        let decoder = JSONDecoder()
        let decodedItem = try decoder.decode(RecallItem.self, from: data)

        #expect(decodedItem.id == originalItem.id)
        #expect(decodedItem.content == originalItem.content)
        #expect(decodedItem.createdAt.timeIntervalSince1970 == originalItem.createdAt.timeIntervalSince1970)
    }

    @Test("RecallItem Identifiable conformance - unique IDs")
    func testIdentifiableConformance() {
        let item1 = RecallItem(content: "First")
        let item2 = RecallItem(content: "Second")

        #expect(item1.id != item2.id)
    }

    @Test("RecallItem with empty content")
    func testEmptyContent() {
        let item = RecallItem(content: "")
        #expect(item.content == "")
    }

    @Test("RecallItem with very long content")
    func testLongContent() {
        let longContent = String(repeating: "a", count: 10000)
        let item = RecallItem(content: longContent)
        #expect(item.content.count == 10000)
    }
}

// MARK: - ForgettingCurve Tests

@Suite("ForgettingCurve Tests")
struct ForgettingCurveTests {

    @Test("ForgettingCurve has exactly 11 intervals")
    func testIntervalCount() {
        #expect(ForgettingCurve.intervals.count == 11)
    }

    @Test("ForgettingCurve interval values are correct")
    func testIntervalValues() {
        let expected: [TimeInterval] = [
            5,           // 5 seconds
            25,          // 25 seconds
            120,         // 2 minutes
            600,         // 10 minutes
            3600,        // 1 hour
            18000,       // 5 hours
            86400,       // 1 day
            432000,      // 5 days
            2160000,     // 25 days
            10368000,    // 4 months
            63072000     // 2 years
        ]

        for (index, interval) in ForgettingCurve.intervals.enumerated() {
            #expect(interval == expected[index])
        }
    }

    @Test("ForgettingCurve intervals are in ascending order")
    func testIntervalsAscending() {
        for i in 0..<(ForgettingCurve.intervals.count - 1) {
            #expect(ForgettingCurve.intervals[i] < ForgettingCurve.intervals[i + 1])
        }
    }

    @Test("reminderDates returns 11 dates")
    func testReminderDatesCount() {
        let startDate = Date()
        let dates = ForgettingCurve.reminderDates(from: startDate)
        #expect(dates.count == 11)
    }

    @Test("reminderDates calculates correct dates from start")
    func testReminderDatesCorrectCalculation() {
        let startDate = Date(timeIntervalSince1970: 1000000)
        let dates = ForgettingCurve.reminderDates(from: startDate)

        for (index, date) in dates.enumerated() {
            let expectedDate = startDate.addingTimeInterval(ForgettingCurve.intervals[index])
            #expect(date.timeIntervalSince1970 == expectedDate.timeIntervalSince1970)
        }
    }

    @Test("reminderDates with past start date")
    func testReminderDatesWithPastDate() {
        let pastDate = Date(timeIntervalSince1970: 0) // 1970
        let dates = ForgettingCurve.reminderDates(from: pastDate)

        #expect(dates.count == 11)
        #expect(dates.first! == pastDate.addingTimeInterval(5))
    }

    @Test("reminderDates with future start date")
    func testReminderDatesWithFutureDate() {
        let futureDate = Date().addingTimeInterval(86400 * 365) // 1 year from now
        let dates = ForgettingCurve.reminderDates(from: futureDate)

        #expect(dates.count == 11)
        #expect(dates.first! > Date())
    }

    @Test("reminderDates are in chronological order")
    func testReminderDatesInOrder() {
        let startDate = Date()
        let dates = ForgettingCurve.reminderDates(from: startDate)

        for i in 0..<(dates.count - 1) {
            #expect(dates[i] < dates[i + 1])
        }
    }

    @Test("First reminder is 5 seconds after start")
    func testFirstReminderInterval() {
        let startDate = Date(timeIntervalSince1970: 1000000)
        let dates = ForgettingCurve.reminderDates(from: startDate)

        let difference = dates.first!.timeIntervalSince(startDate)
        #expect(difference == 5.0)
    }

    @Test("Last reminder is approximately 2 years after start")
    func testLastReminderInterval() {
        let startDate = Date(timeIntervalSince1970: 1000000)
        let dates = ForgettingCurve.reminderDates(from: startDate)

        let difference = dates.last!.timeIntervalSince(startDate)
        #expect(difference == 63072000) // 2 years in seconds
    }
}

// MARK: - TimeInterval+Formatting Tests

@Suite("TimeInterval+Formatting Tests")
struct TimeIntervalFormattingTests {

    @Test("Formatting for negative value returns 'Done!'")
    func testNegativeValue() {
        let interval: TimeInterval = -100
        #expect(interval.formattedForCountdown() == "Done!")
    }

    @Test("Formatting for zero returns 'Done!'")
    func testZeroValue() {
        let interval: TimeInterval = 0
        #expect(interval.formattedForCountdown() == "Done!")
    }

    @Test("Formatting for seconds only (less than 1 minute)")
    func testSecondsOnly() {
        let interval: TimeInterval = 45
        #expect(interval.formattedForCountdown() == "00:00:45")
    }

    @Test("Formatting for minutes and seconds (less than 1 hour)")
    func testMinutesAndSeconds() {
        let interval: TimeInterval = 125 // 2 minutes 5 seconds
        #expect(interval.formattedForCountdown() == "00:02:05")
    }

    @Test("Formatting for hours, minutes, seconds (less than 1 day)")
    func testHoursMinutesSeconds() {
        let interval: TimeInterval = 3661 // 1 hour, 1 minute, 1 second
        #expect(interval.formattedForCountdown() == "01:01:01")
    }

    @Test("Formatting for exactly 1 hour")
    func testExactlyOneHour() {
        let interval: TimeInterval = 3600
        #expect(interval.formattedForCountdown() == "01:00:00")
    }

    @Test("Formatting for exactly 1 day")
    func testExactlyOneDay() {
        let interval: TimeInterval = 86400
        #expect(interval.formattedForCountdown() == "1 day(s), 00:00:00")
    }

    @Test("Formatting for days and hours")
    func testDaysAndHours() {
        let interval: TimeInterval = 90061 // 1 day, 1 hour, 1 minute, 1 second
        #expect(interval.formattedForCountdown() == "1 day(s), 01:01:01")
    }

    @Test("Formatting for multiple days")
    func testMultipleDays() {
        let interval: TimeInterval = 259200 // 3 days
        #expect(interval.formattedForCountdown() == "3 day(s), 00:00:00")
    }

    @Test("Formatting for large values (months)")
    func testMonths() {
        let interval: TimeInterval = 2592000 // ~30 days
        #expect(interval.formattedForCountdown() == "30 day(s), 00:00:00")
    }

    @Test("Formatting for very large values (years)")
    func testYears() {
        let interval: TimeInterval = 31536000 // 365 days
        #expect(interval.formattedForCountdown() == "365 day(s), 00:00:00")
    }

    @Test("Formatting edge case - exactly 23:59:59")
    func testAlmostOneDay() {
        let interval: TimeInterval = 86399 // 23:59:59
        #expect(interval.formattedForCountdown() == "23:59:59")
    }

    @Test("Formatting edge case - 1 second")
    func testOneSecond() {
        let interval: TimeInterval = 1
        #expect(interval.formattedForCountdown() == "00:00:01")
    }
}

// MARK: - PersistenceManager Tests

@Suite("PersistenceManager Tests")
struct PersistenceManagerTests {

    @Test("PersistenceManager is a singleton")
    func testSingleton() {
        let instance1 = PersistenceManager.shared
        let instance2 = PersistenceManager.shared

        #expect(instance1 === instance2)
    }

    @Test("Save and load empty array")
    func testSaveLoadEmptyArray() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_empty_\(UUID().uuidString).json")

        let manager = createTestPersistenceManager(url: tempURL)

        manager.saveItems([])
        let loaded = manager.loadItems()

        #expect(loaded.isEmpty)

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Save and load single item")
    func testSaveLoadSingleItem() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_single_\(UUID().uuidString).json")

        let manager = createTestPersistenceManager(url: tempURL)

        let item = RecallItem(content: "Test item")
        manager.saveItems([item])

        let loaded = manager.loadItems()

        #expect(loaded.count == 1)
        #expect(loaded.first?.content == "Test item")

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Save and load multiple items")
    func testSaveLoadMultipleItems() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_multiple_\(UUID().uuidString).json")

        let manager = createTestPersistenceManager(url: tempURL)

        let items = [
            RecallItem(content: "First"),
            RecallItem(content: "Second"),
            RecallItem(content: "Third")
        ]
        manager.saveItems(items)

        let loaded = manager.loadItems()

        #expect(loaded.count == 3)
        #expect(loaded[0].content == "First")
        #expect(loaded[1].content == "Second")
        #expect(loaded[2].content == "Third")

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Load returns empty array when file doesn't exist")
    func testLoadNonexistentFile() {
        let nonexistentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent_\(UUID().uuidString).json")

        let manager = createTestPersistenceManager(url: nonexistentURL)
        let loaded = manager.loadItems()

        #expect(loaded.isEmpty)
    }

    @Test("Save and load preserves all item properties")
    func testSaveLoadPreservesProperties() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_properties_\(UUID().uuidString).json")

        let manager = createTestPersistenceManager(url: tempURL)

        let customID = UUID()
        let customDate = Date(timeIntervalSince1970: 1234567890)
        let item = RecallItem(id: customID, content: "Custom item", createdAt: customDate)

        manager.saveItems([item])
        let loaded = manager.loadItems()

        #expect(loaded.first?.id == customID)
        #expect(loaded.first?.content == "Custom item")
        #expect(loaded.first?.createdAt.timeIntervalSince1970 == customDate.timeIntervalSince1970)

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    // Helper to create a testable persistence manager with custom URL
    private func createTestPersistenceManager(url: URL) -> TestablePersistenceManager {
        return TestablePersistenceManager(testURL: url)
    }
}

// Testable version of PersistenceManager that allows custom file URL
private class TestablePersistenceManager {
    private let dataURL: URL

    init(testURL: URL) {
        self.dataURL = testURL
    }

    func loadItems() -> [RecallItem] {
        do {
            let data = try Data(contentsOf: dataURL)
            let items = try JSONDecoder().decode([RecallItem].self, from: data)
            return items
        } catch {
            return []
        }
    }

    func saveItems(_ items: [RecallItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: dataURL, options: .atomic)
        } catch {
            print("Failed to save items: \(error.localizedDescription)")
        }
    }
}

// MARK: - NotificationManager Tests

@Suite("NotificationManager Tests")
struct NotificationManagerTests {

    @Test("NotificationManager is a singleton")
    func testSingleton() {
        let instance1 = NotificationManager.shared
        let instance2 = NotificationManager.shared

        #expect(instance1 === instance2)
    }

    @Test("Mock notification manager tracks authorization requests")
    @MainActor
    func testAuthorizationRequest() {
        let mock = MockNotificationManager()
        #expect(mock.authorizationRequested == false)

        mock.requestAuthorization()
        #expect(mock.authorizationRequested == true)
    }

    @Test("Mock notification manager tracks scheduled notifications")
    @MainActor
    func testScheduleNotifications() {
        let mock = MockNotificationManager()
        let item = RecallItem(content: "Test")
        let dates = [Date(), Date().addingTimeInterval(100)]

        mock.scheduleNotifications(for: item, on: dates)

        #expect(mock.scheduledNotifications.count == 1)
        #expect(mock.scheduledNotifications.first?.item.content == "Test")
        #expect(mock.scheduledNotifications.first?.dates.count == 2)
    }

    @Test("Mock notification manager tracks cancellation for specific item")
    @MainActor
    func testCancelNotificationsForItem() {
        let mock = MockNotificationManager()
        let item = RecallItem(content: "Test")

        mock.cancelNotifications(for: item)

        #expect(mock.cancelledItems.count == 1)
        #expect(mock.cancelledItems.first?.content == "Test")
    }

    @Test("Mock notification manager tracks cancel all notifications")
    @MainActor
    func testCancelAllNotifications() {
        let mock = MockNotificationManager()
        #expect(mock.allNotificationsCancelled == false)

        mock.cancelAllNotifications()
        #expect(mock.allNotificationsCancelled == true)
    }

    @Test("Mock notification manager tracks delegate setup")
    @MainActor
    func testDelegateSetup() {
        let mock = MockNotificationManager()
        #expect(mock.delegateSetup == false)

        mock.setupDelegate()
        #expect(mock.delegateSetup == true)
    }

    @Test("Mock notification manager tracks logging requests")
    @MainActor
    func testLogPendingNotifications() {
        let mock = MockNotificationManager()
        #expect(mock.loggingRequested == false)

        mock.logPendingNotifications()
        #expect(mock.loggingRequested == true)
    }
}

// MARK: - RecallListViewModel Tests

@Suite("RecallListViewModel Tests")
@MainActor
struct RecallListViewModelTests {

    @Test("ViewModel initialization loads items from persistence")
    func testInitializationLoadsItems() {
        let mockPersistence = MockPersistenceManager()
        mockPersistence.itemsToLoad = [
            RecallItem(content: "Item 1"),
            RecallItem(content: "Item 2")
        ]

        let viewModel = RecallListViewModel(
            notificationManager: MockNotificationManager(),
            persistenceManager: mockPersistence
        )

        #expect(viewModel.items.count == 2)
        #expect(mockPersistence.loadCallCount == 1)
    }

    @Test("Adding item inserts at beginning of array")
    func testAddItemInsertsAtBeginning() {
        let mockPersistence = MockPersistenceManager()
        mockPersistence.itemsToLoad = [RecallItem(content: "Existing")]

        let viewModel = RecallListViewModel(
            notificationManager: MockNotificationManager(),
            persistenceManager: mockPersistence
        )

        viewModel.addItem(content: "New Item")

        #expect(viewModel.items.count == 2)
        #expect(viewModel.items.first?.content == "New Item")
    }

    @Test("Adding item ignores empty content")
    func testAddItemIgnoresEmptyContent() {
        let mockPersistence = MockPersistenceManager()
        let viewModel = RecallListViewModel(
            notificationManager: MockNotificationManager(),
            persistenceManager: mockPersistence
        )

        viewModel.addItem(content: "")

        #expect(viewModel.items.isEmpty)
    }

    @Test("Adding item schedules notifications")
    func testAddItemSchedulesNotifications() {
        let mockNotifications = MockNotificationManager()
        let mockPersistence = MockPersistenceManager()

        let viewModel = RecallListViewModel(
            notificationManager: mockNotifications,
            persistenceManager: mockPersistence
        )

        viewModel.addItem(content: "Test")

        #expect(mockNotifications.scheduledNotifications.count == 1)
        #expect(mockNotifications.scheduledNotifications.first?.dates.count == 11)
    }

    @Test("Adding item triggers save")
    func testAddItemTriggersSave() {
        let mockPersistence = MockPersistenceManager()
        let viewModel = RecallListViewModel(
            notificationManager: MockNotificationManager(),
            persistenceManager: mockPersistence
        )

        let initialSaveCount = mockPersistence.saveCallCount
        viewModel.addItem(content: "Test")

        #expect(mockPersistence.saveCallCount > initialSaveCount)
        #expect(mockPersistence.savedItems.count == 1)
    }

    @Test("Delete removes items at correct offsets")
    func testDeleteRemovesItems() {
        let mockPersistence = MockPersistenceManager()
        mockPersistence.itemsToLoad = [
            RecallItem(content: "First"),
            RecallItem(content: "Second"),
            RecallItem(content: "Third")
        ]

        let viewModel = RecallListViewModel(
            notificationManager: MockNotificationManager(),
            persistenceManager: mockPersistence
        )

        viewModel.delete(at: IndexSet([1])) // Delete "Second"

        #expect(viewModel.items.count == 2)
        #expect(viewModel.items[0].content == "First")
        #expect(viewModel.items[1].content == "Third")
    }

    @Test("Delete cancels notifications for deleted items")
    func testDeleteCancelsNotifications() {
        let mockNotifications = MockNotificationManager()
        let mockPersistence = MockPersistenceManager()
        mockPersistence.itemsToLoad = [RecallItem(content: "Test")]

        let viewModel = RecallListViewModel(
            notificationManager: mockNotifications,
            persistenceManager: mockPersistence
        )

        viewModel.delete(at: IndexSet([0]))

        #expect(mockNotifications.cancelledItems.count == 1)
        #expect(mockNotifications.cancelledItems.first?.content == "Test")
    }

    @Test("getReminderDates returns 11 dates")
    func testGetReminderDates() {
        let viewModel = RecallListViewModel(
            notificationManager: MockNotificationManager(),
            persistenceManager: MockPersistenceManager()
        )

        let item = RecallItem(content: "Test")
        let dates = viewModel.getReminderDates(for: item)

        #expect(dates.count == 11)
    }

    @Test("getNextReminderDate returns first future date")
    func testGetNextReminderDateReturnsFutureDate() {
        let viewModel = RecallListViewModel(
            notificationManager: MockNotificationManager(),
            persistenceManager: MockPersistenceManager()
        )

        let item = RecallItem(content: "Test", createdAt: Date())
        let nextDate = viewModel.getNextReminderDate(for: item)

        #expect(nextDate != nil)
        #expect(nextDate! > Date())
    }

    @Test("getNextReminderDate returns nil when all dates have passed")
    func testGetNextReminderDateReturnsNilForPastDates() {
        let viewModel = RecallListViewModel(
            notificationManager: MockNotificationManager(),
            persistenceManager: MockPersistenceManager()
        )

        // Item created 3 years ago - all reminders should be in the past
        let oldDate = Date().addingTimeInterval(-94608000) // 3 years ago
        let item = RecallItem(content: "Test", createdAt: oldDate)
        let nextDate = viewModel.getNextReminderDate(for: item)

        #expect(nextDate == nil)
    }

    @Test("requestNotificationPermission delegates to notification manager")
    func testRequestNotificationPermission() {
        let mockNotifications = MockNotificationManager()
        let viewModel = RecallListViewModel(
            notificationManager: mockNotifications,
            persistenceManager: MockPersistenceManager()
        )

        viewModel.requestNotificationPermission()

        #expect(mockNotifications.authorizationRequested == true)
    }

    @Test("cancelAllPendingNotifications delegates to notification manager")
    func testCancelAllPendingNotifications() {
        let mockNotifications = MockNotificationManager()
        let viewModel = RecallListViewModel(
            notificationManager: mockNotifications,
            persistenceManager: MockPersistenceManager()
        )

        viewModel.cancelAllPendingNotifications()

        #expect(mockNotifications.allNotificationsCancelled == true)
    }

    @Test("logAllPendingNotifications delegates to notification manager")
    func testLogAllPendingNotifications() {
        let mockNotifications = MockNotificationManager()
        let viewModel = RecallListViewModel(
            notificationManager: mockNotifications,
            persistenceManager: MockPersistenceManager()
        )

        viewModel.logAllPendingNotifications()

        #expect(mockNotifications.loggingRequested == true)
    }
}

// MARK: - Integration Tests

@Suite("Integration Tests")
@MainActor
struct IntegrationTests {

    @Test("End-to-end flow: Add item, verify persistence and notifications")
    func testEndToEndAddItemFlow() {
        let mockNotifications = MockNotificationManager()
        let mockPersistence = MockPersistenceManager()

        // Create ViewModel
        let viewModel = RecallListViewModel(
            notificationManager: mockNotifications,
            persistenceManager: mockPersistence
        )

        // Add an item
        viewModel.addItem(content: "Learn Swift Testing")

        // Verify item was added
        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.content == "Learn Swift Testing")

        // Verify persistence was called
        #expect(mockPersistence.saveCallCount > 0)
        #expect(mockPersistence.savedItems.count == 1)

        // Verify notifications were scheduled
        #expect(mockNotifications.scheduledNotifications.count == 1)
        #expect(mockNotifications.scheduledNotifications.first?.dates.count == 11)
    }

    @Test("End-to-end flow: Add item and delete it")
    func testEndToEndAddAndDeleteFlow() {
        let mockNotifications = MockNotificationManager()
        let mockPersistence = MockPersistenceManager()

        let viewModel = RecallListViewModel(
            notificationManager: mockNotifications,
            persistenceManager: mockPersistence
        )

        // Add item
        viewModel.addItem(content: "Temporary item")
        #expect(viewModel.items.count == 1)

        // Delete item
        viewModel.delete(at: IndexSet([0]))

        // Verify item was removed
        #expect(viewModel.items.isEmpty)

        // Verify notifications were cancelled
        #expect(mockNotifications.cancelledItems.count == 1)

        // Verify persistence was updated
        #expect(mockPersistence.savedItems.isEmpty)
    }

    @Test("End-to-end flow: Load existing items on initialization")
    func testEndToEndLoadExistingItems() {
        let mockPersistence = MockPersistenceManager()
        mockPersistence.itemsToLoad = [
            RecallItem(content: "Existing 1"),
            RecallItem(content: "Existing 2"),
            RecallItem(content: "Existing 3")
        ]

        let viewModel = RecallListViewModel(
            notificationManager: MockNotificationManager(),
            persistenceManager: mockPersistence
        )

        // Verify items were loaded
        #expect(viewModel.items.count == 3)
        #expect(viewModel.items[0].content == "Existing 1")
        #expect(viewModel.items[1].content == "Existing 2")
        #expect(viewModel.items[2].content == "Existing 3")
    }

    @Test("End-to-end flow: Multiple operations maintain consistency")
    func testEndToEndMultipleOperations() {
        let mockNotifications = MockNotificationManager()
        let mockPersistence = MockPersistenceManager()

        let viewModel = RecallListViewModel(
            notificationManager: mockNotifications,
            persistenceManager: mockPersistence
        )

        // Add multiple items
        viewModel.addItem(content: "First")
        viewModel.addItem(content: "Second")
        viewModel.addItem(content: "Third")

        #expect(viewModel.items.count == 3)
        #expect(mockNotifications.scheduledNotifications.count == 3)

        // Delete middle item
        viewModel.delete(at: IndexSet([1]))

        #expect(viewModel.items.count == 2)
        #expect(viewModel.items[0].content == "Third") // Most recent
        #expect(viewModel.items[1].content == "First") // Oldest

        // Add another item
        viewModel.addItem(content: "Fourth")

        #expect(viewModel.items.count == 3)
        #expect(viewModel.items.first?.content == "Fourth")
    }

    @Test("End-to-end flow: Reminder dates calculation for new item")
    func testEndToEndReminderDatesCalculation() {
        let viewModel = RecallListViewModel(
            notificationManager: MockNotificationManager(),
            persistenceManager: MockPersistenceManager()
        )

        viewModel.addItem(content: "Test reminder dates")

        let item = viewModel.items.first!
        let reminderDates = viewModel.getReminderDates(for: item)

        // Verify 11 reminder dates
        #expect(reminderDates.count == 11)

        // Verify dates are in the future
        let nextReminder = viewModel.getNextReminderDate(for: item)
        #expect(nextReminder != nil)
        #expect(nextReminder! > Date())

        // Verify dates are chronologically ordered
        for i in 0..<(reminderDates.count - 1) {
            #expect(reminderDates[i] < reminderDates[i + 1])
        }
    }
}
