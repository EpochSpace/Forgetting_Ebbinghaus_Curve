//
//  ContentView.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 05.11.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecallListViewModel()
    @State private var newItemContent: String = ""
    @State private var selection = Set<RecallItem.ID>()
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: Set<RecallItem.ID> = []

    // Smart notification timing states
    @State private var showingNightTimeAlert = false
    @State private var currentConflict: NotificationConflict?
    @State private var pendingContent: String = ""

    // Text complexity analysis states
    @State private var detectedCategory: TextCategory = .short
    @State private var analysisResult: TextComplexityAnalyzer.AnalysisResult?
    @State private var manualCategoryOverride: TextCategory?
    @State private var showCategoryDetails = false
    @State private var analysisDebounceTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack {
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

                VStack(spacing: 8) {
                    // Input field with real-time analysis
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

                    // Category selection and analysis display
                    if !newItemContent.isEmpty {
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
            .navigationTitle("Recall List")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Delete selected items button (macOS)
                    #if os(macOS)
                    Button {
                        if !selection.isEmpty {
                            confirmDeleteItems(selection)
                        }
                    } label: {
                        Label("Delete Selected", systemImage: "trash")
                    }
                    .disabled(selection.isEmpty)
                    .help("Delete selected items (⌫ or ⌘⌫)")
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

    // MARK: - Helper Methods

    /// Updates the category analysis with debouncing to improve performance
    /// Waits 300ms after the user stops typing before running the analysis
    private func updateCategoryAnalysis(for content: String) {
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
        if charCount < 20 {
            detectedCategory = .short
        } else if charCount < 400 {
            detectedCategory = .medium
        } else {
            detectedCategory = .long
        }

        // Schedule full analysis with complexity detection after 300ms debounce
        analysisDebounceTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))

                // Check if task was cancelled during sleep
                guard !Task.isCancelled else { return }

                // Perform analysis on main actor
                await MainActor.run {
                    let result = viewModel.analyzeText(content)
                    analysisResult = result
                    detectedCategory = result.category

                    // Clear manual override if detected category changes and matches the override
                    if let override = manualCategoryOverride, override == detectedCategory {
                        manualCategoryOverride = nil
                    }
                }
            } catch {
                // Task was cancelled, ignore
            }
        }
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
        viewModel.addItem(content: pendingContent, manualCategory: manualCategoryOverride, withConflict: currentConflict)
        clearPendingState()
    }

    private func addItemWithoutPostponement() {
        viewModel.addItem(content: pendingContent, manualCategory: manualCategoryOverride, withConflict: nil)
        clearPendingState()
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
}

#Preview {
    ContentView()
}
