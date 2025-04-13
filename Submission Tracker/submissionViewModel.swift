//
//  submissionViewModel.swift
//  Submission Tracker
//
//  Created by Lakshya . music on 3/1/25.
//


import SwiftUI

class submissionViewModel: ObservableObject {
    @Published var currentItems: [submissionItem] = []
    @Published var history: [Date: [submissionItem]] = [:] {
        didSet {
            saveHistory()
        }
    }
    
    var lastSubmittedItems: [submissionItem] = []
    private var lastSubmissionDate: Date?
    
    init() {
        loadHistory()
        cleanOldHistory()
        // Set up timer to clean history periodically
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.cleanOldHistory()
        }
    }
    
    private func loadHistory() {
        let fileURL = FileManager.getHistoryFileURL()
        
        guard let data = try? Data(contentsOf: fileURL),
              let decodedHistory = try? JSONDecoder().decode([String: [submissionItem]].self, from: data) else {
            return
        }
        
        // Convert string dates back to Date objects
        history = decodedHistory.reduce(into: [:]) { result, pair in
            if let date = ISO8601DateFormatter().date(from: pair.key) {
                result[date] = pair.value
            }
        }
    }
    
    private func saveHistory() {
        let fileURL = FileManager.getHistoryFileURL()
        
        // Convert Date keys to ISO8601 strings
        let encodableHistory = history.reduce(into: [String: [submissionItem]]()) { result, pair in
            let dateString = ISO8601DateFormatter().string(from: pair.key)
            result[dateString] = pair.value
        }
        
        guard let encodedData = try? JSONEncoder().encode(encodableHistory) else {
            return
        }
        
        try? encodedData.write(to: fileURL)
    }

    private func updateSequenceNumbers(items: inout [submissionItem]) {
        var baseNumbers: [String: Int] = [:]
        
        for index in items.indices {
            let baseName = items[index].description.split(separator: " ").first?.description ?? items[index].description
            let currentCount = (baseNumbers[baseName] ?? 0) + 1
            baseNumbers[baseName] = currentCount
            
            items[index].sequenceNumber = currentCount > 1 ? currentCount : nil
        }
    }
    
    func addItem(_ description: String) {
        let item = submissionItem(id: submissionItem.getNewId(),
                              description: description,
                              dateAdded: Date(),
                              sequenceNumber: nil)
        currentItems.append(item)
        updateSequenceNumbers(items: &currentItems)
    }
    
    private func reindexAllHistoryItems() {
        // Create a new dictionary to store reindexed items
        var reindexedHistory: [Date: [submissionItem]] = [:]
        
        // Sort dates to ensure consistent ordering
        let sortedDates = history.keys.sorted()
        
        for date in sortedDates {
            var itemsForDate = history[date] ?? []
            
            // Sort items by their id to maintain relative order
            itemsForDate.sort(by: { $0.id < $1.id })
            
            // Update sequence numbers
            updateSequenceNumbers(items: &itemsForDate)
            
            reindexedHistory[date] = itemsForDate
        }
        
        // Update the history with reindexed items
        history = reindexedHistory
    }
    
    func markAsSubmitted() {
        lastSubmittedItems = currentItems
        lastSubmissionDate = Date()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        var allItems = history[startOfDay] ?? []
        allItems.append(contentsOf: currentItems)
        updateSequenceNumbers(items: &allItems)
        
        history[startOfDay] = allItems
        currentItems.removeAll()
    }
    
    func undoLastSubmission() {
        guard !lastSubmittedItems.isEmpty, let date = lastSubmissionDate else { return }
        
        // Remove items from history
        for item in lastSubmittedItems {
            removeHistoryItem(item, from: date)
        }
        
        // Restore items to current items
        currentItems.append(contentsOf: lastSubmittedItems)
        
        // Clear the undo buffer
        lastSubmittedItems = []
        lastSubmissionDate = nil
        
        // Save changes
        saveHistory()
    }
    
    private func cleanOldHistory() {
        let calendar = Calendar.current
        let fourMonthsAgo = calendar.date(byAdding: .month, value: -4, to: Date())!
        
        // Remove entries older than 4 months
        history = history.filter { date, _ in
            date > fourMonthsAgo
        }
    }
    
    func itemsForDate(_ date: Date) -> [submissionItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return history[startOfDay] ?? []
    }
    
    func clearHistory() {
        history.removeAll()
        // Reset the next ID counter
        submissionItem.nextId = 1
    }
    
    private func renumberItems() {
        // Get all items from both current and history
        var allItems = currentItems
        for items in history.values {
            allItems.append(contentsOf: items)
        }
        
        // Sort by ID to find gaps
        allItems.sort(by: { $0.id < $1.id })
        
        // Create a mapping of old IDs to new IDs
        var idMapping: [Int: Int] = [:]
        var newId = 1
        
        for item in allItems {
            idMapping[item.id] = newId
            newId += 1
        }
        
        // Update current items
        for i in currentItems.indices {
            let oldId = currentItems[i].id
            currentItems[i] = submissionItem(
                id: idMapping[oldId] ?? oldId,
                description: currentItems[i].description,
                dateAdded: currentItems[i].dateAdded,
                sequenceNumber: currentItems[i].sequenceNumber,
                isReceived: currentItems[i].isReceived
            )
        }
        
        // Update history items
        var updatedHistory: [Date: [submissionItem]] = [:]
        for (date, items) in history {
            var updatedItems = items
            for i in updatedItems.indices {
                let oldId = updatedItems[i].id
                updatedItems[i] = submissionItem(
                    id: idMapping[oldId] ?? oldId,
                    description: updatedItems[i].description,
                    dateAdded: updatedItems[i].dateAdded,
                    sequenceNumber: updatedItems[i].sequenceNumber,
                    isReceived: updatedItems[i].isReceived
                )
            }
            updatedHistory[date] = updatedItems
        }
        history = updatedHistory
        
        // Update the next ID counter
        submissionItem.nextId = newId
    }
    
    func removeCurrentItem(_ item: submissionItem) {
        currentItems.removeAll { $0.id == item.id }
        updateSequenceNumbers(items: &currentItems)
        renumberItems()
    }
    
    private func updateHistoryNumbers(for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if var items = history[startOfDay] {
            // Update sequence numbers
            updateSequenceNumbers(items: &items)
            
            history[startOfDay] = items
        }
    }
    
    func removeHistoryItem(_ item: submissionItem, from date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        if var items = history[startOfDay] {
            items.removeAll { $0.id == item.id }
            if items.isEmpty {
                history.removeValue(forKey: startOfDay)
            } else {
                updateSequenceNumbers(items: &items)
                history[startOfDay] = items
            }
            renumberItems()
        }
    }
}


