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

    private func updateDisplayNumbers() {
        // Update sequential display numbers (left side)
        for (index, _) in currentItems.enumerated() {
            currentItems[index].displayNumber = index + 1
        }
        
        // Update duplicate item numbers (right side)
        var baseNumbers: [String: Int] = [:]
        
        for (index, item) in currentItems.enumerated() {
            let baseName = item.description.split(separator: " ").first?.description ?? item.description

            // Use the current value before incrementing
            let currentCount = baseNumbers[baseName] ?? 0
            baseNumbers[baseName] = currentCount + 1
            
            if currentCount > 0 {
                // Assign the correct sequence number starting from 2
                currentItems[index].sequenceNumber = currentCount + 1
            } else {
                currentItems[index].sequenceNumber = nil
            }
        }
    }
    
    
    func addItem(_ description: String) {
        let item = submissionItem(id: submissionItem.getNewId(),
                              description: description,
                              dateAdded: Date(),
                              displayNumber: currentItems.count + 1,
                              sequenceNumber: nil)
        currentItems.append(item)
        updateDisplayNumbers()
    }
    
    private func reindexAllHistoryItems() {
        // Create a new dictionary to store reindexed items
        var reindexedHistory: [Date: [submissionItem]] = [:]
        
        // Sort dates to ensure consistent ordering
        let sortedDates = history.keys.sorted()
        
        for date in sortedDates {
            var itemsForDate = history[date] ?? []
            
            // Sort items by their current display number to maintain relative order
            itemsForDate.sort { $0.displayNumber < $1.displayNumber }
            
            // Update display numbers
            for index in itemsForDate.indices {
                itemsForDate[index].displayNumber = index + 1
            }
            
            // Update sequence numbers
            var baseNumbers: [String: Int] = [:]
            for index in itemsForDate.indices {
                let baseName = itemsForDate[index].description.split(separator: " ").first?.description ?? itemsForDate[index].description
                baseNumbers[baseName] = (baseNumbers[baseName] ?? 0) + 1
                
                if baseNumbers[baseName]! > 1 {
                    itemsForDate[index].sequenceNumber = baseNumbers[baseName]
                } else {
                    itemsForDate[index].sequenceNumber = nil
                }
            }
            
            reindexedHistory[date] = itemsForDate
        }
        
        // Update the history with reindexed items
        history = reindexedHistory
    }
    
    func markAsSubmitted() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let existingItems = history[startOfDay] ?? []
        var newItems = currentItems
        
        // Determine starting number for new items
        let startNumber = existingItems.isEmpty ? 1 : existingItems.max(by: { $0.displayNumber < $1.displayNumber })?.displayNumber ?? 0 + 1
        
        // Update display numbers for new items
        for (index, _) in newItems.enumerated() {
            newItems[index].displayNumber = startNumber + index
        }
        
        // Combine existing and new items
        var allItems = existingItems
        allItems.append(contentsOf: newItems)
        
        // Sort all items by display number to ensure correct order
        allItems.sort { $0.displayNumber < $1.displayNumber }
        
        // Update sequence numbers for all items
        var baseNumbers: [String: Int] = [:]
        for index in allItems.indices {
            let baseName = allItems[index].description.split(separator: " ").first?.description ?? allItems[index].description
            baseNumbers[baseName] = (baseNumbers[baseName] ?? 0) + 1
            
            // Update sequence number
            if baseNumbers[baseName]! > 1 {
                allItems[index].sequenceNumber = baseNumbers[baseName]
            } else {
                allItems[index].sequenceNumber = nil
            }
        }
        
        // Save the updated items
        history[startOfDay] = allItems
        currentItems.removeAll()
        
        // Reindex all items after adding new ones
        reindexAllHistoryItems()
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
    
    func removeCurrentItem(_ item: submissionItem) {
        currentItems.removeAll { $0.id == item.id }
        updateDisplayNumbers()
    }
    
    private func updateHistoryNumbers(for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if var items = history[startOfDay] {
            // Update display numbers
            for (index, _) in items.enumerated() {
                items[index].displayNumber = index + 1
            }
            
            // Update sequence numbers
            var baseNumbers: [String: Int] = [:]
            for index in items.indices {
                let baseName = items[index].description.split(separator: " ").first?.description ?? items[index].description
                baseNumbers[baseName] = (baseNumbers[baseName] ?? 0) + 1
                
                if baseNumbers[baseName]! > 1 {
                    items[index].sequenceNumber = baseNumbers[baseName]
                } else {
                    items[index].sequenceNumber = nil
                }
            }
            
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
                // Update display numbers sequentially
                for (index, _) in items.enumerated() {
                    items[index].displayNumber = index + 1
                }
                
                // Update sequence numbers for duplicates
                var baseNumbers: [String: Int] = [:]
                for index in items.indices {
                    let baseName = items[index].description.split(separator: " ").first?.description ?? items[index].description
                    baseNumbers[baseName] = (baseNumbers[baseName] ?? 0) + 1
                    
                    if baseNumbers[baseName]! > 1 {
                        items[index].sequenceNumber = baseNumbers[baseName]
                    } else {
                        items[index].sequenceNumber = nil
                    }
                }
                
                history[startOfDay] = items
            }
            
            // Trigger reindexing of all history items to maintain consistency
            reindexAllHistoryItems()
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
