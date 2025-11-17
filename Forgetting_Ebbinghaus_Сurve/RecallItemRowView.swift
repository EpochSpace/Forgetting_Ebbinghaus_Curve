//
//  RecallItemRowView.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 05.11.2025.
//

import SwiftUI
import Combine

struct RecallItemRowView: View {
    let item: RecallItem
    let reminderDates: [Date]
    /// The specific date for countdown display
    let nextReminderDate: Date?

    @State private var timeRemainingString: String = "Loading..."
    @State private var timerCancellable: AnyCancellable?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content with category badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.content)
                        .font(.headline)

                    // Category badge with icon
                    HStack(spacing: 4) {
                        Image(systemName: item.textCategory.icon)
                            .font(.caption2)
                        Text(item.textCategory.displayName)
                            .font(.caption)

                        if item.isManuallyOverridden {
                            Image(systemName: "hand.tap.fill")
                                .font(.caption2)
                                .help("Manually adjusted")
                        }

                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text("\(item.characterCount) chars")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Timer display
            if nextReminderDate != nil {
                Text("Next recall in: \(timeRemainingString)")
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
            } else {
                 Text("All recalls complete!")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            
            DisclosureGroup("All reminders") {
                VStack(alignment: .leading) {
                    ForEach(reminderDates, id: \.self) { date in
                        Text(date.formatted(.dateTime.day().month().year().hour().minute().second()))
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.caption)
        }
        .padding(.vertical, 8)
        .onAppear {
            startTimerIfNeeded()
        }
        .onDisappear {
            cancelTimer()
        }
    }

    // MARK: - Helper Methods

    /// Starts the timer if there's a next reminder date to count down to
    private func startTimerIfNeeded() {
        // Only start timer if there's an upcoming reminder
        guard nextReminderDate != nil else {
            timeRemainingString = "N/A"
            return
        }

        // Set initial value
        updateRemainingTime()

        // Start the repeating timer
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                updateRemainingTime()
            }
    }

    /// Cancels the timer to prevent memory leaks
    private func cancelTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Updates the countdown timer display
    private func updateRemainingTime() {
        guard let date = nextReminderDate else {
            timeRemainingString = "N/A"
            cancelTimer() // Stop timer if no date
            return
        }

        let remaining = date.timeIntervalSince(Date())

        // If the reminder has passed, stop the timer
        if remaining < 0 {
            timeRemainingString = "Overdue"
            cancelTimer()
            return
        }

        timeRemainingString = remaining.formattedForCountdown()
    }
}
