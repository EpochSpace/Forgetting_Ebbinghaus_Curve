//
//  TimeInterval+Formatting.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 06.11.2025.
//

import Foundation

// A modular extension to format a time interval into a countdown string.
extension TimeInterval {
    
    func formattedForCountdown() -> String {
        // If the time has passed, show a clear message.
        guard self > 0 else {
            return "Done!"
        }

        let totalSeconds = Int(self)
        
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if days > 0 {
            // For longer periods, showing days is more useful.
            return String(format: "%d day(s), %02d:%02d:%02d", days, hours, minutes, seconds)
        } else {
            // For periods less than a day, show HH:MM:SS.
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
}
