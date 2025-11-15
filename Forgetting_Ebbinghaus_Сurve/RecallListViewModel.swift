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
    
    // --- НОВЫЙ МЕТОД ---
    // Безопасно удаляет элементы по указанным индексам
    // и отменяет связанные с ними уведомления.
    func delete(at offsets: IndexSet) {
        // Сначала получаем элементы, которые будут удалены.
        let itemsToDelete = offsets.map { items[$0] }
        
        // Для каждого из них отменяем запланированные уведомления.
        itemsToDelete.forEach { item in
            notificationManager.cancelNotifications(for: item)
        }
        
        // Наконец, удаляем сами элементы из нашего массива.
        items.remove(atOffsets: offsets)
    }
    
    // --- Старые методы (без изменений) ---
    
    func requestNotificationPermission() {
        notificationManager.requestAuthorization()
    }
    
    func addItem(content: String) {
        guard !content.isEmpty else { return }
        
        let newItem = RecallItem(content: content)
        items.insert(newItem, at: 0)

        let reminderDates = ForgettingCurve.reminderDates(from: newItem.createdAt)
        notificationManager.scheduleNotifications(for: newItem, on: reminderDates)
    }
    
    func getReminderDates(for item: RecallItem) -> [Date] {
        return ForgettingCurve.reminderDates(from: item.createdAt)
    }
    
    func getNextReminderDate(for item: RecallItem) -> Date? {
        let allDates = ForgettingCurve.reminderDates(from: item.createdAt)
        return allDates.first(where: { $0 > Date() })
    }
    
    func cancelAllPendingNotifications() {
        notificationManager.cancelAllNotifications()
    }
    
    func logAllPendingNotifications() {
        notificationManager.logPendingNotifications()
    }
}
