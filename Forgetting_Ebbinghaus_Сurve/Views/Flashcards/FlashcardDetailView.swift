//
//  FlashcardDetailView.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac
//

import SwiftUI

/// Detailed flashcard view with flip animation and difficulty rating
/// Displays front (question) and back (answer) with 3D rotation effect
struct FlashcardDetailView: View {
    let flashcard: FlashcardItem
    let onReview: (ReviewDifficulty) -> Void
    var useCompactLayout: Bool = false

    @State private var showingBack = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            if !useCompactLayout {
                Spacer()
            }

            // Flashcard with flip animation
            ZStack {
                // Front side
                cardSide(
                    title: "Question",
                    content: flashcard.frontContent,
                    showHint: true
                )
                .opacity(showingBack ? 0 : 1)
                .rotation3DEffect(
                    .degrees(showingBack ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )

                // Back side
                cardSide(
                    title: "Answer",
                    content: flashcard.backContent,
                    showHint: false
                )
                .opacity(showingBack ? 1 : 0)
                .rotation3DEffect(
                    .degrees(showingBack ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
            }
            .frame(maxWidth: 500, minHeight: 400, maxHeight: 450)
            .onTapGesture {
                flipCard()
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(showingBack ? "Answer: \(flashcard.backContent)" : "Question: \(flashcard.frontContent)")
            .accessibilityHint(showingBack ? "Double tap to show question" : "Double tap to reveal answer")
            .accessibilityAddTraits(.isButton)

            if !useCompactLayout {
                Spacer()
            }

            // Difficulty buttons (show only after revealing answer)
            if showingBack {
                difficultyButtons
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding()
            } else {
                // Placeholder to maintain layout
                Color.clear
                    .frame(height: 100)
            }
        }
        .animation(.spring(duration: 0.6), value: showingBack)
    }

    // MARK: - Difficulty Buttons

    @ViewBuilder
    private var difficultyButtons: some View {
        #if os(macOS)
        // Horizontal layout for macOS - more compact
        HStack(spacing: 12) {
            ForEach(ReviewDifficulty.allCases.reversed(), id: \.self) { difficulty in
                difficultyButton(for: difficulty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        #else
        // Vertical/stacked layout for iOS
        VStack(spacing: 12) {
            ForEach(ReviewDifficulty.allCases.reversed(), id: \.self) { difficulty in
                difficultyButton(for: difficulty)
            }
        }
        .padding(.horizontal)
        #endif
    }

    @ViewBuilder
    private func difficultyButton(for difficulty: ReviewDifficulty) -> some View {
        Button {
            onReview(difficulty)
        } label: {
            #if os(macOS)
            // Compact macOS button
            HStack(spacing: 8) {
                Image(systemName: difficulty.icon)
                    .font(.body)

                VStack(alignment: .leading, spacing: 1) {
                    Text(difficulty.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let shortcut = keyboardShortcut(for: difficulty) {
                        Text("⌨︎ \(shortcut)")
                            .font(.caption2)
                            .opacity(0.7)
                    }
                }

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(difficulty.color.opacity(0.1))
            .foregroundStyle(difficulty.color)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(difficulty.color.opacity(0.3), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            #else
            // Full iOS button
            HStack {
                Image(systemName: difficulty.icon)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(difficulty.rawValue)
                        .font(.headline)
                    Text(difficulty.description)
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(difficulty.color.opacity(0.1))
            .foregroundStyle(difficulty.color)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(difficulty.color.opacity(0.3), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .hoverEffect(.highlight)
            #endif
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(difficulty.rawValue) difficulty")
        .accessibilityHint("Mark this flashcard as \(difficulty.description). Adjusts review interval by \(Int(difficulty.intervalMultiplier * 100))%.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Card Side View

    @ViewBuilder
    private func cardSide(title: String, content: String, showHint: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.adaptiveSurfaceElevated(colorScheme))
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.adaptiveBorder(colorScheme), lineWidth: 1)
                )

            VStack(spacing: 16) {
                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: flashcard.textCategory.icon)
                        .font(.caption)
                    Text(flashcard.textCategory.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.statusBlue.opacity(0.2))
                .foregroundStyle(Color.statusBlue)
                .clipShape(Capsule())
                .padding(.top)

                Spacer()

                // Content area
                VStack(spacing: 8) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        Text(content)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: 250)
                }

                Spacer()

                // Tap hint (only show on front)
                if showHint {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap")
                            .font(.caption2)
                        Text("Tap card to reveal answer")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
                } else {
                    // Spacer to maintain consistent height
                    Text(" ")
                        .font(.caption)
                        .padding(.bottom)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func flipCard() {
        withAnimation(.spring(duration: 0.6)) {
            showingBack.toggle()
        }
    }

    private func keyboardShortcut(for difficulty: ReviewDifficulty) -> String? {
        switch difficulty {
        case .hard: return "1"
        case .good: return "2"
        case .easy: return "3"
        }
    }
}

// MARK: - Preview
#Preview("Flashcard Detail - Question") {
    FlashcardDetailView(
        flashcard: FlashcardItem(
            frontContent: "What is the capital of France?",
            backContent: "Paris is the capital and most populous city of France, with an area of 105 square kilometres and a population of 2,148,271 residents as of 2020.",
            textCategory: .medium
        ),
        onReview: { difficulty in
            print("Reviewed as: \(difficulty.rawValue)")
        }
    )
}

#Preview("Flashcard Detail - Dark Mode") {
    FlashcardDetailView(
        flashcard: FlashcardItem(
            frontContent: "Explain the Ebbinghaus forgetting curve",
            backContent: "The Ebbinghaus forgetting curve illustrates the decline of memory retention over time. It shows that information is lost over time when there is no attempt to retain it. The curve demonstrates that the sharpest decline occurs in the first 20 minutes, and then gradually levels off.",
            textCategory: .long
        ),
        onReview: { difficulty in
            print("Reviewed as: \(difficulty.rawValue)")
        }
    )
    .preferredColorScheme(.dark)
}
