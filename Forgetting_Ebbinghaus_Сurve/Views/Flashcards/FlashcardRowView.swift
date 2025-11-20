//
//  FlashcardRowView.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac
//

import SwiftUI
import Combine

/// List row view for displaying a flashcard preview
/// Shows front content, category, stats, and next review timer
struct FlashcardRowView: View {
    let flashcard: FlashcardItem
    let nextReminderDate: Date?

    @State private var timeRemainingString: String = "Loading..."
    @State private var timerCancellable: AnyCancellable?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Front content preview with icon
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(Color.statusBlue)
                    .font(.title3)

                Text(flashcard.frontContent)
                    .font(.headline)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Category badge and metadata
            HStack(spacing: 6) {
                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: flashcard.textCategory.icon)
                        .font(.caption2)
                    Text(flashcard.textCategory.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.statusBlue.opacity(0.2))
                .foregroundStyle(Color.statusBlue)
                .clipShape(Capsule())

                Text("•")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                Text("\(flashcard.characterCount) chars")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Review count if any
                if flashcard.studyProgress.totalReviews > 0 {
                    Text("•")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption2)
                        Text("\(flashcard.studyProgress.totalReviews)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Next review timer
            if let nextDate = nextReminderDate {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Next review: \(timeRemainingString)")
                        .font(.caption.monospaced())
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Flashcard: \(flashcard.frontContent)")
        .accessibilityValue(accessibilityValueString)
        .accessibilityHint("Double tap to review this flashcard")
    }

    // MARK: - Accessibility

    /// Provides dynamic accessibility value combining category, stats, and next review time
    private var accessibilityValueString: String {
        var components: [String] = []

        // Category
        components.append("\(flashcard.textCategory.displayName) category")

        // Review count
        if flashcard.studyProgress.totalReviews > 0 {
            components.append("Reviewed \(flashcard.studyProgress.totalReviews) times")
        } else {
            components.append("Not yet reviewed")
        }

        // Next review time
        components.append("Next review: \(timeRemainingString)")

        return components.joined(separator: ", ")
    }

    // MARK: - Timer Lifecycle

    /// Starts the countdown timer for the next review
    private func startTimer() {
        guard let nextDate = nextReminderDate else {
            timeRemainingString = "Ready to review!"
            return
        }

        // Update immediately
        updateTimeRemaining(to: nextDate)

        // Start timer for updates every second
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [nextDate] _ in
                updateTimeRemaining(to: nextDate)
            }
    }

    /// Stops and cancels the countdown timer to prevent memory leaks
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Helper Methods

    private func updateTimeRemaining(to date: Date) {
        let now = Date()

        if date <= now {
            timeRemainingString = "Ready to review!"
            return
        }

        let interval = date.timeIntervalSince(now)
        timeRemainingString = interval.formattedForCountdown()
    }
}

// MARK: - Preview
#Preview("Flashcard Row - New") {
    List {
        FlashcardRowView(
            flashcard: FlashcardItem(
                frontContent: "What is the capital of France?",
                backContent: "Paris is the capital and most populous city of France.",
                textCategory: .short
            ),
            nextReminderDate: Date().addingTimeInterval(3600)
        )
    }
}

#Preview("Flashcard Row - Reviewed") {
    var flashcard = FlashcardItem(
        frontContent: "Explain the Ebbinghaus forgetting curve in detail",
        backContent: "The Ebbinghaus forgetting curve illustrates the decline of memory retention over time. It shows that information is lost over time when there is no attempt to retain it.",
        textCategory: .long
    )
    flashcard.studyProgress.totalReviews = 5
    flashcard.studyProgress.easyCount = 3
    flashcard.studyProgress.goodCount = 2

    return List {
        FlashcardRowView(
            flashcard: flashcard,
            nextReminderDate: Date().addingTimeInterval(86400)
        )
    }
}
