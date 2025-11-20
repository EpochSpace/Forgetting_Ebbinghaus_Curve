//
//  ContentView.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 05.11.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecallListViewModel()

    // Tab/Mode selection
    @State private var selectedTab: AppTab = .recallItems

    // Recall items state
    @State private var newItemContent: String = ""
    @State private var selection = Set<RecallItem.ID>()
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: Set<RecallItem.ID> = []

    // Flashcard state
    @State private var frontContent: String = ""
    @State private var backContent: String = ""

    // Smart notification timing states
    @State private var showingNightTimeAlert = false
    @State private var currentConflict: NotificationConflict?
    @State private var pendingContent: String = ""
    @State private var pendingFrontContent: String = ""
    @State private var pendingBackContent: String = ""
    @State private var isFlashcardConflict: Bool = false

    // Text complexity analysis states
    @State private var detectedCategory: TextCategory = .short
    @State private var analysisResult: TextComplexityAnalyzer.AnalysisResult?
    @State private var manualCategoryOverride: TextCategory?
    @State private var showCategoryDetails = false
    @State private var analysisDebounceTask: Task<Void, Never>?

    enum AppTab: String, CaseIterable {
        case recallItems = "Recall Items"
        case flashcards = "Flashcards"

        var icon: String {
            switch self {
            case .recallItems: return "list.bullet.clipboard"
            case .flashcards: return "rectangle.stack"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Tab picker
                Picker("Content Type", selection: $selectedTab) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                // Content based on selected tab
                if selectedTab == .recallItems {
                    recallItemsView
                } else {
                    flashcardsContentView
                }

                VStack(spacing: 8) {
                    // Conditional input based on selected tab
                    if selectedTab == .recallItems {
                        recallItemInput
                    } else {
                        flashcardInput
                    }

                    // Category selection and analysis display
                    if (selectedTab == .recallItems && !newItemContent.isEmpty) ||
                       (selectedTab == .flashcards && (!frontContent.isEmpty || !backContent.isEmpty)) {
                        VStack(spacing: 6) {
                            // Detected category info
                            HStack {
                                Image(systemName: detectedCategory.icon)
                                    .foregroundStyle(.secondary)
                                Text("Detected: \(detectedCategory.displayName)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let result = analysisResult, result.complexityScore > 0 {
                                    Button(action: { showCategoryDetails.toggle() }) {
                                        Image(systemName: "info.circle")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Spacer()

                                if let result = analysisResult {
                                    Text("\(result.characterCount) chars")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            // Category override picker
                            HStack {
                                Text("Category:")
                                    .font(.subheadline)

                                Picker("", selection: Binding(
                                    get: { manualCategoryOverride ?? detectedCategory },
                                    set: { newValue in
                                        manualCategoryOverride = (newValue == detectedCategory) ? nil : newValue
                                    }
                                )) {
                                    ForEach(TextCategory.allCases, id: \.self) { category in
                                        Text(category.displayName)
                                            .tag(category)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if manualCategoryOverride != nil {
                                    Button("Reset") {
                                        manualCategoryOverride = nil
                                    }
                                    .font(.caption)
                                }
                            }

                            // Detailed analysis (expandable)
                            if showCategoryDetails, let result = analysisResult {
                                Text(result.detailDescription)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle(selectedTab == .recallItems ? "Recall List" : "Flashcards")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Delete selected items button (macOS, recall items only)
                    #if os(macOS)
                    if selectedTab == .recallItems {
                        Button {
                            if !selection.isEmpty {
                                confirmDeleteItems(selection)
                            }
                        } label: {
                            Label("Delete Selected", systemImage: "trash")
                        }
                        .disabled(selection.isEmpty)
                        .help("Delete selected items (⌫ or ⌘⌫)")
                    }
                    #endif

                    Button {
                        viewModel.logAllPendingNotifications()
                    } label: {
                        Label("Show Log", systemImage: "list.bullet.rectangle.portrait")
                    }

                    Button {
                        viewModel.cancelAllPendingNotifications()
                    } label: {
                        Label("Cancel All", systemImage: "trash.circle.fill")
                    }
                }
            }
        }
        .onAppear(perform: viewModel.requestNotificationPermission)
        // Keyboard shortcuts for deletion (macOS)
        #if os(macOS)
        .onDeleteCommand {
            if !selection.isEmpty {
                confirmDeleteItems(selection)
            }
        }
        #endif
        // Confirmation dialog for deletion
        .confirmationDialog(
            "Delete Items",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(itemsToDelete.count) \(itemsToDelete.count == 1 ? "Item" : "Items")", role: .destructive) {
                deleteItems(itemsToDelete)
            }
            Button("Cancel", role: .cancel) {
                itemsToDelete.removeAll()
            }
        } message: {
            Text("Are you sure you want to delete \(itemsToDelete.count) \(itemsToDelete.count == 1 ? "item" : "items")? This action cannot be undone.")
        }
        // Smart notification timing alert
        .alert("Night Time Detected", isPresented: $showingNightTimeAlert) {
            Button("Postpone until Morning") {
                addItemWithPostponement()
            }
            Button("Schedule Anyway") {
                addItemWithoutPostponement()
            }
            Button("Cancel", role: .cancel) {
                clearPendingState()
            }
        } message: {
            if let conflict = currentConflict {
                Text(conflict.alertMessage)
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var recallItemsView: some View {
        if viewModel.items.isEmpty {
            VStack {
                Spacer()
                Text("No items yet.")
                    .font(.title)
                Text("Add something you want to remember!")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        } else {
            // List with selection support for macOS
            List(selection: $selection) {
                ForEach(viewModel.items) { item in
                    RecallItemRowView(
                        item: item,
                        reminderDates: viewModel.getReminderDates(for: item),
                        nextReminderDate: viewModel.getNextReminderDate(for: item)
                    )
                }
                // Swipe to delete for iOS
                .onDelete(perform: viewModel.delete)
            }
            // Selection-aware context menu for macOS
            .contextMenu(forSelectionType: RecallItem.ID.self) { selectedIDs in
                if selectedIDs.isEmpty {
                    // Empty area menu
                    Text("No items selected")
                } else if selectedIDs.count == 1 {
                    // Single item menu
                    Button("Delete Item", role: .destructive) {
                        deleteItems(selectedIDs)
                    }
                } else {
                    // Multi-item menu
                    Button("Delete \(selectedIDs.count) Items", role: .destructive) {
                        confirmDeleteItems(selectedIDs)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private var flashcardsContentView: some View {
        FlashcardListView(viewModel: viewModel)
    }

    @ViewBuilder
    private var recallItemInput: some View {
        HStack {
            TextField("What do you want to remember?", text: $newItemContent)
                .textFieldStyle(.roundedBorder)
                .onChange(of: newItemContent) { _, newValue in
                    updateCategoryAnalysis(for: newValue)
                }

            Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
            }
            .disabled(newItemContent.isEmpty)
        }
    }

    @ViewBuilder
    private var flashcardInput: some View {
        VStack(spacing: 8) {
            // Front content input
            HStack {
                TextField("Front (Question)", text: $frontContent)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: frontContent) { _, _ in
                        updateFlashcardCategoryAnalysis()
                    }

                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(Color.statusBlue)
            }

            // Back content input
            HStack {
                TextField("Back (Answer)", text: $backContent)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: backContent) { _, _ in
                        updateFlashcardCategoryAnalysis()
                    }

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.statusGreen)
            }

            // Add button
            Button(action: addFlashcard) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Flashcard")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(frontContent.isEmpty ? Color.gray.opacity(0.2) : Color.accentPrimary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(frontContent.isEmpty)
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helper Methods

    /// Shared debounced category analysis method for both recall items and flashcards
    /// Waits 300ms after the user stops typing before running the full complexity analysis
    /// - Parameter content: The text content to analyze
    private func performDebouncedCategoryAnalysis(for content: String) {
        // Cancel any pending analysis
        analysisDebounceTask?.cancel()

        guard !content.isEmpty else {
            analysisResult = nil
            detectedCategory = .short
            return
        }

        // Provide immediate preliminary categorization based on character count
        // This gives instant feedback before the debounced complexity analysis runs
        let charCount = content.count
        detectedCategory = charCount < 20 ? .short : (charCount < 400 ? .medium : .long)

        // Schedule full analysis with complexity detection after 300ms debounce
        analysisDebounceTask = Task { @MainActor in
            // Use nanoseconds for more efficient sleep (avoids throwing)
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }

            // Perform complexity analysis
            let result = viewModel.analyzeText(content)
            analysisResult = result
            detectedCategory = result.category

            // Clear manual override if detected category matches the auto-detected one
            if let override = manualCategoryOverride, override == detectedCategory {
                manualCategoryOverride = nil
            }
        }
    }

    /// Updates the category analysis for recall items
    /// - Parameter content: The recall item content
    private func updateCategoryAnalysis(for content: String) {
        performDebouncedCategoryAnalysis(for: content)
    }

    private func addItem() {
        let content = newItemContent
        let selectedCategory = manualCategoryOverride ?? detectedCategory

        // Check for night-time conflicts with the selected category
        if let conflict = viewModel.checkForConflicts(content: content, category: selectedCategory) {
            // Store the conflict and pending content
            currentConflict = conflict
            pendingContent = content
            showingNightTimeAlert = true
        } else {
            // No conflicts, add normally with selected category
            viewModel.addItem(content: content, manualCategory: manualCategoryOverride, withConflict: nil)
            clearPendingState()
        }
    }

    private func addItemWithPostponement() {
        if isFlashcardConflict {
            viewModel.addFlashcard(
                frontContent: pendingFrontContent,
                backContent: pendingBackContent,
                manualCategory: manualCategoryOverride,
                withConflict: currentConflict
            )
            clearFlashcardPendingState()
            isFlashcardConflict = false
        } else {
            viewModel.addItem(content: pendingContent, manualCategory: manualCategoryOverride, withConflict: currentConflict)
            clearPendingState()
        }
    }

    private func addItemWithoutPostponement() {
        if isFlashcardConflict {
            viewModel.addFlashcard(
                frontContent: pendingFrontContent,
                backContent: pendingBackContent,
                manualCategory: manualCategoryOverride,
                withConflict: nil
            )
            clearFlashcardPendingState()
            isFlashcardConflict = false
        } else {
            viewModel.addItem(content: pendingContent, manualCategory: manualCategoryOverride, withConflict: nil)
            clearPendingState()
        }
    }

    private func clearPendingState() {
        newItemContent = ""
        pendingContent = ""
        currentConflict = nil
        manualCategoryOverride = nil
        analysisResult = nil
        detectedCategory = .short
        showCategoryDetails = false
        analysisDebounceTask?.cancel()
        analysisDebounceTask = nil
        isFlashcardConflict = false
    }

    /// Confirms deletion for multiple items (shows dialog)
    private func confirmDeleteItems(_ ids: Set<RecallItem.ID>) {
        itemsToDelete = ids
        if ids.count > 1 {
            showingDeleteConfirmation = true
        } else {
            deleteItems(ids)
        }
    }

    /// Deletes items immediately (single item) or after confirmation (multiple items)
    private func deleteItems(_ ids: Set<RecallItem.ID>) {
        let indices = IndexSet(
            ids.compactMap { id in
                viewModel.items.firstIndex(where: { $0.id == id })
            }
        )
        viewModel.delete(at: indices)
        selection.removeAll()
        itemsToDelete.removeAll()
    }

    // MARK: - Flashcard Helper Methods

    /// Updates category analysis for flashcards based on combined front+back content
    private func updateFlashcardCategoryAnalysis() {
        let combinedContent = frontContent + " " + backContent
        performDebouncedCategoryAnalysis(for: combinedContent)
    }

    private func addFlashcard() {
        let front = frontContent
        let back = backContent
        let selectedCategory = manualCategoryOverride ?? detectedCategory

        // Check for night-time conflicts with the selected category
        if let conflict = viewModel.checkForFlashcardConflicts(
            frontContent: front,
            backContent: back,
            category: selectedCategory
        ) {
            // Store the conflict and pending content
            currentConflict = conflict
            pendingFrontContent = front
            pendingBackContent = back
            isFlashcardConflict = true
            showingNightTimeAlert = true
        } else {
            // No conflicts, add normally
            viewModel.addFlashcard(
                frontContent: front,
                backContent: back,
                manualCategory: manualCategoryOverride,
                withConflict: nil
            )
            clearFlashcardPendingState()
        }
    }

    private func clearFlashcardPendingState() {
        frontContent = ""
        backContent = ""
        pendingFrontContent = ""
        pendingBackContent = ""
        manualCategoryOverride = nil
        analysisResult = nil
        detectedCategory = .short
        showCategoryDetails = false
        analysisDebounceTask?.cancel()
        analysisDebounceTask = nil
    }
}

#Preview {
    ContentView()
}
