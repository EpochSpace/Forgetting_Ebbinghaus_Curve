//
//  NightWindow.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 16.11.2025.
//

import Foundation

/// Manages the fixed night window (22:00 - 07:00) for smart notification timing.
struct NightWindow {

    /// The fixed night start hour (22:00 / 10 PM)
    static let nightStartHour = 22

    /// The fixed morning wake hour (07:00 / 7 AM)
    static let morningWakeHour = 7

    /// Checks if the given date falls within the night window (22:00 - 07:00).
    /// - Parameter date: The date to check
    /// - Returns: True if the date is during night time, false otherwise
    static func isDateInNightWindow(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        // Night window is from 22:00 to 07:00
        // This means hour >= 22 OR hour < 7
        return hour >= nightStartHour || hour < morningWakeHour
    }

    /// Returns the next morning wake time (7 AM) after the given date.
    /// If the date is before 7 AM, returns 7 AM on the same day.
    /// If the date is at or after 7 AM, returns 7 AM on the next day.
    /// - Parameter date: The reference date
    /// - Returns: The next 7 AM date
    static func nextMorningWakeTime(after date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        // Get 7 AM on the same day
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = morningWakeHour
        components.minute = 0
        components.second = 0

        guard let morningToday = calendar.date(from: components) else {
            return date
        }

        // If current time is before 7 AM, return today's 7 AM
        // Otherwise, return tomorrow's 7 AM
        if hour < morningWakeHour {
            return morningToday
        } else {
            return calendar.date(byAdding: .day, value: 1, to: morningToday) ?? morningToday
        }
    }

    /// Detects the user's region based on their timezone for context-aware messaging.
    /// - Returns: A user-friendly region name (e.g., "Europe", "North America", "Asia")
    static func detectUserRegion() -> String {
        let timeZone = TimeZone.current
        let identifier = timeZone.identifier

        // Map timezone identifiers to broader regions
        if identifier.contains("Europe") {
            return "Europe"
        } else if identifier.contains("America") {
            if identifier.contains("North") || identifier.contains("New_York") ||
               identifier.contains("Chicago") || identifier.contains("Denver") ||
               identifier.contains("Los_Angeles") || identifier.contains("Toronto") {
                return "North America"
            } else {
                return "South America"
            }
        } else if identifier.contains("Asia") {
            return "Asia"
        } else if identifier.contains("Africa") {
            return "Africa"
        } else if identifier.contains("Australia") || identifier.contains("Pacific") {
            return "Oceania"
        } else {
            // Default fallback
            return "your region"
        }
    }

    /// Calculates the 7 AM wake time on the same day as the given date.
    /// - Parameter date: The reference date
    /// - Returns: 7 AM on the same calendar day
    static func morningWakeTime(onSameDayAs date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = morningWakeHour
        components.minute = 0
        components.second = 0

        return calendar.date(from: components) ?? date
    }
}
