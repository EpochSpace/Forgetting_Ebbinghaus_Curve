//
//  FlashcardListView.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac
//

import SwiftUI

/// Main list view for displaying all flashcards with filtering and actions
struct FlashcardListView: View {
    @ObservedObject var viewModel: RecallListViewModel
    @Environment(\.colorScheme) var colorScheme

    @State private var showingStudySession = false
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var selection = Set<FlashcardItem.ID>()

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case dueToday = "Due Today"
        case short = "Short"
        case medium = "Medium"
        case long = "Long"
    }

    var filteredFlashcards: [FlashcardItem] {
        var result = viewModel.flashcardItems

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { flashcard in
                flashcard.frontContent.localizedCaseInsensitiveContains(searchText) ||
                flashcard.backContent.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .dueToday:
            result = result.filter { flashcard in
                guard let nextDate = viewModel.getNextFlashcardReminderDate(for: flashcard) else {
                    return false
                }
                return nextDate <= Date()
            }
        case .short:
            result = result.filter { $0.textCategory == .short }
        case .medium:
            result = result.filter { $0.textCategory == .medium }
        case .long:
            result = result.filter { $0.textCategory == .long }
        }

        return result
    }

    var dueCount: Int {
        viewModel.getDueFlashcards().count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Flashcard list
            if filteredFlashcards.isEmpty {
                emptyStateView
            } else {
                #if os(macOS)
                // macOS: List with selection support
                List(selection: $selection) {
                    ForEach(filteredFlashcards) { flashcard in
                        NavigationLink(destination: IndividualFlashcardReviewView(viewModel: viewModel, flashcardId: flashcard.id)) {
                            FlashcardRowView(
                                flashcard: flashcard,
                                nextReminderDate: viewModel.getNextFlashcardReminderDate(for: flashcard)
                            )
                        }
                    }
                }
                .contextMenu(forSelectionType: FlashcardItem.ID.self) { selectedIDs in
                    if selectedIDs.isEmpty {
                        Text("No flashcards selected")
                    } else if selectedIDs.count == 1 {
                        Button("Delete Flashcard", role: .destructive) {
                            deleteSelectedFlashcards(selectedIDs)
                        }
                    } else {
                        Button("Delete \(selectedIDs.count) Flashcards", role: .destructive) {
                            deleteSelectedFlashcards(selectedIDs)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search flashcards...")
                #else
                // iOS: List with swipe-to-delete
                List {
                    ForEach(filteredFlashcards) { flashcard in
                        NavigationLink(destination: IndividualFlashcardReviewView(viewModel: viewModel, flashcardId: flashcard.id)) {
                            FlashcardRowView(
                                flashcard: flashcard,
                                nextReminderDate: viewModel.getNextFlashcardReminderDate(for: flashcard)
                            )
                        }
                    }
                    .onDelete { offsets in
                        deleteFilteredFlashcards(at: offsets)
                    }
                }
                .searchable(text: $searchText, prompt: "Search flashcards...")
                #endif
            }
        }
        .navigationTitle("Flashcards (\(viewModel.flashcardItems.count))")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Study session button
                Button {
                    showingStudySession = true
                } label: {
                    Label("Study (\(dueCount))", systemImage: "brain.head.profile")
                }
                .disabled(dueCount == 0)

                #if os(macOS)
                // Delete selected button (macOS)
                Button {
                    if !selection.isEmpty {
                        deleteSelectedFlashcards(selection)
                    }
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
                .disabled(selection.isEmpty)
                .help("Delete selected flashcards (⌫ or ⌘⌫)")
                #endif
            }
        }
        .sheet(isPresented: $showingStudySession) {
            StudySessionView(viewModel: viewModel)
        }
        #if os(macOS)
        .onDeleteCommand {
            if !selection.isEmpty {
                deleteSelectedFlashcards(selection)
            }
        }
        #endif
    }

    // MARK: - Empty State View

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: selectedFilter == .all ? "tray" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text(selectedFilter == .all ? "No Flashcards Yet" : "No Results")
                    .font(.title3)
                    .fontWeight(.semibold)

                if selectedFilter == .all {
                    Text("Create your first flashcard to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Try adjusting your filters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods

    /// Deletes flashcards from the filtered list by mapping back to original indices (iOS swipe-to-delete)
    private func deleteFilteredFlashcards(at offsets: IndexSet) {
        // Map filtered indices to original array indices
        let flashcardsToDelete = offsets.map { filteredFlashcards[$0] }
        let originalIndices = IndexSet(
            flashcardsToDelete.compactMap { flashcard in
                viewModel.flashcardItems.firstIndex(where: { $0.id == flashcard.id })
            }
        )
        viewModel.deleteFlashcards(at: originalIndices)
    }

    /// Deletes selected flashcards by ID (macOS context menu and keyboard shortcuts)
    private func deleteSelectedFlashcards(_ ids: Set<FlashcardItem.ID>) {
        let originalIndices = IndexSet(
            ids.compactMap { id in
                viewModel.flashcardItems.firstIndex(where: { $0.id == id })
            }
        )
        viewModel.deleteFlashcards(at: originalIndices)
        selection.removeAll()
    }
}

// MARK: - Stat Item Component

struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview
#Preview("Flashcard List - With Items") {
    let viewModel = RecallListViewModel()

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

    return NavigationStack {
        FlashcardListView(viewModel: viewModel)
    }
}

#Preview("Flashcard List - Empty") {
    NavigationStack {
        FlashcardListView(viewModel: RecallListViewModel())
    }
}
