//
//  IndividualFlashcardReviewView.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac
//

import SwiftUI

/// Individual flashcard review view with statistics
/// Observes viewModel to show updated statistics after each review
struct IndividualFlashcardReviewView: View {
    @ObservedObject var viewModel: RecallListViewModel
    let flashcardId: UUID
    @Environment(\.colorScheme) var colorScheme

    // Look up current flashcard from viewModel to get live updates
    private var flashcard: FlashcardItem? {
        viewModel.flashcardItems.first(where: { $0.id == flashcardId })
    }

    var body: some View {
        Group {
            if let flashcard = flashcard {
                ScrollView {
                    VStack {
                        FlashcardDetailView(
                            flashcard: flashcard,
                            onReview: { difficulty in
                                viewModel.recordReview(flashcardId: flashcard.id, difficulty: difficulty)
                            },
                            useCompactLayout: true
                        )

                        // Review statistics
                        if flashcard.studyProgress.totalReviews > 0 {
                            Divider()
                                .padding(.vertical)

                            reviewStatsView(for: flashcard)
                                .padding()
                        }
                    }
                }
            } else {
                // Fallback if flashcard not found
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)

                    Text("Flashcard not found")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Review Flashcard")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Review Statistics View

    @ViewBuilder
    private func reviewStatsView(for flashcard: FlashcardItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Statistics")
                .font(.headline)

            HStack(spacing: 32) {
                StatItem(
                    label: "Total Reviews",
                    value: "\(flashcard.studyProgress.totalReviews)",
                    color: .secondary
                )

                StatItem(
                    label: "Easy",
                    value: "\(flashcard.studyProgress.easyCount)",
                    color: Color.statusGreen
                )

                StatItem(
                    label: "Good",
                    value: "\(flashcard.studyProgress.goodCount)",
                    color: Color.statusYellow
                )

                StatItem(
                    label: "Hard",
                    value: "\(flashcard.studyProgress.hardCount)",
                    color: Color.statusRed
                )
            }

            HStack {
                Text("Interval Multiplier:")
                    .foregroundStyle(.secondary)
                Text("\(String(format: "%.2f", flashcard.studyProgress.currentIntervalMultiplier))x")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentPrimary)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.adaptiveSurfaceElevated(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview("Individual Review") {
    PreviewContainer()
}

/// Helper view for preview setup
private struct PreviewContainer: View {
    @StateObject private var viewModel = RecallListViewModel()
    @State private var flashcardId: UUID?

    var body: some View {
        NavigationStack {
            if let flashcardId = flashcardId {
                IndividualFlashcardReviewView(viewModel: viewModel, flashcardId: flashcardId)
            } else {
                Text("Loading...")
                    .onAppear {
                        // Add flashcard using the viewModel's method
                        viewModel.addFlashcard(
                            frontContent: "What is the capital of France?",
                            backContent: "Paris is the capital and most populous city of France.",
                            manualCategory: .short
                        )

                        // Get the flashcard that was just added
                        flashcardId = viewModel.flashcardItems.first?.id
                    }
            }
        }
    }
}
