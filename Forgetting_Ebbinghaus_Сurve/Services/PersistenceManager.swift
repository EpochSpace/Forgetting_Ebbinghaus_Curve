//
//  PersistenceManager.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 11.11.2025.
//

import Foundation

/// Errors that can occur during persistence operations
enum PersistenceError: Error, LocalizedError {
    case loadFailed(String)
    case saveFailed(String)
    case dataCorruption(String)

    var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Failed to load data: \(message)"
        case .saveFailed(let message):
            return "Failed to save data: \(message)"
        case .dataCorruption(let message):
            return "Data corruption detected: \(message)"
        }
    }
}

// Protocol for dependency injection and testing
protocol PersistenceManagerProtocol {
    func loadItems() -> [RecallItem]
    func saveItems(_ items: [RecallItem])
    func loadFlashcards() -> [FlashcardItem]
    func saveFlashcards(_ flashcards: [FlashcardItem])
}

/// Notification names for persistence errors
extension Notification.Name {
    static let persistenceSaveFailed = Notification.Name("persistenceSaveFailed")
    static let persistenceLoadFailed = Notification.Name("persistenceLoadFailed")
}

// A dedicated manager for saving and loading data.
final class PersistenceManager: PersistenceManagerProtocol {
    
    static let shared = PersistenceManager()
    private init() {}
    
    // Defines the path to the file where we'll store recall items.
    private var dataURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("recall_items.json")
    }

    // Defines the path to the file where we'll store flashcards.
    private var flashcardsURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("flashcard_items.json")
    }
    
    // Loads the array of items from the JSON file.
    func loadItems() -> [RecallItem] {
        // Use do-catch for robust error handling.
        do {
            let data = try Data(contentsOf: dataURL)
            let items = try JSONDecoder().decode([RecallItem].self, from: data)
            print("Successfully loaded \(items.count) items from disk.")
            return items
        } catch {
            // If the file doesn't exist or there's a decoding error, return an empty array.
            print("Failed to load items: \(error.localizedDescription). Returning empty array.")
            return []
        }
    }
    
    // Saves the array of items to the JSON file with atomic write and error recovery.
    func saveItems(_ items: [RecallItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            let tempURL = dataURL.appendingPathExtension("tmp")

            // Write to temporary file first (atomic operation)
            try data.write(to: tempURL, options: .atomic)

            // Only replace original if temp write succeeded
            if FileManager.default.fileExists(atPath: dataURL.path) {
                // Create backup before replacing
                let backupURL = dataURL.appendingPathExtension("backup")
                try? FileManager.default.removeItem(at: backupURL)
                try? FileManager.default.copyItem(at: dataURL, to: backupURL)
            }

            // Replace with new file
            _ = try? FileManager.default.replaceItemAt(dataURL, withItemAt: tempURL)

            print("Successfully saved \(items.count) items to disk.")
        } catch {
            print("❌ CRITICAL: Failed to save items: \(error.localizedDescription)")

            // Notify observers of save failure
            NotificationCenter.default.post(
                name: .persistenceSaveFailed,
                object: nil,
                userInfo: ["error": error.localizedDescription, "type": "items"]
            )
        }
    }

    // MARK: - Flashcard Persistence

    // Loads the array of flashcards from the JSON file.
    func loadFlashcards() -> [FlashcardItem] {
        do {
            let data = try Data(contentsOf: flashcardsURL)
            let flashcards = try JSONDecoder().decode([FlashcardItem].self, from: data)
            print("Successfully loaded \(flashcards.count) flashcards from disk.")
            return flashcards
        } catch {
            // If the file doesn't exist or there's a decoding error, return an empty array.
            print("Failed to load flashcards: \(error.localizedDescription). Returning empty array.")
            return []
        }
    }

    // Saves the array of flashcards to the JSON file with atomic write and error recovery.
    func saveFlashcards(_ flashcards: [FlashcardItem]) {
        do {
            let data = try JSONEncoder().encode(flashcards)
            let tempURL = flashcardsURL.appendingPathExtension("tmp")

            // Write to temporary file first (atomic operation)
            try data.write(to: tempURL, options: .atomic)

            // Only replace original if temp write succeeded
            if FileManager.default.fileExists(atPath: flashcardsURL.path) {
                // Create backup before replacing
                let backupURL = flashcardsURL.appendingPathExtension("backup")
                try? FileManager.default.removeItem(at: backupURL)
                try? FileManager.default.copyItem(at: flashcardsURL, to: backupURL)
            }

            // Replace with new file
            _ = try? FileManager.default.replaceItemAt(flashcardsURL, withItemAt: tempURL)

            print("Successfully saved \(flashcards.count) flashcards to disk.")
        } catch {
            print("❌ CRITICAL: Failed to save flashcards: \(error.localizedDescription)")

            // Notify observers of save failure
            NotificationCenter.default.post(
                name: .persistenceSaveFailed,
                object: nil,
                userInfo: ["error": error.localizedDescription, "type": "flashcards"]
            )
        }
    }
}

// MARK: - Security Notice

/*
 ⚠️ SECURITY NOTICE ⚠️

 Data stored by PersistenceManager is saved in PLAIN TEXT JSON format in the app's
 Documents directory. This means:

 - On jailbroken devices, files may be readable by other apps
 - Device backups (iCloud, iTunes) will contain unencrypted data
 - Users storing sensitive information (passwords, personal notes) should be aware

 RECOMMENDATIONS:
 1. Add disclaimer in app settings/about screen
 2. Consider implementing optional encryption using CryptoKit for sensitive data
 3. Use Keychain for truly sensitive information (passwords, tokens)
 4. Educate users not to store highly sensitive data in flashcards

 Future enhancement: Add a "Encrypt data" toggle in Settings that uses AES-GCM
 encryption for all persisted data.
 */

