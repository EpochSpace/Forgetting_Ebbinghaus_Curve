//
//  StudySessionView.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac
//

import SwiftUI

/// Dedicated study session interface for reviewing due flashcards
/// Displays flashcards one at a time with progress tracking
struct StudySessionView: View {
    @ObservedObject var viewModel: RecallListViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var currentIndex = 0
    @State private var sessionComplete = false
    @State private var dueFlashcards: [FlashcardItem] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.adaptiveSurface(colorScheme)
                    .ignoresSafeArea()

                if sessionComplete {
                    completionView
                } else if dueFlashcards.isEmpty {
                    emptyStateView
                } else {
                    studyView
                }
            }
            .navigationTitle(sessionComplete || dueFlashcards.isEmpty ? "Study Session" : "Card \(currentIndex + 1) of \(dueFlashcards.count)")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        dismiss()
                    }
                }

                // Progress bar (only show during active study)
                if !sessionComplete && !dueFlashcards.isEmpty {
                    ToolbarItem(placement: .principal) {
                        ProgressView(value: Double(currentIndex), total: Double(dueFlashcards.count))
                            .frame(width: 150)
                            .tint(.accentPrimary)
                            .accessibilityLabel("Study progress")
                            .accessibilityValue("\(currentIndex) of \(dueFlashcards.count) flashcards reviewed")
                    }
                }
            }
            .onAppear {
                loadDueFlashcards()
            }
        }
    }

    // MARK: - Study View

    @ViewBuilder
    private var studyView: some View {
        FlashcardDetailView(
            flashcard: dueFlashcards[currentIndex],
            onReview: { difficulty in
                handleReview(difficulty)
            }
        )
    }

    // MARK: - Completion View

    @ViewBuilder
    private var completionView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.statusGreen)

            VStack(spacing: 6) {
                Text("Session Complete!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Reviewed \(dueFlashcards.count) card\(dueFlashcards.count == 1 ? "" : "s")")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .accessibilityLabel("Done with study session")
            .accessibilityHint("Double tap to exit study session")

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Study session complete")
        .accessibilityValue("Successfully reviewed \(dueFlashcards.count) flashcard\(dueFlashcards.count == 1 ? "" : "s")")
    }

    // MARK: - Empty State View

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("No Cards Due")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Check back later for more reviews!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .accessibilityLabel("Close study session")
            .accessibilityHint("Double tap to exit")

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("No flashcards due for review")
        .accessibilityHint("Check back later when flashcards are scheduled for review")
    }

    // MARK: - Helper Methods

    private func loadDueFlashcards() {
        dueFlashcards = viewModel.getDueFlashcards()
    }

    private func handleReview(_ difficulty: ReviewDifficulty) {
        // Record the review in the view model
        viewModel.recordReview(
            flashcardId: dueFlashcards[currentIndex].id,
            difficulty: difficulty
        )

        // Move to next card or complete session
        if currentIndex < dueFlashcards.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            withAnimation {
                sessionComplete = true
            }
        }
    }
}

// MARK: - Preview
#Preview("Study Session - Active") {
    let viewModel = RecallListViewModel()

    // Add some test flashcards
    viewModel.addFlashcard(
        frontContent: "What is the capital of France?",
        backContent: "Paris",
        manualCategory: .short
    )
    viewModel.addFlashcard(
        frontContent: "Explain the Ebbinghaus forgetting curve",
        backContent: "The Ebbinghaus forgetting curve illustrates the decline of memory retention over time.",
        manualCategory: .medium
    )

    return StudySessionView(viewModel: viewModel)
}

#Preview("Study Session - Dark Mode") {
    let viewModel = RecallListViewModel()

    viewModel.addFlashcard(
        frontContent: "What is SwiftUI?",
        backContent: "SwiftUI is Apple's declarative framework for building user interfaces across all Apple platforms.",
        manualCategory: .medium
    )

    return StudySessionView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}
