//
//  HistoryView.swift
//  Submission Tracker
//
//  Created by Lakshya . music on 3/1/25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: submissionViewModel
    @State private var selectedDate: Date?
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        // Remove NavigationView since it's handled by NavigationSplitView
        VStack(spacing: UIConstants.padding) {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left.circle.fill")
                        .foregroundColor(UIConstants.primaryColor)
                        .font(.title2)
                }
                
                Text(DateFormatter.monthYearFormatter.string(from: currentMonth))
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right.circle.fill")
                        .foregroundColor(UIConstants.primaryColor)
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            HStack {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
            }
            
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: selectedDate?.isSameDay(as: date) ?? false,
                            hasItems: viewModel.itemsForDate(date).count,
                            isToday: date.isToday,
                            action: { selectedDate = date }
                        )
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
            .padding(.horizontal)
            
            if let date = selectedDate {
                if viewModel.itemsForDate(date).isEmpty {
                    Text("No items for this date")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(viewModel.itemsForDate(date)) { item in
                        Button(action: {
                            viewModel.toggleItemReceived(item, on: date)
                        }) {
                            HStack {
                                Image(systemName: item.isReceived ? "checkmark.square.fill" : "square")
                                    .foregroundColor(item.isReceived ? .green : .gray)
                                    .imageScale(.large)
                                    .font(.system(size: 24))  // Bigger checkbox
                                
                                Text("#\(item.id)")
                                    .foregroundColor(UIConstants.primaryColor)
                                    .font(.system(size: 18, design: .rounded))  // Bigger font
                                Text(item.description)
                                    .font(.system(size: 18))  // Bigger font
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())  // Makes entire row tappable
                            .padding(.vertical, 8)  // More vertical padding
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(UIConstants.secondaryColor.opacity(0.3))
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))  // Adjusted insets
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            
            Spacer()
        }
        .navigationTitle("History")
    }
    
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstDay = interval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
}