//Extentions for submissionViewModel
extension submissionViewModel {
    struct ItemStats {
        let name: String
        let count: Int
        let percentage: Double
    }
    
    func getStatistics() -> [ItemStats] {
        var itemCounts: [String: Int] = [:]
        let allItems = history.values.flatMap { $0 }
        let totalItems = allItems.count
        
        // Count occurrences of each item type
        for item in allItems {
            let baseName = item.description.split(separator: " ").first?.description ?? item.description
            itemCounts[baseName, default: 0] += 1
        }
        
        // Convert to ItemStats and sort by count
        return itemCounts.map { name, count in
            ItemStats(
                name: name,
                count: count,
                percentage: Double(count) / Double(totalItems) * 100
            )
        }.sorted { $0.count > $1.count }
    }
    
    func getMonthlyStats() -> [(month: Date, count: Int)] {
        let calendar = Calendar.current
        var monthlyCount: [Date: Int] = [:]
        
        // Group items by month
        for (date, items) in history {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
            monthlyCount[monthStart, default: 0] += items.count
        }
        
        // Sort by date
        return monthlyCount.map { ($0.key, $0.value) }
            .sorted { $0.0 > $1.0 }
    }
    
    func toggleItemReceived(_ item: submissionItem, on date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if var items = history[startOfDay] {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index].isReceived.toggle()
                history[startOfDay] = items
            }
        }
    }
}
