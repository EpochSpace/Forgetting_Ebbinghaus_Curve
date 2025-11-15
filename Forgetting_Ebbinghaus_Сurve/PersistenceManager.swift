//
//  PersistenceManager.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 11.11.2025.
//

import Foundation

// Protocol for dependency injection and testing
protocol PersistenceManagerProtocol {
    func loadItems() -> [RecallItem]
    func saveItems(_ items: [RecallItem])
}

// A dedicated manager for saving and loading data.
final class PersistenceManager: PersistenceManagerProtocol {
    
    static let shared = PersistenceManager()
    private init() {}
    
    // Defines the path to the file where we'll store our data.
    private var dataURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("recall_items.json")
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
    
    // Saves the array of items to the JSON file.
    func saveItems(_ items: [RecallItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: dataURL, options: .atomic)
            print("Successfully saved \(items.count) items to disk.")
        } catch {
            print("Failed to save items: \(error.localizedDescription)")
        }
    }
}
