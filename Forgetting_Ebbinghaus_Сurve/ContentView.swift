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
                
                HStack {
                    TextField("What do you want to remember?", text: $newItemContent)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                    .disabled(newItemContent.isEmpty)
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
    }

    // MARK: - Helper Methods

    private func addItem() {
        viewModel.addItem(content: newItemContent)
        newItemContent = ""
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
