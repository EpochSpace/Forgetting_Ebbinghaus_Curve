//
//  NotificationManager.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 05.11.2025.
//

import Foundation
import UserNotifications

// Protocol for dependency injection and testing
protocol NotificationManagerProtocol {
    func setupDelegate()
    func requestAuthorization()
    func scheduleNotifications(for item: RecallItem, on dates: [Date])
    func cancelAllNotifications()
    func cancelNotifications(for item: RecallItem)
    func logPendingNotifications()
}

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, NotificationManagerProtocol {
    
    static let shared = NotificationManager()
    
    override private init() {
        super.init()
    }
    
    func setupDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
            if let error = error {
                print("NOTIFICATION ERROR: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(success)")
            }
        }
    }
    
    func scheduleNotifications(for item: RecallItem, on dates: [Date]) {
        for date in dates {
            let content = UNMutableNotificationContent()
            content.title = "Time to recall!"
            content.body = item.content
            content.sound = .default
            
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let requestIdentifier = "\(item.id.uuidString)-\(date.timeIntervalSince1970)"
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
        print("Scheduled \(dates.count) notifications for '\(item.content)'")
    }

    // --- НОВЫЙ МЕТОД №1: ОТМЕНА ВСЕХ УВЕДОМЛЕНИЙ ---
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All pending notifications have been cancelled.")
    }

    // --- НОВЫЙ МЕТОД №2: ОТМЕНА УВЕДОМЛЕНИЙ ДЛЯ ОДНОГО ЭЛЕМЕНТА ---
    func cancelNotifications(for item: RecallItem) {
        let itemIdentifierPrefix = item.id.uuidString
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(itemIdentifierPrefix) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("Cancelled \(identifiersToRemove.count) notifications for item '\(item.content)'")
        }
    }

    // --- НОВЫЙ МЕТОД №3: ВЫВОД СПИСКА В КОНСОЛЬ ---
    func logPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            DispatchQueue.main.async {
                print("\n--- PENDING NOTIFICATIONS (\(requests.count)) ---")
                if requests.isEmpty {
                    print("None.\n")
                } else {
                    for request in requests.sorted(by: { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date.distantFuture < ($1.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date.distantFuture }) {
                        print("ID: \(request.identifier)")
                        print("   Body: \(request.content.body)")
                        if let trigger = request.trigger as? UNCalendarNotificationTrigger, let date = trigger.nextTriggerDate() {
                            print("   Trigger Date: \(date.formatted(.dateTime.year().month().day().hour().minute().second()))")
                        }
                        print("--------------------")
                    }
                }
            }
        }
    }
}
