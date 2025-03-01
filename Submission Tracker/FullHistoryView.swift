//
//  FullHistoryView.swift
//  Submission Tracker
//
//  Created by Lakshya . music on 3/1/25.
//

import SwiftUI

struct FullHistoryView: View {
    @EnvironmentObject var viewModel: submissionViewModel
    @State private var showingClearConfirmation = false
    
    var sortedDates: [(Date, [submissionItem])] {
        viewModel.history.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        List {
            ForEach(sortedDates, id: \.0) { date, items in
                Section(header: Text(date.formatted(.dateTime.day().month().year()))) {
                    ForEach(items) { item in
                        HStack {
                            Text("#\(item.id)")
                                .foregroundColor(UIConstants.primaryColor)
                                .font(.system(.subheadline, design: .rounded))
                            Text(item.description)
                                .font(.body)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.removeHistoryItem(items[index], from: date)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Full History")
        .toolbar {
            Button(role: .destructive) {
                showingClearConfirmation = true
            } label: {
                Label("Clear History", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Clear History",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All History", role: .destructive) {
                viewModel.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
