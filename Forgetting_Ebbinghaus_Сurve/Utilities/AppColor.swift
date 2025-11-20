//
//  AppColor.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac
//

import SwiftUI

/// Centralized color palette matching the demo design
/// Provides semantic colors for consistent theming across the app
extension Color {

    // MARK: - Primary Brand Colors

    /// Primary accent color - Indigo (#5856d6)
    static let accentPrimary = Color(red: 0.345, green: 0.337, blue: 0.839)

    // MARK: - Status Colors (matching demo design)

    /// Red for "Hard" difficulty and critical alerts (#ef4444)
    static let statusRed = Color(red: 0.937, green: 0.267, blue: 0.267)

    /// Yellow for "Good" difficulty and warnings (#eab308)
    static let statusYellow = Color(red: 0.918, green: 0.702, blue: 0.031)

    /// Green for "Easy" difficulty and success states (#22c55e)
    static let statusGreen = Color(red: 0.133, green: 0.773, blue: 0.369)

    /// Blue for tags, categories, and informational elements (#3b82f6)
    static let statusBlue = Color(red: 0.231, green: 0.510, blue: 0.965)

    // MARK: - Gradient Colors

    /// Background gradient start (#667eea)
    static let gradientStart = Color(red: 0.400, green: 0.494, blue: 0.918)

    /// Background gradient end (#764ba2)
    static let gradientEnd = Color(red: 0.463, green: 0.294, blue: 0.635)

    // MARK: - Surface Colors (Light Mode)

    /// Primary surface color (white in light mode)
    static let surfacePrimary = Color.white

    /// Elevated surface color (#f5f5f7 in light mode)
    static let surfaceElevated = Color(red: 0.961, green: 0.961, blue: 0.969)

    // MARK: - Surface Colors (Dark Mode)

    /// Primary surface color in dark mode (#1c1c1e)
    static let surfacePrimaryDark = Color(red: 0.110, green: 0.110, blue: 0.118)

    /// Elevated surface color in dark mode (#2c2c2e)
    static let surfaceElevatedDark = Color(red: 0.173, green: 0.173, blue: 0.180)

    /// Secondary surface for cards (#1f2937 - gray-800 from demo)
    static let surfaceCardDark = Color(red: 0.122, green: 0.161, blue: 0.216)

    // MARK: - Border Colors

    /// Subtle border in light mode
    static let borderLight = Color(white: 0.0, opacity: 0.1)

    /// Subtle border in dark mode
    static let borderDark = Color(white: 1.0, opacity: 0.1)

    /// Card border in dark mode (gray-700)
    static let borderCardDark = Color(red: 0.157, green: 0.196, blue: 0.275)

    // MARK: - Helper Methods

    /// Returns appropriate surface color based on color scheme
    static func adaptiveSurface(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? surfacePrimaryDark : surfacePrimary
    }

    /// Returns appropriate elevated surface color based on color scheme
    static func adaptiveSurfaceElevated(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? surfaceElevatedDark : surfaceElevated
    }

    /// Returns appropriate border color based on color scheme
    static func adaptiveBorder(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? borderDark : borderLight
    }

    /// Returns semi-transparent version of color (demo uses /10, /20, /30 opacity)
    func opacity(_ opacity: Int) -> Color {
        self.opacity(Double(opacity) / 100.0)
    }
}

// MARK: - Gradient Definitions

extension LinearGradient {
    /// Background gradient from demo design
    static let appBackground = LinearGradient(
        colors: [.gradientStart, .gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
